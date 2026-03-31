import 'package:flutter/material.dart';

import '../models/project_detail_model.dart';
import '../services/project_service.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  final String? accessToken;

  const ProjectListScreen({super.key, this.accessToken});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  static const Color kWine = Color(0xFFA31621);
  static const Color kCream = Color(0xFFF6F1F1);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF3A2A2A);
  static const Color kSub = Color(0xFF7D6666);
  static const Color kBorder = Color(0xFFE7C9C9);
  static const Color kSoftCard = Color(0xFFFCFBFB);
  static const Color kInputFill = Color(0xFFF9F1F1);

  late final ProjectService _projectService;

  bool _isLoading = true;
  String? _loadError;

  List<ProjectDetailModel> projects = [];

  @override
  void initState() {
    super.initState();

    _projectService = ProjectService(
      baseUrl: 'https://semothon13app-production.up.railway.app',
      accessToken: widget.accessToken,
    );

    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final fetched = await _projectService.fetchProjects();

      if (!mounted) return;

      setState(() {
        projects = List<ProjectDetailModel>.from(fetched);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        projects = List<ProjectDetailModel>.from(_fallbackProjects());
        _loadError = '서버 프로젝트 목록을 불러오지 못해 임시 데이터를 표시합니다.';
        _isLoading = false;
      });
    }
  }

  List<ProjectDetailModel> _fallbackProjects() {
    return const [
      ProjectDetailModel(
        projectNumber: '13',
        projectTitle: '세계와 시민',
        projectGoal: '팀 프로젝트 목표를 설정하세요.',
        members: [],
        schedules: [],
        roles: [],
        chatMessages: [],
        notifications: [],
      ),
      ProjectDetailModel(
        projectNumber: '12',
        projectTitle: '소프트웨어공학',
        projectGoal: '프로젝트 목표를 입력하세요.',
        members: [],
        schedules: [],
        roles: [],
        chatMessages: [],
        notifications: [],
      ),
      ProjectDetailModel(
        projectNumber: '7',
        projectTitle: '데이터베이스',
        projectGoal: '데이터베이스 프로젝트 목표를 입력하세요.',
        members: [],
        schedules: [],
        roles: [],
        chatMessages: [],
        notifications: [],
      ),
    ];
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _statusColor(String status) {
    if (status.contains('기한 지난')) return const Color(0xFFFF6B2C);
    if (status.contains('마감 임박')) return const Color(0xFFFF8A3D);
    if (status.contains('지연')) return const Color(0xFFFF6B2C);
    if (status.contains('완료')) return const Color(0xFF2E9E57);
    if (status.contains('준비')) return const Color(0xFF8B8480);
    return kWine;
  }

  String _summaryStatus(ProjectDetailModel project) {
    int overdueCount = 0;
    int urgentCount = 0;
    int delayedRoleCount = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (final role in project.roles) {
      if (role.status == '지연') {
        delayedRoleCount++;
      }

      for (final task in role.tasks) {
        if (task.done) continue;

        final due = DateTime(
          task.dueDate.year,
          task.dueDate.month,
          task.dueDate.day,
        );

        if (due.isBefore(today)) {
          overdueCount++;
        } else if (due == tomorrow) {
          urgentCount++;
        }
      }
    }

    if (overdueCount > 0) return '기한 지난 업무 $overdueCount개';
    if (urgentCount > 0) return '마감 임박 업무 $urgentCount개';
    if (delayedRoleCount > 0) return '역할 $delayedRoleCount개 지연';
    if (project.roles.isEmpty &&
        project.members.isEmpty &&
        project.schedules.isEmpty) {
      return '준비 중';
    }
    return '진행 중';
  }

  String _updatedText(ProjectDetailModel project) {
    return '최근 업데이트 프로젝트 #${project.projectNumber}';
  }

  Future<void> _showAddProjectDialog() async {
    final titleController = TextEditingController();
    final goalController = TextEditingController();

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '새 프로젝트 추가',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _DialogField(
                  controller: titleController,
                  label: '프로젝트 이름',
                  hintText: '예: 운영체제 팀플',
                ),
                const SizedBox(height: 14),
                _DialogField(
                  controller: goalController,
                  label: '프로젝트 목표',
                  hintText: '예: 발표 자료 완성 및 발표 준비',
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: kBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            color: kSub,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final goal = goalController.text.trim();

                          if (title.isEmpty) return;

                          try {
                            final created = await _projectService.createProject(
                              title: title,
                              goal: goal.isEmpty ? '프로젝트 목표를 입력하세요.' : goal,
                            );

                            if (!mounted) return;

                            setState(() {
                              projects = [created, ...projects];
                            });

                            Navigator.of(dialogContext).pop();
                            _showSnackBar('프로젝트를 추가했어요.');
                          } catch (_) {
                            if (!mounted) return;

                            final nextNumber = _nextProjectNumber();

                            setState(() {
                              projects = [
                                ProjectDetailModel(
                                  projectNumber: nextNumber,
                                  projectTitle: title,
                                  projectGoal:
                                      goal.isEmpty ? '프로젝트 목표를 입력하세요.' : goal,
                                  members: const [],
                                  schedules: const [],
                                  roles: const [],
                                  chatMessages: const [],
                                  notifications: const [],
                                ),
                                ...projects,
                              ];
                            });

                            Navigator.of(dialogContext).pop();
                            _showSnackBar('서버 생성이 불가능해 임시 프로젝트로 추가했습니다.');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kWine,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '추가',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _nextProjectNumber() {
    int maxNumber = 0;
    for (final project in projects) {
      final parsed = int.tryParse(project.projectNumber) ?? 0;
      if (parsed > maxNumber) {
        maxNumber = parsed;
      }
    }
    return '${maxNumber + 1}';
  }

  Future<void> _showEditProjectDialog(int index) async {
    final controller = TextEditingController(
      text: projects[index].projectTitle,
    );

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '프로젝트 이름 수정',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _DialogField(
                  controller: controller,
                  label: '프로젝트 이름',
                  hintText: '프로젝트 이름을 입력하세요',
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: kBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            color: kSub,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final newTitle = controller.text.trim();
                          if (newTitle.isEmpty) return;

                          setState(() {
                            projects[index] = projects[index].copyWith(
                              projectTitle: newTitle,
                            );
                          });

                          Navigator.of(dialogContext).pop();
                          _showSnackBar('현재 이름 수정은 로컬 반영만 가능합니다.');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kWine,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditGoalDialog(int index) async {
    final controller = TextEditingController(text: projects[index].projectGoal);

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '프로젝트 목표 수정',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _DialogField(
                  controller: controller,
                  label: '프로젝트 목표',
                  hintText: '프로젝트 목표를 입력하세요',
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: kBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            color: kSub,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final newGoal = controller.text.trim();
                          if (newGoal.isEmpty) return;

                          setState(() {
                            projects[index] = projects[index].copyWith(
                              projectGoal: newGoal,
                            );
                          });

                          Navigator.of(dialogContext).pop();
                          _showSnackBar('현재 목표 수정은 로컬 반영만 가능합니다.');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kWine,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteDialog(int index) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '프로젝트 삭제',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '\'${projects[index].projectTitle}\' 프로젝트를 삭제할까요?',
                    style: const TextStyle(
                      fontSize: 15,
                      color: kSub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: kBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            color: kSub,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            projects = List<ProjectDetailModel>.from(projects)
                              ..removeAt(index);
                          });

                          Navigator.of(dialogContext).pop();
                          _showSnackBar('현재 삭제는 로컬 반영만 가능합니다.');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD94A3A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '삭제',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showProjectMenu(int index) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DDD8),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              _MenuTile(
                icon: Icons.edit_outlined,
                title: '이름 수정',
                onTap: () => Navigator.of(sheetContext).pop('edit_name'),
              ),
              _MenuTile(
                icon: Icons.flag_outlined,
                title: '목표 수정',
                onTap: () => Navigator.of(sheetContext).pop('edit_goal'),
              ),
              _MenuTile(
                icon: Icons.delete_outline,
                title: '삭제',
                textColor: const Color(0xFFD94A3A),
                onTap: () => Navigator.of(sheetContext).pop('delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (action == 'edit_name') {
      await _showEditProjectDialog(index);
    } else if (action == 'edit_goal') {
      await _showEditGoalDialog(index);
    } else if (action == 'delete') {
      await _showDeleteDialog(index);
    }
  }

  Future<void> _openProject(ProjectDetailModel project, int index) async {
    final result = await Navigator.push<ProjectDetailModel>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProjectDetailScreen(project: project, service: _projectService),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        projects[index] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Center(
          child: RefreshIndicator(
            onRefresh: _loadProjects,
            color: kWine,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopSection(context),
                      const SizedBox(height: 18),
                      _buildIntroCard(),
                      if (_loadError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4F1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFFFD6CC),
                            ),
                          ),
                          child: Text(
                            _loadError!,
                            style: const TextStyle(
                              color: Color(0xFF9A4D36),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _showAddProjectDialog,
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            '새 프로젝트 추가',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: kWine,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        '✶ 내 프로젝트',
                        style: TextStyle(
                          color: kWine,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_isLoading)
                        const _LoadingProjectView()
                      else if (projects.isEmpty)
                        const _EmptyProjectView()
                      else
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: projects.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final project = projects[index];
                            final summaryStatus = _summaryStatus(project);

                            return _ProjectCard(
                              project: project,
                              statusColor: _statusColor(summaryStatus),
                              summaryStatus: summaryStatus,
                              updatedText: _updatedText(project),
                              onTap: () => _openProject(project, index),
                              onMoreTap: () => _showProjectMenu(index),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new, size: 16, color: kSub),
                SizedBox(width: 4),
                Text(
                  '홈으로',
                  style: TextStyle(
                    color: kSub,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Text(
          '프로젝트',
          style: TextStyle(
            color: kText,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: kSoftCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAE1E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        '현재 진행 중인 프로젝트와 상태를 한눈에 확인하고, 필요하면 이름이나 목표를 바로 수정해보세요.',
        style: TextStyle(fontSize: 15, color: Color(0xFF4B3A3A), height: 1.5),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectDetailModel project;
  final Color statusColor;
  final String summaryStatus;
  final String updatedText;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _ProjectCard({
    required this.project,
    required this.statusColor,
    required this.summaryStatus,
    required this.updatedText,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _ProjectListScreenState.kSoftCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _ProjectListScreenState.kBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.projectTitle,
                      style: const TextStyle(
                        color: _ProjectListScreenState.kText,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: onMoreTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7EFEF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: _ProjectListScreenState.kSub,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '#${project.projectNumber}',
                style: const TextStyle(
                  color: _ProjectListScreenState.kSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  summaryStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                updatedText,
                style: const TextStyle(
                  color: _ProjectListScreenState.kSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFF0E8E4), height: 1),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.group_outlined,
                    text: '${project.members.length}명',
                  ),
                  _InfoChip(
                    icon: Icons.work_outline,
                    text: '역할 ${project.roles.length}개',
                  ),
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    text: '일정 ${project.schedules.length}개',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: _ProjectListScreenState.kSub),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: _ProjectListScreenState.kText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _ProjectListScreenState.kText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFA58787),
              fontSize: 14,
            ),
            filled: true,
            fillColor: _ProjectListScreenState.kInputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: _ProjectListScreenState.kBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: _ProjectListScreenState.kWine,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? _ProjectListScreenState.kText;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 24,
    );
  }
}

class _EmptyProjectView extends StatelessWidget {
  const _EmptyProjectView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE1E1)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 34,
            color: _ProjectListScreenState.kSub,
          ),
          SizedBox(height: 12),
          Text(
            '아직 프로젝트가 없습니다.',
            style: TextStyle(
              color: _ProjectListScreenState.kText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '새 프로젝트를 추가해서 시작해보세요.',
            style: TextStyle(
              color: _ProjectListScreenState.kSub,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadingProjectView extends StatelessWidget {
  const _LoadingProjectView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE1E1)),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: _ProjectListScreenState.kWine,
            ),
          ),
          SizedBox(height: 14),
          Text(
            '프로젝트를 불러오는 중입니다...',
            style: TextStyle(
              color: _ProjectListScreenState.kSub,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
