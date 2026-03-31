import 'task_model.dart';

class RoleModel {
  final int id;
  final String title;
  final String assignee;
  final String status;
  final List<TaskModel> tasks;

  const RoleModel({
    required this.id,
    required this.title,
    required this.assignee,
    required this.status,
    required this.tasks,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: _toInt(json['id']),
      title: _toString(json['title']),
      assignee: _toString(json['assignee']),
      status: _toString(json['status']),
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  RoleModel copyWith({
    int? id,
    String? title,
    String? assignee,
    String? status,
    List<TaskModel>? tasks,
  }) {
    return RoleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      assignee: assignee ?? this.assignee,
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'assignee': assignee,
      'status': status,
      'tasks': tasks.map((e) => e.toJson()).toList(),
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }
}
