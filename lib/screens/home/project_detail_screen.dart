import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/app_notification_model.dart';
import '../models/chat_message_model.dart';
import '../models/member_model.dart';
import '../models/project_detail_model.dart';
import '../models/role_model.dart';
import '../models/schedule_model.dart';
import '../models/task_model.dart';
import '../services/project_service.dart';

String formatDate(DateTime date) {
  return '${date.month}월 ${date.day}일';
}

String formatTimeOfDay(TimeOfDay time) {
  final period = time.hour < 12 ? '오전' : '오후';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$period $hour:$minute';
}

class ProjectDetailScreen extends StatefulWidget {
  final ProjectDetailModel project;
  final ProjectService service;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.service,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  static const Color kWine = Color(0xFFA31621);
  static const Color kCream = Color(0xFFFCFAF7);
  static const Color kCard = Color(0xFFFFFFFF);
  static const Color kSoft = Color(0xFFF7F3EF);
  static const Color kText = Color(0xFF231A1C);
  static const Color kSub = Color(0xFF8C7E7F);
  static const Color kPurple = Color(0xFF8B5CF6);
  static const Color kOrange = Color(0xFFF08A4B);
  static const Color kGreen = Color(0xFF2E9B64);
  static const Color kBlue = Color(0xFF4E6EF2);
  static const Color kRedSoft = Color(0xFFFFF3F0);

  int selectedTabIndex = 0;
  int? expandedRoleIndex = 0;

  late ProjectDetailModel project;

  final TextEditingController chatController = TextEditingController();
  final ScrollController chatScrollController = ScrollController();
  final FocusNode chatFocusNode = FocusNode();

  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isSendingChat = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    project = widget.project;
    _refreshAllRoleStatuses();
    _loadProjectDetail(showLoading: false);

    chatFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    chatController.dispose();
    chatScrollController.dispose();
    chatFocusNode.dispose();
    super.dispose();
  }

  List<MemberModel> get members => project.members;
  List<ScheduleModel> get schedules => project.schedules;
  List<RoleModel> get roles => project.roles;
  List<ChatMessageModel> get chatMessages => project.chatMessages;
  List<AppNotificationModel> get notifications => project.notifications;

  int _maxBy<T>(List<T> items, int Function(T) pick) {
    if (items.isEmpty) return 0;
    return items.map(pick).reduce((a, b) => a > b ? a : b);
  }

  int _nextMemberId() => _maxBy(members, (item) => item.id) + 1;

  int _nextScheduleId() => _maxBy(schedules, (item) => item.id) + 1;

  int _nextTaskId() {
    int maxId = 0;
    for (final role in roles) {
      for (final task in role.tasks) {
        if (task.id > maxId) maxId = task.id;
      }
    }
    return maxId + 1;
  }

  int _nextChatId() => _maxBy(chatMessages, (item) => item.id) + 1;

  String _nowLabel() {
    final now = TimeOfDay.now();
    return formatTimeOfDay(now);
  }

  Future<void> _loadProjectDetail({bool showLoading = true}) async {
    // ✅ 1. mock 프로젝트면 API 호출 안함 (404 방지)
    if (project.projectNumber == '12' ||
        project.projectNumber == '13' ||
        project.projectNumber == '7') {
      if (!mounted) return;
      setState(() {
        project = widget.project;
        _refreshAllRoleStatuses();
        _errorText = null;
        _isLoading = false;
      });
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorText = null;
      });
    }

    try {
      final fetched = await widget.service.fetchProjectDetail(
        project.projectNumber,
      );

      if (!mounted) return;
      setState(() {
        project = fetched;
        _refreshAllRoleStatuses();
        _errorText = null;
      });
    } catch (e) {
      if (!mounted) return;

      // ✅ 2. 실패해도 기존 UI 유지
      setState(() {
        project = widget.project;
        _refreshAllRoleStatuses();
        _errorText = null;
      });

      _showErrorSnackBar('서버 연결 실패 → 기존 데이터 표시');
    } finally {
      if (!mounted) return;
      if (showLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadProject() async {
    await _loadProjectDetail(showLoading: false);
  }

  void _showErrorSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _showSuccessSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Color statusColor(String status) {
    switch (status) {
      case '완료':
        return kGreen;
      case '지연':
        return kOrange;
      case '마감 임박':
        return kOrange;
      case '시작 전':
        return kSub;
      default:
        return kWine;
    }
  }

  int completedTaskCount(RoleModel role) {
    return role.tasks.where((task) => task.done).length;
  }

  int totalTaskCount(RoleModel role) {
    return role.tasks.length;
  }

  bool isDueTomorrow(TaskModel task) {
    if (task.done) return false;
    final now = DateTime.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final due = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
    );
    return due == tomorrow;
  }

  bool isOverdue(TaskModel task) {
    if (task.done) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
    );
    return due.isBefore(today);
  }

  int get urgentTaskCount {
    int count = 0;
    for (final role in roles) {
      for (final task in role.tasks) {
        if (isDueTomorrow(task)) count++;
      }
    }
    return count;
  }

  int get overdueTaskCount {
    int count = 0;
    for (final role in roles) {
      for (final task in role.tasks) {
        if (isOverdue(task)) count++;
      }
    }
    return count;
  }

  List<_UrgentTaskView> get urgentTasks {
    final List<_UrgentTaskView> items = [];
    for (final role in roles) {
      for (final task in role.tasks) {
        if (isDueTomorrow(task) || isOverdue(task)) {
          items.add(
            _UrgentTaskView(
              title: task.title,
              assignee: role.assignee,
              priority: task.priority,
              dueDate: task.dueDate,
              isOverdue: isOverdue(task),
            ),
          );
        }
      }
    }
    return items;
  }

  List<ChatMessageModel> get fileMessages {
    return chatMessages
        .where((message) => message.isFile)
        .toList()
        .reversed
        .toList();
  }

  int get unreadChatCount {
    return chatMessages
        .where((message) => message.sender != '나' && !message.isRead)
        .length;
  }

  int get unreadNotificationCount {
    return notifications.where((item) => !item.isRead).length;
  }

  String get summaryStatus {
    if (overdueTaskCount > 0) return '기한 지난 업무 $overdueTaskCount개';
    if (urgentTaskCount > 0) return '마감 임박 업무 $urgentTaskCount개';
    final delayedCount = roles.where((role) => role.status == '지연').length;
    if (delayedCount > 0) return '역할 $delayedCount개 지연';
    return '전체 흐름 안정적';
  }

  void _refreshAllRoleStatuses() {
    final updatedRoles = roles.map((role) {
      final completed = role.tasks.where((task) => task.done).length;
      final total = role.tasks.length;

      final hasOverdue = role.tasks.any(isOverdue);
      final hasUrgent = role.tasks.any(isDueTomorrow);

      String newStatus = '시작 전';

      if (hasOverdue) {
        newStatus = '지연';
      } else if (completed == total && total > 0) {
        newStatus = '완료';
      } else if (hasUrgent && completed < total) {
        newStatus = '마감 임박';
      } else if (completed == 0 && total > 0) {
        newStatus = '시작 전';
      } else if (completed > 0 && completed < total) {
        newStatus = '진행 중';
      }

      return role.copyWith(status: newStatus);
    }).toList();

    project = project.copyWith(roles: updatedRoles);
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!chatScrollController.hasClients) return;
      chatScrollController.animateTo(
        chatScrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String fileTypeLabel(String message) {
    final firstLine = message.split('\n').first.toLowerCase();

    if (firstLine.startsWith('http://') || firstLine.startsWith('https://')) {
      return '링크';
    }

    if (firstLine.endsWith('.jpg') ||
        firstLine.endsWith('.jpeg') ||
        firstLine.endsWith('.png') ||
        firstLine.endsWith('.gif') ||
        firstLine.endsWith('.mp4') ||
        firstLine.endsWith('.mov')) {
      return '사진/동영상';
    }

    return '파일';
  }

  IconData fileTypeIcon(String message) {
    final type = fileTypeLabel(message);
    if (type == '사진/동영상') return Icons.photo_library_rounded;
    if (type == '링크') return Icons.link_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color fileTypeColor(String message) {
    final type = fileTypeLabel(message);
    if (type == '사진/동영상') return const Color(0xFF16A34A);
    if (type == '링크') return const Color(0xFF2F80ED);
    return const Color(0xFF6B7280);
  }

  Future<void> _markAllChatAsRead() async {
    try {
      await widget.service.readAllChat(project.projectNumber);
      await _reloadProject();
    } on UnsupportedError {
      final updated = chatMessages.map((message) {
        if (message.sender == '나' || message.isRead) return message;
        return message.copyWith(isRead: true);
      }).toList();

      if (!mounted) return;
      setState(() {
        project = project.copyWith(chatMessages: updated);
      });
    } catch (e) {
      _showErrorSnackBar('채팅 읽음 처리에 실패했어요.');
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      await widget.service.readAllNotifications(project.projectNumber);
      await _reloadProject();
    } on UnsupportedError {
      final updated = notifications
          .map((item) => item.isRead ? item : item.copyWith(isRead: true))
          .toList();

      if (!mounted) return;
      setState(() {
        project = project.copyWith(notifications: updated);
      });
    } catch (e) {
      _showErrorSnackBar('알림 읽음 처리에 실패했어요.');
    }
  }

  Future<void> toggleTask(int roleIndex, int taskIndex) async {
    final role = roles[roleIndex];
    final task = role.tasks[taskIndex];

    try {
      await widget.service.updateTask(
        projectNumber: project.projectNumber,
        roleId: role.id,
        taskId: task.id,
        dueDate: task.dueDate,
        done: !task.done,
      );
      await _reloadProject();
    } on UnsupportedError {
      final updatedRoles = [...roles];
      final updatedTasks = [...role.tasks];
      updatedTasks[taskIndex] = task.copyWith(done: !task.done);
      updatedRoles[roleIndex] = role.copyWith(tasks: updatedTasks);

      if (!mounted) return;
      setState(() {
        project = project.copyWith(roles: updatedRoles);
        _refreshAllRoleStatuses();
      });
    } catch (e) {
      _showErrorSnackBar('업무 상태 변경에 실패했어요.');
    }
  }

  Future<void> deleteTask(int roleIndex, int taskIndex) async {
    final role = roles[roleIndex];
    final task = role.tasks[taskIndex];

    try {
      await widget.service.deleteTask(
        projectNumber: project.projectNumber,
        roleId: role.id,
        taskId: task.id,
      );
      await _reloadProject();
      _showSuccessSnackBar('${task.title} 업무를 삭제했어요.');
    } on UnsupportedError {
      final updatedRoles = [...roles];
      final updatedTasks = [...role.tasks]..removeAt(taskIndex);
      updatedRoles[roleIndex] = role.copyWith(tasks: updatedTasks);

      if (!mounted) return;
      setState(() {
        project = project.copyWith(roles: updatedRoles);
        _refreshAllRoleStatuses();
      });
      _showSuccessSnackBar('${task.title} 업무를 삭제했어요.');
    } catch (e) {
      _showErrorSnackBar('업무 삭제에 실패했어요.');
    }
  }

  Future<void> sendChatMessage() async {
    final text = chatController.text.trim();
    if (text.isEmpty || _isSendingChat) return;

    setState(() {
      _isSendingChat = true;
    });

    try {
      await widget.service.sendChat(
        projectNumber: project.projectNumber,
        message: text,
        isFile: false,
      );
      chatController.clear();
      await _reloadProject();
      _scrollChatToBottom();
    } on UnsupportedError {
      final updated = [
        ...chatMessages,
        ChatMessageModel(
          id: _nextChatId(),
          sender: '나',
          message: text,
          time: _nowLabel(),
          isMe: true,
          isRead: true,
          isAi: false,
          isFile: false,
        ),
      ];

      if (!mounted) return;
      setState(() {
        project = project.copyWith(chatMessages: updated);
      });
      chatController.clear();
      _scrollChatToBottom();
    } catch (e) {
      _showErrorSnackBar('채팅 전송에 실패했어요.');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSendingChat = false;
      });
    }
  }

  Future<void> _sendAttachmentMessage(String message) async {
    try {
      await widget.service.sendChat(
        projectNumber: project.projectNumber,
        message: message,
        isFile: true,
      );
      await _reloadProject();
      _scrollChatToBottom();
    } on UnsupportedError {
      final updated = [
        ...chatMessages,
        ChatMessageModel(
          id: _nextChatId(),
          sender: '나',
          message: message,
          time: _nowLabel(),
          isMe: true,
          isRead: true,
          isAi: false,
          isFile: true,
        ),
      ];

      if (!mounted) return;
      setState(() {
        project = project.copyWith(chatMessages: updated);
      });
      _scrollChatToBottom();
    } catch (e) {
      _showErrorSnackBar('파일 공유에 실패했어요.');
    }
  }

  Future<void> showAddMemberSheet() async {
    final nameController = TextEditingController();
    final studentIdController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '팀원 추가',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DialogField(
                  controller: nameController,
                  label: '이름',
                  hintText: '팀원 이름을 입력하세요',
                ),
                const SizedBox(height: 14),
                _DialogField(
                  controller: studentIdController,
                  label: '학번',
                  hintText: '학번을 입력하세요',
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFFE4D9D4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            color: kSub,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final studentId = studentIdController.text.trim();
                          if (name.isEmpty || studentId.isEmpty) return;

                          try {
                            await widget.service.createMember(
                              projectNumber: project.projectNumber,
                              name: name,
                              studentId: studentId,
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                            await _reloadProject();
                            _showSuccessSnackBar('팀원을 추가했어요.');
                          } on UnsupportedError {
                            final newMember = MemberModel(
                              id: _nextMemberId(),
                              name: name,
                              studentId: studentId,
                            );
                            if (!mounted) return;
                            setState(() {
                              project = project.copyWith(
                                members: [...members, newMember],
                              );
                            });
                            Navigator.pop(context);
                            _showSuccessSnackBar('팀원을 추가했어요.');
                          } catch (e) {
                            _showErrorSnackBar('팀원 추가에 실패했어요.');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kWine,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '추가',
                          style: TextStyle(fontWeight: FontWeight.w800),
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

  Future<void> showEditMemberSheet(MemberModel member, int index) async {
    final nameController = TextEditingController(text: member.name);
    final studentIdController = TextEditingController(text: member.studentId);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '팀원 수정',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DialogField(
                  controller: nameController,
                  label: '이름',
                  hintText: '팀원 이름을 입력하세요',
                ),
                const SizedBox(height: 14),
                _DialogField(
                  controller: studentIdController,
                  label: '학번',
                  hintText: '학번을 입력하세요',
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final studentId = studentIdController.text.trim();
                          if (name.isEmpty || studentId.isEmpty) return;

                          try {
                            await widget.service.updateMember(
                              projectNumber: project.projectNumber,
                              memberId: member.id,
                              name: name,
                              studentId: studentId,
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                            await _reloadProject();
                            _showSuccessSnackBar('팀원 정보를 수정했어요.');
                          } on UnsupportedError {
                            final updated = [...members];
                            updated[index] = member.copyWith(
                              name: name,
                              studentId: studentId,
                            );
                            if (!mounted) return;
                            setState(() {
                              project = project.copyWith(members: updated);
                            });
                            Navigator.pop(context);
                            _showSuccessSnackBar('팀원 정보를 수정했어요.');
                          } catch (e) {
                            _showErrorSnackBar('팀원 수정에 실패했어요.');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kWine,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('저장'),
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

  Future<void> deleteMember(int index) async {
    final member = members[index];

    try {
      await widget.service.deleteMember(
        projectNumber: project.projectNumber,
        memberId: member.id,
      );
      await _reloadProject();
      _showSuccessSnackBar('${member.name} 팀원을 삭제했어요.');
    } on UnsupportedError {
      final updated = [...members]..removeAt(index);
      if (!mounted) return;
      setState(() {
        project = project.copyWith(members: updated);
      });
      _showSuccessSnackBar('${member.name} 팀원을 삭제했어요.');
    } catch (e) {
      _showErrorSnackBar('팀원 삭제에 실패했어요.');
    }
  }

  Future<void> showAddScheduleSheet() async {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay startTime = const TimeOfDay(hour: 14, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 16, minute: 0);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '일정 추가',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _DialogField(
                      controller: titleController,
                      label: '제목',
                      hintText: '예: 중간 점검 회의',
                    ),
                    const SizedBox(height: 14),
                    _DateSelectField(
                      label: '날짜',
                      text: formatDate(selectedDate),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setInnerState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeSelectField(
                            label: '시작 시간',
                            text: formatTimeOfDay(startTime),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                              );
                              if (picked != null) {
                                setInnerState(() {
                                  startTime = picked;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeSelectField(
                            label: '종료 시간',
                            text: formatTimeOfDay(endTime),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                              );
                              if (picked != null) {
                                setInnerState(() {
                                  endTime = picked;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final title = titleController.text.trim();
                              if (title.isEmpty) return;

                              try {
                                await widget.service.createSchedule(
                                  projectNumber: project.projectNumber,
                                  title: title,
                                  date: selectedDate,
                                  startTime: startTime,
                                  endTime: endTime,
                                );
                                if (!mounted) return;
                                Navigator.pop(context);
                                await _reloadProject();
                                _showSuccessSnackBar('일정을 추가했어요.');
                              } on UnsupportedError {
                                final newSchedule = ScheduleModel(
                                  id: _nextScheduleId(),
                                  title: title,
                                  date: selectedDate,
                                  startTime: startTime,
                                  endTime: endTime,
                                );
                                if (!mounted) return;
                                setState(() {
                                  project = project.copyWith(
                                    schedules: [...schedules, newSchedule],
                                  );
                                });
                                Navigator.pop(context);
                                _showSuccessSnackBar('일정을 추가했어요.');
                              } catch (e) {
                                _showErrorSnackBar('일정 추가에 실패했어요.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kWine,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('추가'),
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
      },
    );
  }

  Future<void> showEditScheduleSheet(ScheduleModel schedule, int index) async {
    final titleController = TextEditingController(text: schedule.title);
    DateTime selectedDate = schedule.date;
    TimeOfDay startTime = schedule.startTime;
    TimeOfDay endTime = schedule.endTime;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '일정 수정',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _DialogField(
                      controller: titleController,
                      label: '제목',
                      hintText: '예: 중간 점검 회의',
                    ),
                    const SizedBox(height: 14),
                    _DateSelectField(
                      label: '날짜',
                      text: formatDate(selectedDate),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setInnerState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeSelectField(
                            label: '시작 시간',
                            text: formatTimeOfDay(startTime),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                              );
                              if (picked != null) {
                                setInnerState(() {
                                  startTime = picked;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeSelectField(
                            label: '종료 시간',
                            text: formatTimeOfDay(endTime),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                              );
                              if (picked != null) {
                                setInnerState(() {
                                  endTime = picked;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final title = titleController.text.trim();
                              if (title.isEmpty) return;

                              try {
                                await widget.service.updateSchedule(
                                  projectNumber: project.projectNumber,
                                  scheduleId: schedule.id,
                                  title: title,
                                  date: selectedDate,
                                  startTime: startTime,
                                  endTime: endTime,
                                );
                                if (!mounted) return;
                                Navigator.pop(context);
                                await _reloadProject();
                                _showSuccessSnackBar('일정을 수정했어요.');
                              } on UnsupportedError {
                                final updated = [...schedules];
                                updated[index] = schedule.copyWith(
                                  title: title,
                                  date: selectedDate,
                                  startTime: startTime,
                                  endTime: endTime,
                                );
                                if (!mounted) return;
                                setState(() {
                                  project =
                                      project.copyWith(schedules: updated);
                                });
                                Navigator.pop(context);
                                _showSuccessSnackBar('일정을 수정했어요.');
                              } catch (e) {
                                _showErrorSnackBar('일정 수정에 실패했어요.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kWine,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('저장'),
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
      },
    );
  }

  Future<void> deleteSchedule(int index) async {
    final schedule = schedules[index];

    try {
      await widget.service.deleteSchedule(
        projectNumber: project.projectNumber,
        scheduleId: schedule.id,
      );
      await _reloadProject();
      _showSuccessSnackBar('${schedule.title} 일정을 삭제했어요.');
    } on UnsupportedError {
      final updated = [...schedules]..removeAt(index);
      if (!mounted) return;
      setState(() {
        project = project.copyWith(schedules: updated);
      });
      _showSuccessSnackBar('${schedule.title} 일정을 삭제했어요.');
    } catch (e) {
      _showErrorSnackBar('일정 삭제에 실패했어요.');
    }
  }

  Future<void> _createRoleSmart({
    required String title,
    required String? selectedMemberName,
    required String inputMemberName,
  }) async {
    try {
      int memberId;
      String assigneeName;

      if (selectedMemberName != null && selectedMemberName.isNotEmpty) {
        final selectedMember = members.firstWhere(
          (m) => m.name == selectedMemberName,
        );
        memberId = selectedMember.id;
        assigneeName = selectedMember.name;
      } else {
        final typedName = inputMemberName.trim();
        if (typedName.isEmpty) {
          _showErrorSnackBar('팀원을 선택하거나 새 팀원 이름을 입력해주세요.');
          return;
        }

        final existingMembers =
            members.where((m) => m.name == typedName).toList();

        if (existingMembers.isNotEmpty) {
          memberId = existingMembers.first.id;
          assigneeName = existingMembers.first.name;
        } else {
          try {
            await widget.service.createMember(
              projectNumber: project.projectNumber,
              name: typedName,
              studentId: '',
            );
            await _reloadProject();

            final createdMember = project.members.firstWhere(
              (m) => m.name == typedName,
            );
            memberId = createdMember.id;
            assigneeName = createdMember.name;
          } on UnsupportedError {
            final newMember = MemberModel(
              id: _nextMemberId(),
              name: typedName,
              studentId: '',
            );

            setState(() {
              project = project.copyWith(
                members: [...members, newMember],
              );
            });

            memberId = newMember.id;
            assigneeName = newMember.name;
          }
        }
      }

      try {
        await widget.service.createRole(
          projectNumber: project.projectNumber,
          title: title,
          assigneeId: memberId,
        );
        await _reloadProject();
      } on UnsupportedError {
        final newRole = RoleModel(
          id: _maxBy(roles, (item) => item.id) + 1,
          title: title,
          assignee: assigneeName,
          status: '시작 전',
          tasks: [],
        );

        setState(() {
          project = project.copyWith(
            roles: [...roles, newRole],
          );
          _refreshAllRoleStatuses();
        });
      }

      _showSuccessSnackBar('역할을 추가했어요.');
    } catch (e) {
      _showErrorSnackBar('역할 추가에 실패했어요.');
    }
  }

  Future<void> showAddRoleSmartSheet() async {
    final titleController = TextEditingController();
    final memberInputController = TextEditingController();
    String? selectedMemberName;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '역할 추가',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _DialogField(
                      controller: titleController,
                      label: '역할 이름',
                      hintText: '예: 발표자, 자료조사, 디자인',
                    ),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '기존 팀원 선택',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kSub,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedMemberName,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFEFCFA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFEDE5E1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: kWine,
                            width: 1.2,
                          ),
                        ),
                      ),
                      hint: const Text('팀원을 선택하세요'),
                      items: members.map((member) {
                        return DropdownMenuItem<String>(
                          value: member.name,
                          child: Text(member.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setInnerState(() {
                          selectedMemberName = value;
                          if (value != null) {
                            memberInputController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _DialogField(
                      controller: memberInputController,
                      label: '또는 새 팀원 이름 입력',
                      hintText: '기존 팀원에 없으면 직접 입력',
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: const BorderSide(color: Color(0xFFE4D9D4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              '취소',
                              style: TextStyle(
                                color: kSub,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final title = titleController.text.trim();
                              final inputMemberName =
                                  memberInputController.text.trim();

                              if (title.isEmpty) {
                                _showErrorSnackBar('역할 이름을 입력해주세요.');
                                return;
                              }

                              if ((selectedMemberName == null ||
                                      selectedMemberName!.isEmpty) &&
                                  inputMemberName.isEmpty) {
                                _showErrorSnackBar(
                                  '팀원을 선택하거나 새 팀원 이름을 입력해주세요.',
                                );
                                return;
                              }

                              Navigator.pop(context);

                              await _createRoleSmart(
                                title: title,
                                selectedMemberName: selectedMemberName,
                                inputMemberName: inputMemberName,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kWine,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              '추가',
                              style: TextStyle(fontWeight: FontWeight.w800),
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
      },
    );
  }

  Future<void> showAddTaskDialog(int roleIndex) async {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '업무 추가',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DialogField(
                      controller: titleController,
                      label: '업무 내용',
                      hintText: '예: 발표 대본 초안 작성',
                    ),
                    const SizedBox(height: 14),
                    _DateSelectField(
                      label: '마감기한',
                      text: formatDate(selectedDate),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setInnerState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final title = titleController.text.trim();
                              if (title.isEmpty) return;

                              final role = roles[roleIndex];

                              try {
                                await widget.service.createTask(
                                  projectNumber: project.projectNumber,
                                  roleId: role.id,
                                  title: title,
                                  dueDate: selectedDate,
                                  priority: '보통',
                                  source: '수동',
                                );
                                if (!mounted) return;
                                Navigator.pop(context);
                                await _reloadProject();
                                _showSuccessSnackBar('업무를 추가했어요.');
                              } on UnsupportedError {
                                final updatedRoles = [...roles];
                                final updatedTasks = [...role.tasks];
                                updatedTasks.add(
                                  TaskModel(
                                    id: _nextTaskId(),
                                    title: title,
                                    priority: '보통',
                                    dueDate: selectedDate,
                                    done: false,
                                    source: '수동',
                                  ),
                                );
                                updatedRoles[roleIndex] =
                                    role.copyWith(tasks: updatedTasks);
                                if (!mounted) return;
                                setState(() {
                                  project =
                                      project.copyWith(roles: updatedRoles);
                                  _refreshAllRoleStatuses();
                                });
                                Navigator.pop(context);
                                _showSuccessSnackBar('업무를 추가했어요.');
                              } catch (e) {
                                _showErrorSnackBar('업무 추가에 실패했어요.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kWine,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('추가'),
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
      },
    );
  }

  Future<void> showEditTaskDeadlineDialog(int roleIndex, int taskIndex) async {
    DateTime selectedDate = roles[roleIndex].tasks[taskIndex].dueDate;
    final role = roles[roleIndex];
    final task = role.tasks[taskIndex];

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '마감기한 수정',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kSub,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DateSelectField(
                      label: '마감기한',
                      text: formatDate(selectedDate),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setInnerState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await widget.service.updateTask(
                                  projectNumber: project.projectNumber,
                                  roleId: role.id,
                                  taskId: task.id,
                                  dueDate: selectedDate,
                                  done: task.done,
                                );
                                if (!mounted) return;
                                Navigator.pop(context);
                                await _reloadProject();
                                _showSuccessSnackBar('마감기한을 수정했어요.');
                              } on UnsupportedError {
                                final updatedRoles = [...roles];
                                final updatedTasks = [...role.tasks];
                                updatedTasks[taskIndex] =
                                    task.copyWith(dueDate: selectedDate);
                                updatedRoles[roleIndex] =
                                    role.copyWith(tasks: updatedTasks);
                                if (!mounted) return;
                                setState(() {
                                  project =
                                      project.copyWith(roles: updatedRoles);
                                  _refreshAllRoleStatuses();
                                });
                                Navigator.pop(context);
                                _showSuccessSnackBar('마감기한을 수정했어요.');
                              } catch (e) {
                                _showErrorSnackBar('마감기한 수정에 실패했어요.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kWine,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('저장'),
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
      },
    );
  }

  Future<void> autoGenerateTasks(int roleIndex) async {
    final role = roles[roleIndex];
    final generated = _aiRecommendedTasks(role.title);

    try {
      for (final task in generated) {
        await widget.service.createTask(
          projectNumber: project.projectNumber,
          roleId: role.id,
          title: task.title,
          dueDate: task.dueDate,
          priority: task.priority,
          source: task.source,
        );
      }
      await _reloadProject();
      _showSuccessSnackBar('AI 추천 업무를 추가했어요.');
    } on UnsupportedError {
      final updatedRoles = [...roles];
      final updatedTasks = [...role.tasks];
      updatedTasks.addAll(
        generated.map((task) => task.copyWith(id: _nextTaskId())),
      );
      updatedRoles[roleIndex] = role.copyWith(tasks: updatedTasks);

      if (!mounted) return;
      setState(() {
        project = project.copyWith(roles: updatedRoles);
        _refreshAllRoleStatuses();
      });
      _showSuccessSnackBar('AI 추천 업무를 추가했어요.');
    } catch (e) {
      _showErrorSnackBar('AI 자동생성에 실패했어요.');
    }
  }

  List<TaskModel> _aiRecommendedTasks(String roleTitle) {
    final now = DateTime.now();

    if (roleTitle.contains('자료')) {
      return [
        TaskModel(
          id: 0,
          title: '참고자료 찾기',
          priority: '높음',
          dueDate: now.add(const Duration(days: 1)),
          done: false,
          source: 'AI',
        ),
        TaskModel(
          id: 0,
          title: '논문 요약',
          priority: '보통',
          dueDate: now.add(const Duration(days: 2)),
          done: false,
          source: 'AI',
        ),
        TaskModel(
          id: 0,
          title: '출처 정리',
          priority: '보통',
          dueDate: now.add(const Duration(days: 3)),
          done: false,
          source: 'AI',
        ),
      ];
    }

    if (roleTitle.contains('발표 자료')) {
      return [
        TaskModel(
          id: 0,
          title: '슬라이드 초안 작성',
          priority: '높음',
          dueDate: now.add(const Duration(days: 1)),
          done: false,
          source: 'AI',
        ),
        TaskModel(
          id: 0,
          title: '디자인 정리',
          priority: '높음',
          dueDate: now.add(const Duration(days: 2)),
          done: false,
          source: 'AI',
        ),
        TaskModel(
          id: 0,
          title: '최종 수정 반영',
          priority: '보통',
          dueDate: now.add(const Duration(days: 3)),
          done: false,
          source: 'AI',
        ),
      ];
    }

    if (roleTitle.contains('발표')) {
      return [
        TaskModel(
          id: 0,
          title: '발표 대본 준비',
          priority: '높음',
          dueDate: now.add(const Duration(days: 1)),
          done: false,
          source: 'AI',
        ),
        TaskModel(
          id: 0,
          title: '1차 리허설',
          priority: '높음',
          dueDate: now.add(const Duration(days: 2)),
          done: false,
          source: 'AI',
        ),
        TaskModel(
          id: 0,
          title: '예상 질문 정리',
          priority: '보통',
          dueDate: now.add(const Duration(days: 3)),
          done: false,
          source: 'AI',
        ),
      ];
    }

    return [
      TaskModel(
        id: 0,
        title: '$roleTitle 관련 초안 작성',
        priority: '보통',
        dueDate: now.add(const Duration(days: 1)),
        done: false,
        source: 'AI',
      ),
      TaskModel(
        id: 0,
        title: '$roleTitle 관련 검토',
        priority: '보통',
        dueDate: now.add(const Duration(days: 2)),
        done: false,
        source: 'AI',
      ),
    ];
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> _requestPhotosPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }
    return true;
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final hasPermission = await _requestPhotosPermission();
      if (!hasPermission) {
        _showErrorSnackBar('사진 접근 권한이 필요해요.');
        return;
      }

      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) return;

      final fileName =
          picked.name.isNotEmpty ? picked.name : picked.path.split('/').last;

      await _sendAttachmentMessage('$fileName\n사진을 업로드했습니다.');
    } catch (e) {
      _showErrorSnackBar('사진 보관함에서 파일을 불러오지 못했어요.');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        _showErrorSnackBar('카메라 권한이 필요해요.');
        return;
      }

      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (picked == null) return;

      final fileName =
          picked.name.isNotEmpty ? picked.name : picked.path.split('/').last;

      await _sendAttachmentMessage('$fileName\n사진을 촬영해 업로드했습니다.');
    } catch (e) {
      _showErrorSnackBar('카메라 촬영에 실패했어요.');
    }
  }

  Future<void> _pickFileFromDevice() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final fileName = file.name;

      await _sendAttachmentMessage('$fileName\n파일을 업로드했습니다.');
    } catch (e) {
      _showErrorSnackBar('파일을 불러오지 못했어요.');
    }
  }

  void showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFCFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '첨부 방식 선택',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _AttachOptionTile(
                icon: Icons.photo_library_outlined,
                title: '사진 보관함',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromGallery();
                },
              ),
              _AttachOptionTile(
                icon: Icons.camera_alt_outlined,
                title: '카메라',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromCamera();
                },
              ),
              _AttachOptionTile(
                icon: Icons.insert_drive_file_outlined,
                title: '파일',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFileFromDevice();
                },
              ),
              _AttachOptionTile(
                icon: Icons.link_outlined,
                title: '링크',
                onTap: () async {
                  Navigator.pop(context);
                  await _sendAttachmentMessage(
                    'https://example.com\n링크를 공유했습니다.',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showUrgentTasksSheet() {
    final items = urgentTasks;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFCFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '마감 임박 업무',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: kText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD4B2)),
                ),
                child: Text(
                  items.isEmpty
                      ? '현재 마감 임박 또는 지연 업무가 없습니다.'
                      : '확인이 필요한 업무 ${items.length}개가 있습니다.',
                  style: const TextStyle(
                    color: kOrange,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          '표시할 업무가 없습니다.',
                          style: TextStyle(
                            color: kSub,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = items[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: task.isOverdue
                                    ? const Color(0xFFFFB6A1)
                                    : const Color(0xFFFFC49E),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: kOrange,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: const TextStyle(
                                          color: kText,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '담당자: ${task.assignee}',
                                        style: const TextStyle(
                                          color: kSub,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        task.isOverdue ? '기한 지남' : '마감 임박',
                                        style: const TextStyle(
                                          color: kOrange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      task.priority,
                                      style: const TextStyle(
                                        color: kOrange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatDate(task.dueDate),
                                      style: const TextStyle(
                                        color: kSub,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showNotificationSheet() async {
    await _markAllNotificationsAsRead();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.62,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '알림',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: kText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: notifications.isEmpty
                    ? const Center(
                        child: Text(
                          '표시할 알림이 없어요.',
                          style: TextStyle(
                            color: kSub,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item.isRead
                                  ? const Color(0xFFF8F3F0)
                                  : const Color(0xFFFFF3EE),
                              borderRadius: BorderRadius.circular(18),
                              border: item.isRead
                                  ? null
                                  : Border.all(color: const Color(0xFFFFD6C7)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  item.type == 'task'
                                      ? Icons.task_alt_rounded
                                      : Icons.chat_bubble_outline_rounded,
                                  color: item.type == 'task' ? kGreen : kWine,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: kText,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.body,
                                        style: const TextStyle(
                                          color: kSub,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showFileOnlySheet() {
    final files = fileMessages;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.68,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '공유된 파일',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: kText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: files.isEmpty
                    ? const Center(
                        child: Text(
                          '공유된 파일이 없어요.',
                          style: TextStyle(
                            color: kSub,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: files.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final file = files[index];
                          final firstLine = file.message.split('\n').first;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F3F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: fileTypeColor(
                                      file.message,
                                    ).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    fileTypeIcon(file.message),
                                    color: fileTypeColor(file.message),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fileTypeLabel(file.message),
                                        style: TextStyle(
                                          color: fileTypeColor(file.message),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        firstLine,
                                        style: const TextStyle(
                                          color: kText,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        file.time,
                                        style: const TextStyle(
                                          color: kSub,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTabContent() {
    switch (selectedTabIndex) {
      case 0:
        return RefreshIndicator(
          onRefresh: _reloadProject,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            child: _OverviewTab(
              members: members,
              schedules: schedules,
              summaryStatus: summaryStatus,
              urgentTaskCount: urgentTaskCount,
              overdueTaskCount: overdueTaskCount,
              onAddMember: showAddMemberSheet,
              onAddSchedule: showAddScheduleSheet,
              onEditMember: showEditMemberSheet,
              onDeleteMember: deleteMember,
              onEditSchedule: showEditScheduleSheet,
              onDeleteSchedule: deleteSchedule,
            ),
          ),
        );
      case 1:
        return RefreshIndicator(
          onRefresh: _reloadProject,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            child: _RolesTab(
              roles: roles,
              members: members, // 👈 추가
              expandedRoleIndex: expandedRoleIndex,
              onRoleTap: (index) {
                setState(() {
                  expandedRoleIndex = expandedRoleIndex == index ? null : index;
                });
              },
              onAddRole: showAddRoleSmartSheet,
              onTaskToggle: toggleTask,
              onAddTask: showAddTaskDialog,
              onEditDeadline: showEditTaskDeadlineDialog,
              onAutoGenerate: autoGenerateTasks,
              onDeleteTask: deleteTask,
              statusColor: statusColor,
              completedTaskCount: completedTaskCount,
              totalTaskCount: totalTaskCount,
              isDueTomorrow: isDueTomorrow,
              isOverdue: isOverdue,
            ),
          ),
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
          child: _ChatTab(
            messages: chatMessages,
            controller: chatController,
            focusNode: chatFocusNode,
            scrollController: chatScrollController,
            onAttachTap: showAttachmentOptions,
            onSendTap: sendChatMessage,
            onFileOnlyTap: showFileOnlySheet,
            isSending: _isSendingChat,
          ),
        );
      case 3:
        return RefreshIndicator(
          onRefresh: _reloadProject,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            child: _StatusTab(
              roles: roles,
              summaryStatus: summaryStatus,
              urgentTaskCount: urgentTaskCount,
              overdueTaskCount: overdueTaskCount,
              statusColor: statusColor,
              completedTaskCount: completedTaskCount,
              totalTaskCount: totalTaskCount,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: kCream,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _HeaderSection(
                projectTitle: project.projectTitle,
                summaryStatus: summaryStatus,
                onBack: () => Navigator.pop(context),
                onBellTap: showNotificationSheet,
                statusColor: statusColor(summaryStatus),
                onStatusTap: showUrgentTasksSheet,
                unreadNotificationCount: unreadNotificationCount,
              ),
              _TopTabBar(
                selectedIndex: selectedTabIndex,
                unreadChatCount: unreadChatCount,
                onChanged: (index) async {
                  setState(() {
                    selectedTabIndex = index;
                  });
                  if (index == 2) {
                    await _markAllChatAsRead();
                  }
                },
              ),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorText != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 52,
                            color: kSub,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '프로젝트 정보를 불러오지 못했어요.',
                            style: TextStyle(
                              color: kText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kSub,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadProjectDetail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kWine,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(child: buildTabContent()),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String projectTitle;
  final String summaryStatus;
  final VoidCallback onBack;
  final VoidCallback onBellTap;
  final VoidCallback onStatusTap;
  final Color statusColor;
  final int unreadNotificationCount;

  const _HeaderSection({
    required this.projectTitle,
    required this.summaryStatus,
    required this.onBack,
    required this.onBellTap,
    required this.onStatusTap,
    required this.statusColor,
    required this.unreadNotificationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      color: _ProjectDetailScreenState.kCream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _ProjectDetailScreenState.kSub,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '프로젝트 목록으로',
                      style: TextStyle(
                        color: _ProjectDetailScreenState.kSub,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onBellTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDE4E1)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: _ProjectDetailScreenState.kSub,
                          size: 22,
                        ),
                      ),
                      if (unreadNotificationCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            decoration: BoxDecoration(
                              color: _ProjectDetailScreenState.kWine,
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: Colors.white, width: 1.2),
                            ),
                            child: Text(
                              unreadNotificationCount > 9
                                  ? '9+'
                                  : '$unreadNotificationCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE9DFDB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectTitle,
                  style: const TextStyle(
                    color: _ProjectDetailScreenState.kText,
                    fontSize: 30,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: onStatusTap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2F1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: _ProjectDetailScreenState.kWine,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          summaryStatus,
                          style: const TextStyle(
                            color: _ProjectDetailScreenState.kWine,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTabBar extends StatelessWidget {
  final int selectedIndex;
  final int unreadChatCount;
  final ValueChanged<int> onChanged;

  const _TopTabBar({
    required this.selectedIndex,
    required this.unreadChatCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.info_outline, '개요'),
      (Icons.group_outlined, '역할'),
      (Icons.chat_bubble_outline, '채팅'),
      (Icons.bar_chart_outlined, '현황'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4F1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEE4E0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(tabs.length, (index) {
            final selected = selectedIndex == index;
            final item = tabs[index];
            final isChatTab = index == 2;

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                  decoration: BoxDecoration(
                    color: selected
                        ? _ProjectDetailScreenState.kWine
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: selected
                        ? Border.all(color: _ProjectDetailScreenState.kWine)
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            item.$1,
                            size: 18,
                            color: selected
                                ? Colors.white
                                : _ProjectDetailScreenState.kSub,
                          ),
                          if (isChatTab && unreadChatCount > 0)
                            Positioned(
                              right: -10,
                              top: -8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: _ProjectDetailScreenState.kWine,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  unreadChatCount > 9
                                      ? '9+'
                                      : '$unreadChatCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.$2,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : _ProjectDetailScreenState.kSub,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final List<MemberModel> members;
  final List<ScheduleModel> schedules;
  final String summaryStatus;
  final int urgentTaskCount;
  final int overdueTaskCount;
  final VoidCallback onAddMember;
  final VoidCallback onAddSchedule;
  final void Function(MemberModel member, int index) onEditMember;
  final void Function(int index) onDeleteMember;
  final void Function(ScheduleModel schedule, int index) onEditSchedule;
  final void Function(int index) onDeleteSchedule;

  const _OverviewTab({
    required this.members,
    required this.schedules,
    required this.summaryStatus,
    required this.urgentTaskCount,
    required this.overdueTaskCount,
    required this.onAddMember,
    required this.onAddSchedule,
    required this.onEditMember,
    required this.onDeleteMember,
    required this.onEditSchedule,
    required this.onDeleteSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AiCoachCard(
          summaryStatus: summaryStatus,
          urgentTaskCount: urgentTaskCount,
          overdueTaskCount: overdueTaskCount,
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '팀원',
          icon: Icons.group_outlined,
          buttonText: '+ 추가',
          onButtonTap: onAddMember,
          child: Column(
            children: List.generate(members.length, (index) {
              final member = members[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Slidable(
                  key: ValueKey('member_${member.id}'),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.42,
                    children: [
                      SlidableAction(
                        onPressed: (_) => onEditMember(member, index),
                        backgroundColor: const Color(0xFFB65AE1),
                        foregroundColor: Colors.white,
                        icon: Icons.edit_rounded,
                        label: '수정',
                        borderRadius: BorderRadius.circular(18),
                      ),
                      SlidableAction(
                        onPressed: (_) => onDeleteMember(index),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete_rounded,
                        label: '삭제',
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ],
                  ),
                  child: _SimpleListTile(
                    title: member.name,
                    subtitle: member.studentId,
                    leadingText: member.name.isNotEmpty
                        ? member.name.characters.first
                        : '?',
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '일정',
          icon: Icons.calendar_today_outlined,
          buttonText: '+ 추가',
          onButtonTap: onAddSchedule,
          child: Column(
            children: List.generate(schedules.length, (index) {
              final schedule = schedules[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Slidable(
                  key: ValueKey('schedule_${schedule.id}'),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.42,
                    children: [
                      SlidableAction(
                        onPressed: (_) => onEditSchedule(schedule, index),
                        backgroundColor: const Color(0xFFB65AE1),
                        foregroundColor: Colors.white,
                        icon: Icons.edit_rounded,
                        label: '수정',
                        borderRadius: BorderRadius.circular(18),
                      ),
                      SlidableAction(
                        onPressed: (_) => onDeleteSchedule(index),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete_rounded,
                        label: '삭제',
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ],
                  ),
                  child: _SimpleListTile(
                    title: schedule.title,
                    subtitle:
                        '${formatDate(schedule.date)} · ${formatTimeOfDay(schedule.startTime)} - ${formatTimeOfDay(schedule.endTime)}',
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _RolesTab extends StatelessWidget {
  final List<RoleModel> roles;
  final List<MemberModel> members;
  final int? expandedRoleIndex;
  final void Function(int) onRoleTap;
  final VoidCallback onAddRole;
  final Future<void> Function(int, int) onTaskToggle;
  final Future<void> Function(int) onAddTask;
  final Future<void> Function(int, int) onEditDeadline;
  final Future<void> Function(int) onAutoGenerate;
  final Future<void> Function(int, int) onDeleteTask;
  final Color Function(String) statusColor;
  final int Function(RoleModel) completedTaskCount;
  final int Function(RoleModel) totalTaskCount;
  final bool Function(TaskModel) isDueTomorrow;
  final bool Function(TaskModel) isOverdue;

  const _RolesTab({
    required this.roles,
    required this.members,
    required this.expandedRoleIndex,
    required this.onRoleTap,
    required this.onAddRole,
    required this.onTaskToggle,
    required this.onAddTask,
    required this.onEditDeadline,
    required this.onAutoGenerate,
    required this.onDeleteTask,
    required this.statusColor,
    required this.completedTaskCount,
    required this.totalTaskCount,
    required this.isDueTomorrow,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '역할 분담',
                style: TextStyle(
                  color: _ProjectDetailScreenState.kText,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            InkWell(
              onTap: onAddRole,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECE3DF)),
                ),
                child: const Text(
                  '+ 역할 추가',
                  style: TextStyle(
                    color: _ProjectDetailScreenState.kText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '누가 어떤 업무를 맡았는지 한눈에 보고, 업무를 추가하거나 수정할 수 있어요',
          style: TextStyle(
            color: _ProjectDetailScreenState.kSub,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(members.length, (index) {
          final member = members[index];

          // 👇 해당 멤버의 role 찾기
          final role = roles.where((r) => r.assignee == member.name).isNotEmpty
              ? roles.firstWhere((r) => r.assignee == member.name)
              : RoleModel(
                  id: -1,
                  title: '역할 미정',
                  assignee: member.name,
                  status: '시작 전',
                  tasks: [],
                );

          final expanded = expandedRoleIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _ProjectDetailScreenState.kCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEBE2DE)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => onRoleTap(index),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Text(
                                        role.title,
                                        style: const TextStyle(
                                          color:
                                              _ProjectDetailScreenState.kText,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: _ProjectDetailScreenState.kSub,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(
                                        role.assignee,
                                        style: const TextStyle(
                                          color: _ProjectDetailScreenState.kSub,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    role.title == '역할 미정'
                                        ? '아직 역할이 정해지지 않았어요'
                                        : '${role.assignee} 담당 역할',
                                    style: const TextStyle(
                                      color: _ProjectDetailScreenState.kSub,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    statusColor(role.status).withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    role.status == '지연'
                                        ? Icons.error_outline
                                        : Icons.schedule_outlined,
                                    size: 16,
                                    color: statusColor(role.status),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    role.status,
                                    style: TextStyle(
                                      color: statusColor(role.status),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F4F1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '업무 ${completedTaskCount(role)}/${totalTaskCount(role)} 완료',
                                style: const TextStyle(
                                  color: _ProjectDetailScreenState.kSub,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: expanded
                                    ? _ProjectDetailScreenState.kWine
                                        .withOpacity(0.10)
                                    : const Color(0xFFF7F1EE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                expanded ? '업무 접기' : '업무 보기',
                                style: TextStyle(
                                  color: expanded
                                      ? _ProjectDetailScreenState.kWine
                                      : _ProjectDetailScreenState.kSub,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: const Color(0xFFF0E8E4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          role.title == '역할 미정'
                              ? '${role.assignee}의 예정 업무'
                              : '${role.assignee}의 업무 리스트',
                          style: const TextStyle(
                            color: _ProjectDetailScreenState.kText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => onAddTask(index),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            side: const BorderSide(color: Color(0xFFE4D9D4)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '+ 수동 추가',
                            style: TextStyle(
                              color: _ProjectDetailScreenState.kSub,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => onAutoGenerate(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ProjectDetailScreenState.kWine,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'AI 자동생성',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (role.tasks.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F3F0),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '${role.assignee}에게 아직 배정된 업무가 없습니다. 수동으로 추가하거나 AI 자동생성을 눌러보세요.',
                          style: const TextStyle(
                            color: _ProjectDetailScreenState.kSub,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      ...List.generate(role.tasks.length, (taskIndex) {
                        final task = role.tasks[taskIndex];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Dismissible(
                            key: ValueKey('${role.id}_${task.id}_$taskIndex'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('업무 삭제'),
                                        content: const Text('이 업무를 삭제할까요?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('취소'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('삭제'),
                                          ),
                                        ],
                                      );
                                    },
                                  ) ??
                                  false;
                            },
                            onDismissed: (_) => onDeleteTask(index, taskIndex),
                            child: _TaskTile(
                              task: task,
                              onTap: () => onTaskToggle(index, taskIndex),
                              onEditDeadline: () =>
                                  onEditDeadline(index, taskIndex),
                              isDueTomorrow: isDueTomorrow(task),
                              isOverdue: isOverdue(task),
                            ),
                          ),
                        );
                      }),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ChatTab extends StatelessWidget {
  final List<ChatMessageModel> messages;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final VoidCallback onAttachTap;
  final Future<void> Function() onSendTap;
  final VoidCallback onFileOnlyTap;
  final bool isSending;

  const _ChatTab({
    required this.messages,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.onAttachTap,
    required this.onSendTap,
    required this.onFileOnlyTap,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '진행상황 공유',
                  style: TextStyle(
                    color: _ProjectDetailScreenState.kText,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: onFileOnlyTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECE8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEE5E1)),
                  ),
                  child: const Icon(
                    Icons.folder_open_rounded,
                    color: _ProjectDetailScreenState.kWine,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '작업 내용과 파일을 공유하세요',
            style: TextStyle(
              color: _ProjectDetailScreenState.kSub,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCFB),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFEDE1DF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: NotificationListener<ScrollUpdateNotification>(
                      onNotification: (_) {
                        FocusScope.of(context).unfocus();
                        return false;
                      },
                      child: ListView.builder(
                        controller: scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final showDateDivider = _shouldShowDateDivider(
                            messages,
                            index,
                          );

                          return Column(
                            children: [
                              if (showDateDivider)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: _ChatDateDivider(text: '오늘'),
                                ),
                              _ChatBubble(message: message),
                              const SizedBox(height: 10),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      10,
                      12,
                      bottomInset > 0 ? 10 : 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFF0E8E4))),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: onAttachTap,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F0EC),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: _ProjectDetailScreenState.kSub,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: 46,
                                maxHeight: 120,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F3F0),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: focusNode.hasFocus
                                      ? _ProjectDetailScreenState.kWine
                                          .withOpacity(0.28)
                                      : const Color(0xFFE8DFDA),
                                ),
                              ),
                              child: TextField(
                                controller: controller,
                                focusNode: focusNode,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  hintText: '메시지를 입력하세요',
                                  hintStyle: TextStyle(
                                    color: _ProjectDetailScreenState.kSub,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onTapOutside: (_) =>
                                    FocusScope.of(context).unfocus(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: isSending ? null : onSendTap,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSending
                                    ? _ProjectDetailScreenState.kWine
                                        .withOpacity(0.5)
                                    : _ProjectDetailScreenState.kWine,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: isSending
                                  ? const Padding(
                                      padding: EdgeInsets.all(11),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateDivider(List<ChatMessageModel> messages, int index) {
    return index == 0;
  }
}

class _StatusTab extends StatelessWidget {
  final List<RoleModel> roles;
  final String summaryStatus;
  final int urgentTaskCount;
  final int overdueTaskCount;
  final Color Function(String) statusColor;
  final int Function(RoleModel) completedTaskCount;
  final int Function(RoleModel) totalTaskCount;

  const _StatusTab({
    required this.roles,
    required this.summaryStatus,
    required this.urgentTaskCount,
    required this.overdueTaskCount,
    required this.statusColor,
    required this.completedTaskCount,
    required this.totalTaskCount,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = roles.where((role) => role.status == '완료').length;
    final delayedCount = roles.where((role) => role.status == '지연').length;
    final workingCount = roles.where((role) => role.status == '진행 중').length;
    final urgentCount = roles.where((role) => role.status == '마감 임박').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AiCoachCard(
          summaryStatus: summaryStatus,
          urgentTaskCount: urgentTaskCount,
          overdueTaskCount: overdueTaskCount,
        ),
        const SizedBox(height: 16),
        const Text(
          '진행 현황',
          style: TextStyle(
            color: _ProjectDetailScreenState.kText,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '각 역할별 진행 상태를 확인하세요',
          style: TextStyle(
            color: _ProjectDetailScreenState.kSub,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _ProjectDetailScreenState.kCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEBE2DE)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _StatusCountRow(title: '진행 중 역할', value: '$workingCount개'),
              const SizedBox(height: 10),
              _StatusCountRow(title: '마감 임박 역할', value: '$urgentCount개'),
              const SizedBox(height: 10),
              _StatusCountRow(title: '지연 역할', value: '$delayedCount개'),
              const SizedBox(height: 10),
              _StatusCountRow(title: '완료 역할', value: '$completedCount개'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...roles.map((role) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _ProjectDetailScreenState.kCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFEBE2DE)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.title,
                          style: const TextStyle(
                            color: _ProjectDetailScreenState.kText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          role.assignee,
                          style: const TextStyle(
                            color: _ProjectDetailScreenState.kSub,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '업무 ${completedTaskCount(role)}/${totalTaskCount(role)} 완료',
                          style: const TextStyle(
                            color: _ProjectDetailScreenState.kSub,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor(role.status).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      role.status,
                      style: TextStyle(
                        color: statusColor(role.status),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AiCoachCard extends StatelessWidget {
  final String summaryStatus;
  final int urgentTaskCount;
  final int overdueTaskCount;

  const _AiCoachCard({
    required this.summaryStatus,
    required this.urgentTaskCount,
    required this.overdueTaskCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEE6F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFEEDDF8),
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: _ProjectDetailScreenState.kPurple,
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'AI 코치 분석',
                style: TextStyle(
                  color: Color(0xFF5A2B7A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AiHintBox(
            backgroundColor: const Color(0xFFEFF4FF),
            textColor: _ProjectDetailScreenState.kBlue,
            text: '현재 상태: $summaryStatus',
          ),
          if (overdueTaskCount > 0) ...[
            const SizedBox(height: 10),
            _AiHintBox(
              backgroundColor: const Color(0xFFFFEDE8),
              textColor: _ProjectDetailScreenState.kOrange,
              text: '기한이 지난 미완료 업무가 $overdueTaskCount개 있어요. 가장 먼저 확인하세요.',
            ),
          ],
          if (urgentTaskCount > 0) ...[
            const SizedBox(height: 10),
            _AiHintBox(
              backgroundColor: _ProjectDetailScreenState.kRedSoft,
              textColor: _ProjectDetailScreenState.kOrange,
              text: '마감 하루 전인데 아직 완료되지 않은 업무가 $urgentTaskCount개 있어요.',
            ),
          ],
          if (urgentTaskCount == 0 && overdueTaskCount == 0) ...[
            const SizedBox(height: 10),
            const _AiHintBox(
              backgroundColor: Color(0xFFEFFAEA),
              textColor: _ProjectDetailScreenState.kGreen,
              text: '현재 급한 마감 경고는 없어요. 지금 흐름을 유지하면 됩니다.',
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String buttonText;
  final VoidCallback onButtonTap;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.buttonText,
    required this.onButtonTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ProjectDetailScreenState.kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBE2DE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: _ProjectDetailScreenState.kText, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _ProjectDetailScreenState.kText,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onButtonTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4F1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFECE3DF)),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: _ProjectDetailScreenState.kText,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SimpleListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? leadingText;

  const _SimpleListTile({
    required this.title,
    required this.subtitle,
    this.leadingText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEE5E1)),
      ),
      child: Row(
        children: [
          if (leadingText != null)
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF3ECE8),
                shape: BoxShape.circle,
              ),
              child: Text(
                leadingText!,
                style: const TextStyle(
                  color: _ProjectDetailScreenState.kText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (leadingText != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ProjectDetailScreenState.kText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _ProjectDetailScreenState.kSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onEditDeadline;
  final bool isDueTomorrow;
  final bool isOverdue;

  const _TaskTile({
    required this.task,
    required this.onTap,
    required this.onEditDeadline,
    required this.isDueTomorrow,
    required this.isOverdue,
  });

  Color priorityColor(String priority) {
    if (priority == '높음') return _ProjectDetailScreenState.kOrange;
    return _ProjectDetailScreenState.kWine;
  }

  @override
  Widget build(BuildContext context) {
    final hasAlert = isDueTomorrow || isOverdue;

    return Container(
      decoration: BoxDecoration(
        color: hasAlert ? const Color(0xFFFFF5F1) : const Color(0xFFFBF7F4),
        borderRadius: BorderRadius.circular(18),
        border: hasAlert
            ? Border.all(color: const Color(0xFFFFDDD1))
            : Border.all(color: const Color(0xFFEEE5E1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                task.done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: task.done
                    ? _ProjectDetailScreenState.kGreen
                    : _ProjectDetailScreenState.kSub,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              color: _ProjectDetailScreenState.kText,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              decoration:
                                  task.done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (task.source == 'AI')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2E6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                color: Color(0xFF7B3CB0),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          task.priority,
                          style: TextStyle(
                            color: priorityColor(task.priority),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        GestureDetector(
                          onTap: onEditDeadline,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatDate(task.dueDate),
                                style: const TextStyle(
                                  color: _ProjectDetailScreenState.kSub,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.edit_calendar_outlined,
                                size: 14,
                                color: _ProjectDetailScreenState.kSub,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isOverdue) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '기한이 지났는데 아직 완료되지 않았어요',
                        style: TextStyle(
                          color: _ProjectDetailScreenState.kOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ] else if (isDueTomorrow) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '마감 하루 전인데 아직 완료되지 않았어요',
                        style: TextStyle(
                          color: _ProjectDetailScreenState.kOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    const Text(
                      '왼쪽으로 밀어서 삭제',
                      style: TextStyle(
                        color: _ProjectDetailScreenState.kSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isMine = message.sender == '나';
    final bool isAi = message.isAi;

    final Color bubbleColor = isMine
        ? _ProjectDetailScreenState.kWine
        : (isAi ? const Color(0xFFF7F1FF) : const Color(0xFFFFFCFB));

    final Color textColor =
        isMine ? Colors.white : _ProjectDetailScreenState.kText;

    final BorderRadius bubbleRadius = isMine
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          );

    return Row(
      mainAxisAlignment:
          isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMine) ...[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isAi ? const Color(0xFFE9D8FF) : const Color(0xFFF1E8E5),
              shape: BoxShape.circle,
            ),
            child: Text(
              isAi
                  ? 'AI'
                  : (message.sender.isNotEmpty ? message.sender[0] : '?'),
              style: TextStyle(
                color: isAi
                    ? const Color(0xFF7B3CB0)
                    : _ProjectDetailScreenState.kText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.sender,
                        style: TextStyle(
                          color: isAi
                              ? const Color(0xFF7B3CB0)
                              : _ProjectDetailScreenState.kSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!message.isRead && message.sender != '나') ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment:
                    isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isMine)
                    Padding(
                      padding: const EdgeInsets.only(right: 6, bottom: 2),
                      child: Text(
                        message.time,
                        style: const TextStyle(
                          color: _ProjectDetailScreenState.kSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: bubbleRadius,
                        border: Border.all(
                          color: isMine
                              ? _ProjectDetailScreenState.kWine
                                  .withOpacity(0.15)
                              : (isAi
                                  ? const Color(0xFFE3D2FF)
                                  : const Color(0xFFEAE1DC)),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.roleTag.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? Colors.white.withOpacity(0.16)
                                    : const Color(0xFFF6F0EC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                message.roleTag,
                                style: TextStyle(
                                  color: isMine
                                      ? Colors.white
                                      : _ProjectDetailScreenState.kSub,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                          if (message.isFile) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.insert_drive_file_rounded,
                                  size: 18,
                                  color: isMine
                                      ? Colors.white
                                      : _ProjectDetailScreenState.kText,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    message.message,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Text(
                              message.message,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.42,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!isMine)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 2),
                      child: Text(
                        message.time,
                        style: const TextStyle(
                          color: _ProjectDetailScreenState.kSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AiHintBox extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final String text;

  const _AiHintBox({
    required this.backgroundColor,
    required this.textColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusCountRow extends StatelessWidget {
  final String title;
  final String value;

  const _StatusCountRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ProjectDetailScreenState.kSub,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: _ProjectDetailScreenState.kText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _ProjectDetailScreenState.kSub,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFB3AAA6),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFFEFCFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEDE5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: _ProjectDetailScreenState.kWine,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateSelectField extends StatelessWidget {
  final String label;
  final String text;
  final VoidCallback onTap;

  const _DateSelectField({
    required this.label,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _ProjectDetailScreenState.kSub,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DFDA)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: _ProjectDetailScreenState.kText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: _ProjectDetailScreenState.kSub,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeSelectField extends StatelessWidget {
  final String label;
  final String text;
  final VoidCallback onTap;

  const _TimeSelectField({
    required this.label,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _ProjectDetailScreenState.kSub,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DFDA)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: _ProjectDetailScreenState.kText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.schedule_outlined,
                  size: 18,
                  color: _ProjectDetailScreenState.kSub,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Future<void> Function() onTap;

  const _AttachOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4F1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEE5E1)),
        ),
        child: Icon(icon, color: _ProjectDetailScreenState.kWine),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: _ProjectDetailScreenState.kText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFE5DAD7),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _ChatDateDivider extends StatelessWidget {
  final String text;

  const _ChatDateDivider({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE8DFDA), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: const TextStyle(
              color: _ProjectDetailScreenState.kSub,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE8DFDA), thickness: 1)),
      ],
    );
  }
}

class _UrgentTaskView {
  final String title;
  final String assignee;
  final String priority;
  final DateTime dueDate;
  final bool isOverdue;

  _UrgentTaskView({
    required this.title,
    required this.assignee,
    required this.priority,
    required this.dueDate,
    required this.isOverdue,
  });
}
