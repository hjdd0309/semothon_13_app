import 'app_notification_model.dart';
import 'chat_message_model.dart';
import 'member_model.dart';
import 'role_model.dart';
import 'schedule_model.dart';

class ProjectDetailModel {
  final String projectNumber;
  final String projectTitle;
  final String projectGoal;
  final List<MemberModel> members;
  final List<ScheduleModel> schedules;
  final List<RoleModel> roles;
  final List<ChatMessageModel> chatMessages;
  final List<AppNotificationModel> notifications;
  final bool isMock;

  const ProjectDetailModel({
    required this.projectNumber,
    required this.projectTitle,
    required this.projectGoal,
    required this.members,
    required this.schedules,
    required this.roles,
    required this.chatMessages,
    required this.notifications,
    this.isMock = false,
  });

  factory ProjectDetailModel.fromJson(Map<String, dynamic> json) {
    return ProjectDetailModel(
      projectNumber: _toString(
        json['projectNumber'] ?? json['project_number'] ?? json['id'],
      ),
      projectTitle: _toString(
        json['projectTitle'] ?? json['project_title'] ?? json['title'],
      ),
      projectGoal: _toString(
        json['projectGoal'] ?? json['project_goal'] ?? json['description'],
      ),
      members: (json['members'] as List<dynamic>? ?? [])
          .map((e) => MemberModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      schedules: (json['schedules'] as List<dynamic>? ?? [])
          .map(
            (e) => ScheduleModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((e) => RoleModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      chatMessages: (json['chatMessages'] as List<dynamic>? ??
              json['chat_messages'] as List<dynamic>? ??
              [])
          .map(
            (e) => ChatMessageModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      notifications: (json['notifications'] as List<dynamic>? ?? [])
          .map(
            (e) => AppNotificationModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      isMock: json['isMock'] == true,
    );
  }

  ProjectDetailModel copyWith({
    String? projectNumber,
    String? projectTitle,
    String? projectGoal,
    List<MemberModel>? members,
    List<ScheduleModel>? schedules,
    List<RoleModel>? roles,
    List<ChatMessageModel>? chatMessages,
    List<AppNotificationModel>? notifications,
    bool? isMock,
  }) {
    return ProjectDetailModel(
      projectNumber: projectNumber ?? this.projectNumber,
      projectTitle: projectTitle ?? this.projectTitle,
      projectGoal: projectGoal ?? this.projectGoal,
      members: members ?? this.members,
      schedules: schedules ?? this.schedules,
      roles: roles ?? this.roles,
      chatMessages: chatMessages ?? this.chatMessages,
      notifications: notifications ?? this.notifications,
      isMock: isMock ?? this.isMock,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectNumber': projectNumber,
      'projectTitle': projectTitle,
      'projectGoal': projectGoal,
      'members': members.map((e) => e.toJson()).toList(),
      'schedules': schedules.map((e) => e.toJson()).toList(),
      'roles': roles.map((e) => e.toJson()).toList(),
      'chatMessages': chatMessages.map((e) => e.toJson()).toList(),
      'notifications': notifications.map((e) => e.toJson()).toList(),
      'isMock': isMock,
    };
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }
}
