import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/project_detail_model.dart';
import '../services/project_service.dart';

class TodoDisplayItem {
  final String title;
  final String assignee;
  final String dueDateText;
  final String status; // 완료 / 진행중 / 대기
  final bool isDone;

  const TodoDisplayItem({
    required this.title,
    required this.assignee,
    required this.dueDateText,
    required this.status,
    required this.isDone,
  });
}

class TeamMemberOverview {
  final String id;
  final String name;
  final String role;
  final String status; // 활동중 / 비활동 / 대기
  final List<String> tasks;

  const TeamMemberOverview({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.tasks,
  });

  TeamMemberOverview copyWith({
    String? id,
    String? name,
    String? role,
    String? status,
    List<String>? tasks,
  }) {
    return TeamMemberOverview(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
    );
  }
}

class TeamTodoOverviewScreen extends StatefulWidget {
  final ProjectDetailModel project;
  final ProjectService service;
  final List<TodoDisplayItem> todoItems;

  final String? myUserId;
  final String? myUsername;
  final String? myDisplayName;

  const TeamTodoOverviewScreen({
    super.key,
    required this.project,
    required this.service,
    required this.todoItems,
    this.myUserId,
    this.myUsername,
    this.myDisplayName,
  });

  @override
  State<TeamTodoOverviewScreen> createState() => _TeamTodoOverviewScreenState();
}

class _TeamTodoOverviewScreenState extends State<TeamTodoOverviewScreen> {
  static const Color kBg = Color(0xFFF7F4F3);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF231A1C);
  static const Color kSub = Color(0xFF8C7E7F);
  static const Color kBorder = Color(0xFFEBE2DE);
  static const Color kWine = Color(0xFFA31621);
  static const Color kGreen = Color(0xFF18A957);
  static const Color kGrayBadge = Color(0xFFF1EFEE);
  static const Color kRedSoft = Color(0xFFFFEFEF);
  static const Color kGreenSoft = Color(0xFFEAF8F0);

  static const String baseUrl =
      'https://semothon13app-production.up.railway.app';

  bool _isLoadingMembers = true;
  String? _memberLoadError;
  List<TeamMemberOverview> _members = [];

  String? _currentUserId;
  String? _currentUsername;
  String? _currentDisplayName;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _resolveCurrentUser();
    await _loadMembersFromApi();
  }

  String _normalize(String value) => value.trim().toLowerCase();

  Future<void> _resolveCurrentUser() async {
    // 1) 먼저 외부에서 넘겨준 값 사용
    _currentUserId = (widget.myUserId ?? '').trim();
    _currentUsername = (widget.myUsername ?? '').trim();
    _currentDisplayName = (widget.myDisplayName ?? '').trim();

    // 2) 셋 다 비어 있지 않으면 그대로 사용
    final hasEnoughInfo = (_currentUserId?.isNotEmpty == true) ||
        (_currentUsername?.isNotEmpty == true) ||
        (_currentDisplayName?.isNotEmpty == true);

    if (hasEnoughInfo) return;

    // 3) 비어 있으면 /auth/me fallback
    final token = widget.service.accessToken?.trim() ?? '';
    if (token.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      _currentUserId = (data['id'] ?? data['user_id'] ?? '').toString().trim();
      _currentUsername = (data['username'] ?? '').toString().trim();
      _currentDisplayName =
          (data['display_name'] ?? data['nickname'] ?? data['name'] ?? '')
              .toString()
              .trim();
    } catch (_) {}
  }

  Future<void> _loadMembersFromApi() async {
    setState(() {
      _isLoadingMembers = true;
      _memberLoadError = null;
    });

    final token = widget.service.accessToken?.trim() ?? '';
    if (token.isEmpty) {
      setState(() {
        _memberLoadError = '로그인 토큰이 없어 팀원 정보를 불러올 수 없어요.';
        _isLoadingMembers = false;
      });
      return;
    }

    try {
      final roomId = widget.project.projectNumber.trim();

      final response = await http.get(
        Uri.parse('$baseUrl/rooms/$roomId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        setState(() {
          _memberLoadError = '팀원 정보를 불러오지 못했어요. (${response.statusCode})';
          _isLoadingMembers = false;
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      final parsedMembers = _parseMembers(decoded);

      setState(() {
        _members = parsedMembers;
        _isLoadingMembers = false;
      });
    } catch (_) {
      setState(() {
        _memberLoadError = '팀원 정보를 불러오는 중 오류가 발생했어요.';
        _isLoadingMembers = false;
      });
    }
  }

  List<TeamMemberOverview> _parseMembers(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return [];

    final dynamic rawUsers =
        decoded['users'] ?? decoded['members'] ?? decoded['participants'];

    final List<dynamic> userList =
        rawUsers is List ? rawUsers : const <dynamic>[];

    final taskMap = _buildTaskMap(widget.todoItems);
    final List<TeamMemberOverview> members = [];

    for (final raw in userList) {
      final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      final nestedUser = map['user'] is Map<String, dynamic>
          ? map['user'] as Map<String, dynamic>
          : null;

      final id = (map['id'] ??
              map['user_id'] ??
              nestedUser?['id'] ??
              nestedUser?['user_id'] ??
              '')
          .toString()
          .trim();

      final username =
          (map['username'] ?? nestedUser?['username'] ?? '').toString().trim();

      final displayName = (map['display_name'] ??
              map['name'] ??
              nestedUser?['display_name'] ??
              nestedUser?['name'] ??
              '')
          .toString()
          .trim();

      final nickname =
          (map['nickname'] ?? nestedUser?['nickname'] ?? '').toString().trim();

      final role =
          (map['role'] ?? map['team_role'] ?? nestedUser?['role'] ?? '팀원')
              .toString()
              .trim();

      if (_isCurrentUser(
        id: id,
        username: username,
        displayName: displayName,
        nickname: nickname,
      )) {
        continue;
      }

      final name = [
        displayName,
        nickname,
        username,
      ].firstWhere(
        (e) => e.isNotEmpty,
        orElse: () => '이름 없음',
      );

      final status = _memberStatusFromMap(map);

      members.add(
        TeamMemberOverview(
          id: id,
          name: name,
          role: role.isEmpty ? '팀원' : role,
          status: status,
          tasks: taskMap[name] ?? const [],
        ),
      );
    }

    return members;
  }

  bool _isCurrentUser({
    required String id,
    required String username,
    required String displayName,
    required String nickname,
  }) {
    final myUserId = _normalize(_currentUserId ?? '');
    final myUsername = _normalize(_currentUsername ?? '');
    final myDisplayName = _normalize(_currentDisplayName ?? '');

    final normalizedId = _normalize(id);
    final normalizedUsername = _normalize(username);
    final normalizedDisplayName = _normalize(displayName);
    final normalizedNickname = _normalize(nickname);

    if (myUserId.isNotEmpty &&
        normalizedId.isNotEmpty &&
        myUserId == normalizedId) {
      return true;
    }

    if (myUsername.isNotEmpty &&
        normalizedUsername.isNotEmpty &&
        myUsername == normalizedUsername) {
      return true;
    }

    if (myDisplayName.isNotEmpty) {
      if (normalizedDisplayName.isNotEmpty &&
          myDisplayName == normalizedDisplayName) {
        return true;
      }
      if (normalizedNickname.isNotEmpty &&
          myDisplayName == normalizedNickname) {
        return true;
      }
      if (normalizedUsername.isNotEmpty &&
          myDisplayName == normalizedUsername) {
        return true;
      }
    }

    return false;
  }

  Map<String, List<String>> _buildTaskMap(List<TodoDisplayItem> items) {
    final Map<String, List<String>> taskMap = {};

    for (final item in items) {
      final key = item.assignee.trim();
      if (key.isEmpty) continue;
      taskMap.putIfAbsent(key, () => []);
      taskMap[key]!.add(item.title);
    }

    return taskMap;
  }

  String _memberStatusFromMap(Map<String, dynamic> map) {
    final raw = (map['status'] ?? map['activity_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (raw.contains('active') || raw.contains('활동')) return '활동중';
    if (raw.contains('inactive') || raw.contains('비활동')) return '비활동';
    if (raw.contains('pending') || raw.contains('대기')) return '대기';
    return '활동중';
  }

  int get _doneCount => widget.todoItems.where((e) => e.isDone).length;

  int get _totalCount => widget.todoItems.length;

  int get _progressPercent {
    if (_totalCount == 0) return 0;
    return ((_doneCount / _totalCount) * 100).round();
  }

  Color _todoStatusTextColor(String status) {
    switch (status.trim()) {
      case '완료':
        return kWine;
      case '진행중':
        return const Color(0xFFFF4A4A);
      case '대기':
        return const Color(0xFF8C7E7F);
      default:
        return kSub;
    }
  }

  Color _todoStatusBgColor(String status) {
    switch (status.trim()) {
      case '완료':
        return const Color(0xFFFFEFEF);
      case '진행중':
        return const Color(0xFFFFEFEF);
      case '대기':
        return const Color(0xFFF2F1F1);
      default:
        return const Color(0xFFF2F1F1);
    }
  }

  Color _memberStatusTextColor(String status) {
    switch (status.trim()) {
      case '활동중':
        return kGreen;
      case '비활동':
        return const Color(0xFF8C7E7F);
      case '대기':
        return const Color(0xFFFF8A3D);
      default:
        return kGreen;
    }
  }

  Color _memberStatusBgColor(String status) {
    switch (status.trim()) {
      case '활동중':
        return kGreenSoft;
      case '비활동':
        return kGrayBadge;
      case '대기':
        return const Color(0xFFFFF3E8);
      default:
        return kGreenSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kText,
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 44,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            '팀으로 돌아가기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kText,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        color: kWine,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const Text(
              'To do list',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: kText,
              ),
            ),
            const SizedBox(height: 14),
            _buildTodoCard(),
            const SizedBox(height: 22),
            const Text(
              '팀원 현황',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: kText,
              ),
            ),
            const SizedBox(height: 14),
            _buildMemberSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
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
        children: [
          Row(
            children: [
              Text(
                '총 $_totalCount개 중 $_doneCount개 완료',
                style: const TextStyle(
                  color: kSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kRedSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$_progressPercent%',
                  style: const TextStyle(
                    color: Color(0xFFFF4A4A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.todoItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const Text(
                '표시할 To do 항목이 없어요.',
                style: TextStyle(
                  color: kSub,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...widget.todoItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _TodoItemTile(
                  title: item.title,
                  assignee: item.assignee,
                  dueDateText: item.dueDateText,
                  status: item.status,
                  isDone: item.isDone,
                  statusBgColor: _todoStatusBgColor(item.status),
                  statusTextColor: _todoStatusTextColor(item.status),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberSection() {
    if (_isLoadingMembers) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          color: kWine,
          strokeWidth: 2.4,
        ),
      );
    }

    if (_memberLoadError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _memberLoadError!,
              style: const TextStyle(
                color: Color(0xFF9A4D36),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadMembersFromApi,
              style: OutlinedButton.styleFrom(
                foregroundColor: kWine,
                side: const BorderSide(color: kBorder),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_members.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: const Text(
          '불러온 팀원 정보가 없어요.',
          style: TextStyle(
            color: kSub,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Column(
      children: _members
          .map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MemberCard(
                name: member.name,
                role: member.role,
                taskCount: member.tasks.length,
                tasks: member.tasks,
                status: member.status,
                statusBgColor: _memberStatusBgColor(member.status),
                statusTextColor: _memberStatusTextColor(member.status),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TodoItemTile extends StatelessWidget {
  final String title;
  final String assignee;
  final String dueDateText;
  final String status;
  final bool isDone;
  final Color statusBgColor;
  final Color statusTextColor;

  const _TodoItemTile({
    required this.title,
    required this.assignee,
    required this.dueDateText,
    required this.status,
    required this.isDone,
    required this.statusBgColor,
    required this.statusTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isDone
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: isDone ? const Color(0xFF18A957) : const Color(0xFFFF3B3B),
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDone
                      ? const Color(0xFFA1A1AF)
                      : const Color(0xFF231A1C),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  decoration:
                      isDone ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$assignee · $dueDateText',
                style: const TextStyle(
                  color: Color(0xFF8C7E7F),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: statusBgColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberCard extends StatefulWidget {
  final String name;
  final String role;
  final int taskCount;
  final List<String> tasks;
  final String status;
  final Color statusBgColor;
  final Color statusTextColor;

  const _MemberCard({
    required this.name,
    required this.role,
    required this.taskCount,
    required this.tasks,
    required this.status,
    required this.statusBgColor,
    required this.statusTextColor,
  });

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  bool _isExpanded = false;

  List<String> get _visibleTasks {
    if (_isExpanded) return widget.tasks;
    return widget.tasks.take(2).toList();
  }

  bool get _canExpand => widget.tasks.length > 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEBE2DE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEAEA),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${widget.taskCount}',
              style: const TextStyle(
                color: Color(0xFFFF3B3B),
                fontSize: 20,
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
                  '${widget.name}  ${widget.taskCount}개 작업',
                  style: const TextStyle(
                    color: Color(0xFF231A1C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.role,
                  style: const TextStyle(
                    color: Color(0xFF8C7E7F),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (widget.tasks.isEmpty)
                  const Text(
                    '할당된 작업 없음',
                    style: TextStyle(
                      color: Color(0xFF8C7E7F),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else ...[
                  ..._visibleTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: Color(0xFFFF4A4A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task,
                              style: const TextStyle(
                                color: Color(0xFF231A1C),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_canExpand)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: const Color(0xFFA31621),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isExpanded ? '접기' : '더보기',
                                style: const TextStyle(
                                  color: Color(0xFFA31621),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: widget.statusBgColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.status,
                  style: TextStyle(
                    color: widget.statusTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
