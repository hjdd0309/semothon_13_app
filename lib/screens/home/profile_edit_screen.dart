import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileEditScreen extends StatefulWidget {
  final String? token;
  const ProfileEditScreen({super.key, this.token});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // 기본 정보
  final TextEditingController nameController = TextEditingController();
  final TextEditingController majorController = TextEditingController();
  final TextEditingController personalityController = TextEditingController();

  // MBTI
  String? selectedMBTI;
  final List<String> mbtiList = [
    'ISTJ', 'ISFJ', 'INFJ', 'INTJ',
    'ISTP', 'ISFP', 'INFP', 'INTP',
    'ESTP', 'ESFP', 'ENFP', 'ENTP',
    'ESTJ', 'ESFJ', 'ENFJ', 'ENTJ',
  ];

  // 역할
  Set<String> selectedRoles = {};
  final List<String> roles = [
    'PPT 제작', '발표', '자료조사', '보고서 작성',
    '디자인', '코딩', '영상 편집',
  ];
  final TextEditingController customRoleController = TextEditingController();
  List<String> customRoles = [];

  // 취미
  Set<String> selectedHobbies = {};
  final List<String> hobbies = [
    '영화/드라마', '운동/스포츠 시청', '독서', '유튜브/릴스 시청',
  ];
  final TextEditingController customHobbyController = TextEditingController();
  List<String> customHobbies = [];

  // 시간표
  final List<String> days = ['월', '화', '수', '목', '금'];
  final int startHour = 9;
  final int endHour = 21;
  List<Map<String, dynamic>> scheduleItems = [];
  int _nextId = 1000;

  // 상태
  bool isLoading = true;
  bool isSaving = false;

  static const Color primaryColor = Color(0xFFA31621);
  static const Color bgColor = Color(0xFFF6F1F1);
  static const Color cardColor = Colors.white;
  static const Color subtitleColor = Color(0xFF7D6666);
  static const Color inputFillColor = Color(0xFFF9F1F1);
  static const Color cardBorder = Color(0xFFE7C9C9);
  static const Color textDark = Color(0xFF1A1A1A);

  static const String baseUrl = 'https://semothon13app-production.up.railway.app';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    majorController.dispose();
    personalityController.dispose();
    customRoleController.dispose();
    customHobbyController.dispose();
    super.dispose();
  }

  // ─── 데이터 불러오기 ───
  Future<void> _loadProfile() async {
    if (widget.token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // 프로필 불러오기
      final profileRes = await http.get(
        Uri.parse('$baseUrl/profile/me'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (profileRes.statusCode == 200) {
        final data = jsonDecode(profileRes.body);
        setState(() {
          nameController.text = data['display_name'] ?? '';
          majorController.text = data['major'] ?? '';
          selectedMBTI = data['mbti'];
          personalityController.text = data['personality_summary'] ?? '';

          // preferred_roles 파싱
          if (data['preferred_roles'] != null && data['preferred_roles'].toString().isNotEmpty) {
            final savedRoles = data['preferred_roles'].toString().split(', ');
            for (var r in savedRoles) {
              if (roles.contains(r)) {
                selectedRoles.add(r);
              } else if (r.isNotEmpty) {
                customRoles.add(r);
              }
            }
          }

          // hobbies 파싱
          if (data['hobbies'] != null && data['hobbies'].toString().isNotEmpty) {
            final savedHobbies = data['hobbies'].toString().split(', ');
            for (var h in savedHobbies) {
              if (hobbies.contains(h)) {
                selectedHobbies.add(h);
              } else if (h.isNotEmpty) {
                customHobbies.add(h);
              }
            }
          }
        });
      }

      // 시간표 불러오기
      final scheduleRes = await http.get(
        Uri.parse('$baseUrl/schedules/me'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (scheduleRes.statusCode == 200) {
        final List<dynamic> scheduleData = jsonDecode(scheduleRes.body);
        setState(() {
          scheduleItems = scheduleData.map((s) {
            final startParts = s['start_time'].toString().split(':');
            final endParts = s['end_time'].toString().split(':');
            return {
              'id': s['id'],
              'serverId': s['id'],
              'day': s['day'],
              'startHour': int.parse(startParts[0]),
              'startMin': int.parse(startParts[1]),
              'endHour': int.parse(endParts[0]),
              'endMin': int.parse(endParts[1]),
              'title': s['name'],
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('프로필 불러오기 실패: $e');
    }

    setState(() => isLoading = false);
  }

  // ─── 저장하기 ───
  Future<void> _saveProfile() async {
    if (widget.token == null) return;
    setState(() => isSaving = true);

    try {
      // 프로필 저장
      final Map<String, dynamic> profileData = {
        'display_name': nameController.text.trim(),
        'major': majorController.text.trim(),
      };
      if (selectedMBTI != null) profileData['mbti'] = selectedMBTI;
      if (personalityController.text.trim().isNotEmpty) {
        profileData['personality_summary'] = personalityController.text.trim();
      }
      if (selectedRoles.isNotEmpty || customRoles.isNotEmpty) {
        profileData['preferred_roles'] = [...selectedRoles, ...customRoles].join(', ');
      }
      if (selectedHobbies.isNotEmpty || customHobbies.isNotEmpty) {
        profileData['hobbies'] = [...selectedHobbies, ...customHobbies].join(', ');
      }

      await http.patch(
        Uri.parse('$baseUrl/profile/me'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode(profileData),
      );

      // 기존 시간표 삭제 후 새로 저장
      // 1. 서버에 있는 기존 일정 삭제
      final existingSchedules = scheduleItems.where((s) => s['serverId'] != null).toList();
      for (var item in existingSchedules) {
        await http.delete(
          Uri.parse('$baseUrl/schedules/${item['serverId']}'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
      }

      // 2. 현재 일정 전부 새로 저장
      for (var item in scheduleItems) {
        final startTime = '${item['startHour'].toString().padLeft(2, '0')}:${item['startMin'].toString().padLeft(2, '0')}';
        final endTime = '${item['endHour'].toString().padLeft(2, '0')}:${item['endMin'].toString().padLeft(2, '0')}';
        await http.post(
          Uri.parse('$baseUrl/schedules'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
          body: jsonEncode({'day': item['day'], 'start_time': startTime, 'end_time': endTime, 'name': item['title']}),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }

    setState(() => isSaving = false);
  }

  // ─── 일정 추가 다이얼로그 ───
  void _showAddScheduleDialog({String? preselectedDay}) {
    String selectedDay = preselectedDay ?? '월';
    int sHour = 9, sMin = 0, eHour = 10, eMin = 0;
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: Text('일정 추가', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textDark))),
                      const SizedBox(height: 20),
                      _label('일정 이름'), const SizedBox(height: 8),
                      TextField(controller: titleController, decoration: _inputDecoration('예) 데이터구조, 알바')),
                      const SizedBox(height: 16),
                      _label('요일'), const SizedBox(height: 8),
                      Row(
                        children: days.map((day) {
                          final isSel = selectedDay == day;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedDay = day),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(color: isSel ? primaryColor : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSel ? primaryColor : cardBorder, width: 1.5)),
                                child: Center(child: Text(day, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSel ? Colors.white : textDark))),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _label('시작 시간'), const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _buildDropdown(value: sHour, items: List.generate(endHour - startHour, (i) => startHour + i), label: (v) => '$v시', onChanged: (v) => setDialogState(() => sHour = v))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildDropdown(value: sMin, items: [0, 15, 30, 45], label: (v) => '${v.toString().padLeft(2, '0')}분', onChanged: (v) => setDialogState(() => sMin = v))),
                      ]),
                      const SizedBox(height: 16),
                      _label('종료 시간'), const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _buildDropdown(value: eHour, items: List.generate(endHour - startHour + 1, (i) => startHour + i), label: (v) => '$v시', onChanged: (v) => setDialogState(() => eHour = v))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildDropdown(value: eMin, items: [0, 15, 30, 45], label: (v) => '${v.toString().padLeft(2, '0')}분', onChanged: (v) => setDialogState(() => eMin = v))),
                      ]),
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(child: SizedBox(height: 44, child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: const BorderSide(color: cardBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('취소', style: TextStyle(color: textDark, fontWeight: FontWeight.w600))))),
                        const SizedBox(width: 10),
                        Expanded(child: SizedBox(height: 44, child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.trim().isEmpty) return;
                            if (eHour * 60 + eMin <= sHour * 60 + sMin) return;
                            setState(() {
                              scheduleItems.add({'id': _nextId++, 'day': selectedDay, 'startHour': sHour, 'startMin': sMin, 'endHour': eHour, 'endMin': eMin, 'title': titleController.text.trim()});
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ))),
                      ]),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown({required int value, required List<int> items, required String Function(int) label, required void Function(int) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: inputFillColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: cardBorder)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          items: items.map((v) => DropdownMenuItem(value: v, child: Text(label(v), style: const TextStyle(fontSize: 14, color: textDark)))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }

  // ─── 시간표 격자 ───
  Widget _buildScheduleGrid() {
    final hours = List.generate(endHour - startHour, (i) => startHour + i);
    return Column(
      children: [
        Row(children: [
          const SizedBox(width: 40),
          ...days.map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDark))))),
        ]),
        const SizedBox(height: 4),
        ...hours.expand((hour) => List.generate(4, (q) {
          final min = q * 15;
          return Row(children: [
            SizedBox(width: 40, height: 18, child: q == 0 ? Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 4), child: Text('$hour:00', style: const TextStyle(fontSize: 10, color: subtitleColor)))) : null),
            ...days.map((day) {
              final slotStart = hour * 60 + min;
              final item = scheduleItems.firstWhere((s) {
                if (s['day'] != day) return false;
                return slotStart >= s['startHour'] * 60 + s['startMin'] && slotStart < s['endHour'] * 60 + s['endMin'];
              }, orElse: () => {});
              final has = item.isNotEmpty;
              final isStart = has && item['startHour'] == hour && item['startMin'] == min;
              return Expanded(child: GestureDetector(
                onTap: () { if (has) { _showDeleteDialog(item); } else { _showAddScheduleDialog(preselectedDay: day); } },
                child: Container(
                  height: 18, margin: const EdgeInsets.all(0.5),
                  decoration: BoxDecoration(color: has ? primaryColor.withOpacity(0.85) : const Color(0xFFF9F1F1), borderRadius: BorderRadius.circular(2), border: Border.all(color: has ? primaryColor : const Color(0xFFEDE3E3), width: 0.5)),
                  child: isStart ? Padding(padding: const EdgeInsets.only(left: 2, top: 1), child: Text(item['title'] ?? '', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)) : null,
                ),
              ));
            }),
          ]);
        })),
      ],
    );
  }

  void _showDeleteDialog(Map<String, dynamic> item) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(item['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Text('${item['day']}  ${item['startHour']}:${item['startMin'].toString().padLeft(2, '0')} ~ ${item['endHour']}:${item['endMin'].toString().padLeft(2, '0')}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
        TextButton(onPressed: () { setState(() => scheduleItems.removeWhere((s) => s['id'] == item['id'])); Navigator.pop(ctx); }, child: const Text('삭제', style: TextStyle(color: primaryColor))),
      ],
    ));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Color(0xFFA58787), fontSize: 14),
      filled: true, fillColor: inputFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cardBorder, width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryColor, width: 1.2)),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5F4747)));

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBFB), borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAE1E1)),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
                child: Column(
                  children: [
                    // ─── 헤더 ───
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF7D6666)),
                            SizedBox(width: 4),
                            Text('돌아가기', style: TextStyle(color: Color(0xFF7D6666), fontSize: 14, fontWeight: FontWeight.w500)),
                          ]),
                        ),
                        const Spacer(),
                        const Text('프로필 수정', style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        const SizedBox(width: 70),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── 기본 정보 ───
                    _buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('이름'), const SizedBox(height: 8),
                      TextField(controller: nameController, decoration: _inputDecoration('이름')),
                      const SizedBox(height: 18),
                      _label('전공'), const SizedBox(height: 8),
                      TextField(controller: majorController, decoration: _inputDecoration('전공')),
                    ])),
                    const SizedBox(height: 16),

                    // ─── MBTI + 자기소개 + 역할 ───
                    _buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Center(child: Text('나를 소개해주세요!', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w600))),
                      const SizedBox(height: 18),
                      _label('MBTI'), const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.8),
                        itemCount: mbtiList.length,
                        itemBuilder: (_, i) {
                          final m = mbtiList[i]; final sel = selectedMBTI == m;
                          return GestureDetector(onTap: () => setState(() => selectedMBTI = m), child: Container(
                            decoration: BoxDecoration(color: sel ? primaryColor : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? primaryColor : cardBorder, width: 1.5)),
                            alignment: Alignment.center, child: Text(m, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : textDark)),
                          ));
                        },
                      ),
                      const SizedBox(height: 18),
                      _label('한줄 자기소개'), const SizedBox(height: 8),
                      TextField(controller: personalityController, decoration: _inputDecoration('예) 계획적이고 꼼꼼한 성격입니다')),
                      const SizedBox(height: 18),

                      // 역할
                      _label('자신있는 역할 (최대 4개)'), const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: roles.map((role) {
                        final sel = selectedRoles.contains(role);
                        final total = selectedRoles.length + customRoles.length;
                        return GestureDetector(
                          onTap: () { setState(() { if (sel) { selectedRoles.remove(role); } else if (total < 4) { selectedRoles.add(role); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 4개까지 선택할 수 있어요'))); } }); },
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: sel ? primaryColor : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? primaryColor : cardBorder, width: 1.5)),
                              child: Text(role, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: sel ? Colors.white : textDark))),
                        );
                      }).toList()),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextField(controller: customRoleController, decoration: InputDecoration(hintText: '기타 역할 직접 입력', hintStyle: const TextStyle(color: Color(0xFFA58787), fontSize: 13), filled: true, fillColor: inputFillColor, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: cardBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: primaryColor, width: 1.2))))),
                        const SizedBox(width: 8),
                        GestureDetector(onTap: () { final t = customRoleController.text.trim(); final total = selectedRoles.length + customRoles.length; if (total >= 4) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최대 4개까지 선택할 수 있어요'))); return; } if (t.isNotEmpty && !customRoles.contains(t)) { setState(() { customRoles.add(t); customRoleController.clear(); }); } },
                            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.add, size: 18, color: Colors.white))),
                      ]),
                      if (customRoles.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, runSpacing: 8, children: customRoles.map((r) => Container(
                          padding: const EdgeInsets.only(left: 14, right: 6, top: 8, bottom: 8),
                          decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(r, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                            const SizedBox(width: 4),
                            GestureDetector(onTap: () => setState(() => customRoles.remove(r)), child: const Icon(Icons.close, size: 16, color: Colors.white)),
                          ]),
                        )).toList()),
                      ],
                    ])),
                    const SizedBox(height: 16),

                    // ─── 취미 ───
                    _buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Center(child: Text('취미', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w600))),
                      const SizedBox(height: 14),
                      Wrap(spacing: 8, runSpacing: 8, children: hobbies.map((h) {
                        final sel = selectedHobbies.contains(h);
                        return GestureDetector(onTap: () { setState(() { if (sel) selectedHobbies.remove(h); else selectedHobbies.add(h); }); },
                            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: sel ? primaryColor : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? primaryColor : cardBorder, width: 1.5)),
                                child: Text(h, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: sel ? Colors.white : textDark))));
                      }).toList()),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextField(controller: customHobbyController, decoration: InputDecoration(hintText: '기타 취미 직접 입력', hintStyle: const TextStyle(color: Color(0xFFA58787), fontSize: 13), filled: true, fillColor: inputFillColor, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: cardBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: primaryColor, width: 1.2))))),
                        const SizedBox(width: 8),
                        GestureDetector(onTap: () { final t = customHobbyController.text.trim(); if (t.isNotEmpty && !customHobbies.contains(t)) { setState(() { customHobbies.add(t); customHobbyController.clear(); }); } },
                            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.add, size: 18, color: Colors.white))),
                      ]),
                      if (customHobbies.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, runSpacing: 8, children: customHobbies.map((h) => Container(
                          padding: const EdgeInsets.only(left: 14, right: 6, top: 8, bottom: 8),
                          decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(h, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                            const SizedBox(width: 4),
                            GestureDetector(onTap: () => setState(() => customHobbies.remove(h)), child: const Icon(Icons.close, size: 16, color: Colors.white)),
                          ]),
                        )).toList()),
                      ],
                    ])),
                    const SizedBox(height: 16),

                    // ─── 시간표 ───
                    _buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Center(child: Text('내 시간표', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w600))),
                      const SizedBox(height: 4),
                      const Center(child: Text('빈 칸을 터치해서 일정을 추가하세요', style: TextStyle(color: subtitleColor, fontSize: 12))),
                      const SizedBox(height: 14),
                      _buildScheduleGrid(),
                      const SizedBox(height: 12),
                      if (scheduleItems.isNotEmpty) ...[
                        const Divider(color: cardBorder),
                        const SizedBox(height: 8),
                        _label('추가된 일정'), const SizedBox(height: 8),
                        ...scheduleItems.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: primaryColor.withOpacity(0.2))),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark)),
                              const SizedBox(height: 2),
                              Text('${item['day']}  ${item['startHour']}:${item['startMin'].toString().padLeft(2, '0')} ~ ${item['endHour']}:${item['endMin'].toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: subtitleColor)),
                            ])),
                            GestureDetector(onTap: () => setState(() => scheduleItems.removeWhere((s) => s['id'] == item['id'])), child: const Icon(Icons.close, size: 18, color: subtitleColor)),
                          ]),
                        )),
                      ],
                      const SizedBox(height: 8),
                      Center(child: TextButton.icon(onPressed: () => _showAddScheduleDialog(), icon: const Icon(Icons.add, size: 18, color: primaryColor), label: const Text('일정 추가', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)))),
                    ])),
                    const SizedBox(height: 22),

                    // ─── 저장 버튼 ───
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : _saveProfile,
                        icon: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, size: 18, color: Colors.white),
                        label: const Text('저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: primaryColor, disabledBackgroundColor: primaryColor.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}