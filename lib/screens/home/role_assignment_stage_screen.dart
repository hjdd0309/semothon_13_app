import 'package:flutter/material.dart';
import '../models/project_detail_model.dart';
import '../services/project_service.dart';
import 'project_detail_screen.dart';

class RoleAssignmentStageScreen extends StatefulWidget {
  final ProjectDetailModel project;
  final ProjectService service;

  const RoleAssignmentStageScreen({
    super.key,
    required this.project,
    required this.service,
  });

  @override
  State<RoleAssignmentStageScreen> createState() =>
      _RoleAssignmentStageScreenState();
}

class _RoleAssignmentStageScreenState extends State<RoleAssignmentStageScreen> {
  static const Color kBg = Color(0xFFF8F5F3);
  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE9DEDA);
  static const Color kText = Color(0xFF231A1C);
  static const Color kSub = Color(0xFF8C7E7F);
  static const Color kWine = Color(0xFFA31621);
  static const Color kSoftRed = Color(0xFFFFF1F1);
  static const Color kSoftPink = Color(0xFFFFFAFA);
  static const Color kGreen = Color(0xFF18A957);
  static const Color kAmber = Color(0xFFFF8A3D);

  final List<_MemberRoleData> members = [
    _MemberRoleData(
      name: 'user_1',
      role: '자료조사',
      accentLabel: '리서치 중심',
      todos: [
        _TodoItem(title: '유사 서비스 5개 조사하기'),
        _TodoItem(title: '경쟁 서비스 장단점 표로 정리하기'),
        _TodoItem(title: '핵심 인사이트 3개 추출하기'),
      ],
    ),
    _MemberRoleData(
      name: 'user_2',
      role: 'PPT 만들기',
      accentLabel: '시각 정리',
      todos: [
        _TodoItem(title: '발표 흐름에 맞는 PPT 목차 구성하기'),
        _TodoItem(title: '슬라이드 디자인 템플릿 통일하기'),
        _TodoItem(title: '최종 발표용 핵심 화면 정리하기'),
      ],
    ),
    _MemberRoleData(
      name: 'user_3',
      role: '논문 자료 분석',
      accentLabel: '분석 중심',
      todos: [
        _TodoItem(title: '관련 논문 3편 핵심 내용 요약하기'),
        _TodoItem(title: '논문 기반 근거 문장 정리하기'),
        _TodoItem(title: '프로젝트에 적용 가능한 포인트 추리기'),
      ],
    ),
    _MemberRoleData(
      name: '표지훈',
      role: '발표자',
      accentLabel: '전달 중심',
      todos: [
        _TodoItem(title: '발표 대본 초안 작성하기'),
        _TodoItem(title: '중간 리허설 후 피드백 반영하기'),
        _TodoItem(title: 'Q&A 예상 질문 답변 정리하기'),
      ],
    ),
  ];

  int _selectedMemberIndex = 0;

  _MemberRoleData get _selectedMember => members[_selectedMemberIndex];

  double get _selectedProgress {
    if (_selectedMember.todos.isEmpty) return 0;
    final done = _selectedMember.todos.where((e) => e.isDone).length;
    return done / _selectedMember.todos.length;
  }

  int get _selectedDoneCount =>
      _selectedMember.todos.where((e) => e.isDone).length;

  void _toggleTodo(int memberIndex, int todoIndex) {
    setState(() {
      final target = members[memberIndex];
      target.todos[todoIndex] = target.todos[todoIndex]
          .copyWith(isDone: !target.todos[todoIndex].isDone);
    });
  }

  Color _memberBadgeBg(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFEFEF);
      case 1:
        return const Color(0xFFFFF6EA);
      case 2:
        return const Color(0xFFF3F2FF);
      case 3:
        return const Color(0xFFEFF8F1);
      default:
        return const Color(0xFFF4F1EF);
    }
  }

  Color _memberBadgeText(int index) {
    switch (index) {
      case 0:
        return kWine;
      case 1:
        return kAmber;
      case 2:
        return const Color(0xFF5E58D6);
      case 3:
        return kGreen;
      default:
        return kSub;
    }
  }

  void _showCompleteSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('역할 및 업무 분배를 확인했어요.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedMember;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kText,
        centerTitle: false,
        titleSpacing: 0,
        title: const Text(
          '역할 및 업무 분배',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildMemberTabSection(),
            const SizedBox(height: 16),
            _buildSelectedRoleCard(selected),
            const SizedBox(height: 18),
            const Text(
              '전체 팀원 업무 현황',
              style: TextStyle(
                color: kText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              members.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildMemberSummaryCard(index),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  _showCompleteSnack();

                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (!mounted) return;
                    Navigator.pop(context);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kWine,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  '이 분배로 진행하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: kSoftRed,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '자동 분배 완료',
              style: TextStyle(
                color: kWine,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${widget.project.projectTitle} 팀의 역할과 업무를 정리했어요.',
            style: const TextStyle(
              color: kText,
              fontSize: 24,
              height: 1.28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '아이스브레이킹 결과를 참고해 팀원마다 강점이 잘 드러나도록 역할과 할 일을 배정한 화면이에요. '
            '위에서 팀원을 눌러 개인 역할을 자세히 볼 수 있어요.',
            style: TextStyle(
              color: kSub,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTabSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '팀원 선택',
            style: TextStyle(
              color: kText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final selected = _selectedMemberIndex == index;
                final member = members[index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMemberIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? kWine : kSoftPink,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? kWine : kBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withOpacity(0.18)
                                : _memberBadgeBg(index),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            member.name.substring(0, 1),
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : _memberBadgeText(index),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member.name,
                          style: TextStyle(
                            color: selected ? Colors.white : kText,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRoleCard(_MemberRoleData member) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${member.name}님의 역할',
            style: const TextStyle(
              color: kSub,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  member.role,
                  style: const TextStyle(
                    color: kText,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _memberBadgeBg(_selectedMemberIndex),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  member.accentLabel,
                  style: TextStyle(
                    color: _memberBadgeText(_selectedMemberIndex),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'To do list',
            style: TextStyle(
              color: kText,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            member.todos.length,
            (todoIndex) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF0E5E1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${todoIndex + 1}. ${member.todos[todoIndex].title}',
                        style: TextStyle(
                          color: member.todos[todoIndex].isDone
                              ? const Color(0xFFA39B99)
                              : kText,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          decoration: member.todos[todoIndex].isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _toggleTodo(_selectedMemberIndex, todoIndex),
                      borderRadius: BorderRadius.circular(999),
                      child: Icon(
                        member.todos[todoIndex].isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 24,
                        color: member.todos[todoIndex].isDone
                            ? kGreen
                            : const Color(0xFFFF4A4A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: _selectedProgress,
                    backgroundColor: const Color(0xFFF1ECE9),
                    valueColor: const AlwaysStoppedAnimation(kWine),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(_selectedProgress * 100).round()}%',
                style: const TextStyle(
                  color: kWine,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '총 ${member.todos.length}개 중 $_selectedDoneCount개 완료',
            style: const TextStyle(
              color: kSub,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSummaryCard(int memberIndex) {
    final member = members[memberIndex];
    final previewTodos = member.todos.take(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _memberBadgeBg(memberIndex),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${member.todos.length}',
              style: TextStyle(
                color: _memberBadgeText(memberIndex),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member.name} _ ${member.role}',
                  style: const TextStyle(
                    color: kText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.accentLabel,
                  style: const TextStyle(
                    color: kSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  previewTodos.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: kWine,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            previewTodos[index].title,
                            style: const TextStyle(
                              color: kText,
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (member.todos.length > 2)
                  Text(
                    '+ ${member.todos.length - 2}개 업무 더 있음',
                    style: const TextStyle(
                      color: kSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: member.todos
                .take(2)
                .map(
                  (todo) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Icon(
                      todo.isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 22,
                      color: todo.isDone ? kGreen : const Color(0xFFFF4A4A),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MemberRoleData {
  final String name;
  final String role;
  final String accentLabel;
  final List<_TodoItem> todos;

  _MemberRoleData({
    required this.name,
    required this.role,
    required this.accentLabel,
    required this.todos,
  });
}

class _TodoItem {
  final String title;
  final bool isDone;

  const _TodoItem({
    required this.title,
    this.isDone = false,
  });

  _TodoItem copyWith({
    String? title,
    bool? isDone,
  }) {
    return _TodoItem(
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}
