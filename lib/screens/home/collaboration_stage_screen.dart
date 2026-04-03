import 'package:flutter/material.dart';

class CollaborationStageScreen extends StatefulWidget {
  const CollaborationStageScreen({super.key});

  @override
  State<CollaborationStageScreen> createState() =>
      _CollaborationStageScreenState();
}

class _CollaborationStageScreenState
    extends State<CollaborationStageScreen> {
  static const Color kPrimary = Color(0xFFA31621);
  static const Color kPrimaryDark = Color(0xFF7E1018);
  static const Color kBackground = Colors.white;
  static const Color kCard = Color(0xFFFFFCFC);
  static const Color kBorder = Color(0xFFE6CFCF);
  static const Color kText = Color(0xFF3A2A2A);
  static const Color kSubText = Color(0xFF7B6666);
  static const Color kSoftPink = Color(0xFFF4E7E7);
  static const Color kMint = Color(0xFF21B36B);
  static const Color kBlue = Color(0xFF4A7DFF);
  static const Color kYellow = Color(0xFFF0C84B);
  static const Color kGrayDot = Color(0xFFD5D2D2);

  int _selectedTab = 0;

  final List<_TaskItem> _tasks = [
    _TaskItem(
      title: '시장 조사 및 경쟁 분석',
      assignee: '최현우',
      dueDate: '2024-03-20',
      priority: '높음',
      status: '완료',
      progress: 1.0,
    ),
    _TaskItem(
      title: '와이어프레임 디자인',
      assignee: '박지은',
      dueDate: '2024-03-25',
      priority: '높음',
      status: '진행중',
      progress: 0.7,
    ),
    _TaskItem(
      title: '기술 스택 선정',
      assignee: '이민수',
      dueDate: '2024-03-27',
      priority: '보통',
      status: '진행중',
      progress: 0.45,
    ),
    _TaskItem(
      title: '프로젝트 문서 작성',
      assignee: '김경희',
      dueDate: '2024-03-30',
      priority: '보통',
      status: '대기',
      progress: 0.0,
    ),
  ];

  final List<_TimelineItem> _timelineItems = [
    _TimelineItem(
      date: '2024-03-20',
      title: '시장 조사 완료',
      subtitle: '1차 자료조사 및 경쟁 서비스 분석 정리',
      color: kMint,
    ),
    _TimelineItem(
      date: '',
      title: '기술 스택 및 개발 환경 선정',
      subtitle: '디자인/프론트/백엔드 방향 확정',
      color: kBlue,
    ),
    _TimelineItem(
      date: '',
      title: '개발 시작 예정',
      subtitle: '기능 우선순위 기준으로 개발 시작',
      color: kGrayDot,
    ),
  ];

  final List<_MemberItem> _members = [
    _MemberItem(
      name: '김경희',
      initials: '김',
      assignedCount: 1,
      status: '활동중',
      hasBadge: true,
    ),
    _MemberItem(
      name: '이민수',
      initials: '이',
      assignedCount: 1,
      status: '활동중',
    ),
    _MemberItem(
      name: '박지은',
      initials: '박',
      assignedCount: 1,
      status: '활동중',
    ),
    _MemberItem(
      name: '최현우',
      initials: '최',
      assignedCount: 1,
      status: '활동중',
    ),
  ];

  double get _projectProgress {
    if (_tasks.isEmpty) return 0;
    final completedCount = _tasks.where((e) => e.status == '완료').length;
    return completedCount / _tasks.length;
  }

  int get _completedCount => _tasks.where((e) => e.status == '완료').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: kText,
          ),
        ),
        titleSpacing: 0,
        title: const Text(
          '팀으로 돌아가기',
          style: TextStyle(
            color: kText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            _buildProgressCard(),
            const SizedBox(height: 14),
            _buildTabBar(),
            const SizedBox(height: 16),
            _buildSelectedSection(),
            const SizedBox(height: 18),
            _buildCoachMessageCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
  final progressPercent = (_projectProgress * 100).round();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: kBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10A31621),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                ' To do list',
                style: TextStyle(
                  color: kText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFEF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$progressPercent%',
                style: const TextStyle(
                  color: kPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        ..._tasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    task.status == '완료'
                        ? Icons.check_circle_rounded
                        : task.status == '진행중'
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: task.status == '완료'
                        ? kMint
                        : task.status == '진행중'
                            ? kPrimary
                            : const Color(0xFFB8A9A9),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: kText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: task.status == '완료'
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: const Color(0xFF9E8C8C),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${task.assignee} · ${task.dueDate}',
                        style: const TextStyle(
                          color: kSubText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(task.status),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),
        Text(
          '총 ${_tasks.length}개 중 $_completedCount개 완료',
          style: const TextStyle(
            color: kSubText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildTabBar() {
    const tabs = [
      {'icon': Icons.description_outlined, 'label': '작업 목록'},
      {'icon': Icons.show_chart_rounded, 'label': '타임라인'},
      {'icon': Icons.people_outline_rounded, 'label': '팀원 현황'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kSoftPink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x0FA31621),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      size: 16,
                      color: selected ? kPrimary : kSubText,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tabs[index]['label'] as String,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? kPrimary : kText,
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedSection() {
    if (_selectedTab == 0) {
      return Column(
        children: _tasks.map((task) => _buildTaskCard(task)).toList(),
      );
    } else if (_selectedTab == 1) {
      return _buildTimelineCard();
    } else {
      return Column(
        children: _members.map((member) => _buildMemberCard(member)).toList(),
      );
    }
  }

  Widget _buildTaskCard(_TaskItem task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: _buildTaskStatusIcon(task.status),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: kText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '담당: ${task.assignee}',
                  style: const TextStyle(
                    color: kSubText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '마감: ${task.dueDate}',
                  style: const TextStyle(
                    color: kSubText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: task.progress,
                    backgroundColor: const Color(0xFFF0E2E2),
                    valueColor: AlwaysStoppedAnimation(
                      task.status == '완료'
                          ? kMint
                          : task.status == '대기'
                              ? const Color(0xFFBDB5B5)
                              : kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPriorityChip(task.priority),
              const SizedBox(height: 8),
              _buildStatusChip(task.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: List.generate(_timelineItems.length, (index) {
          final item = _timelineItems[index];
          final isLast = index == _timelineItems.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 54,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: const Color(0xFFE7D7D7),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.date.isNotEmpty)
                        Text(
                          item.date,
                          style: const TextStyle(
                            color: kSubText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (item.date.isNotEmpty) const SizedBox(height: 3),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: kText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: kSubText,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMemberCard(_MemberItem member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF8EEEE),
                  border: Border.all(color: const Color(0xFFE7C9C9)),
                ),
                alignment: Alignment.center,
                child: Text(
                  member.initials,
                  style: const TextStyle(
                    color: Color(0xFFC4A9A9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (member.hasBadge)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '4',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    color: kText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${member.assignedCount}개 작업 담당',
                  style: const TextStyle(
                    color: kSubText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            member.status,
            style: const TextStyle(
              color: Color(0xFF0BAF4B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachMessageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
Container(
  width: 110,
  height: 110,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white,
    border: Border.all(
      color: kBorder,
      width: 2,
    ),
  ),
  alignment: Alignment.center,
  child: Padding(
    padding: const EdgeInsets.all(10),
    child: Image.asset(
      'assets/images/happykhuong.png',
      width: 100,
      height: 100,
      fit: BoxFit.contain,
    ),
  ),
),
          const SizedBox(height: 14),
          const Text(
            '쿠옹 코치 한마디',
            style: TextStyle(
              color: kPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
  '팀원들이 맡은 작업을 차근차근 잘 진행하고 있어요.\n이 흐름대로만 가면 다음 단계도 안정적으로 이어질 수 있어요.\n지금처럼 협업 리듬을 잘 유지해봐요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kText,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusIcon(String status) {
    if (status == '완료') {
      return const Icon(
        Icons.check_circle_outline_rounded,
        color: kMint,
        size: 20,
      );
    }
    if (status == '진행중') {
      return const Icon(
        Icons.access_time_rounded,
        color: kBlue,
        size: 20,
      );
    }
    return const Icon(
      Icons.radio_button_unchecked_rounded,
      color: Color(0xFF8A7C7C),
      size: 20,
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color bg;
    Color textColor;

    switch (priority) {
      case '높음':
        bg = const Color(0xFFFFE5E5);
        textColor = kPrimary;
        break;
      case '보통':
        bg = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF9A7300);
        break;
      default:
        bg = const Color(0xFFEEEEEE);
        textColor = const Color(0xFF666666);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color textColor;

    switch (status) {
      case '완료':
        bg = const Color(0xFFFFE9E9);
        textColor = kPrimary;
        break;
      case '진행중':
        bg = const Color(0xFFFFEFEF);
        textColor = kPrimary;
        break;
      case '대기':
        bg = const Color(0xFFF3EAEA);
        textColor = const Color(0xFF8A6B6B);
        break;
      default:
        bg = const Color(0xFFF3EAEA);
        textColor = const Color(0xFF8A6B6B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TaskItem {
  final String title;
  final String assignee;
  final String dueDate;
  final String priority;
  final String status;
  final double progress;

  _TaskItem({
    required this.title,
    required this.assignee,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.progress,
  });
}

class _TimelineItem {
  final String date;
  final String title;
  final String subtitle;
  final Color color;

  _TimelineItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _MemberItem {
  final String name;
  final String initials;
  final int assignedCount;
  final String status;
  final bool hasBadge;

  _MemberItem({
    required this.name,
    required this.initials,
    required this.assignedCount,
    required this.status,
    this.hasBadge = false,
  });
}