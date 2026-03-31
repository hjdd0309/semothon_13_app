class TaskModel {
  final int id;
  final String title;
  final String priority;
  final DateTime dueDate;
  final bool done;
  final String source;
  final String assignee;

  const TaskModel({
    required this.id,
    required this.title,
    required this.priority,
    required this.dueDate,
    required this.done,
    required this.source,
    this.assignee = '',
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: _toInt(json['id']),
      title: _toString(json['title']),
      priority: _toString(json['priority']),
      dueDate: _parseDateTime(json['dueDate'] ?? json['due_date']),
      done: _toBool(json['done']),
      source: _toString(json['source']),
      assignee: _toString(json['assignee']),
    );
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? priority,
    DateTime? dueDate,
    bool? done,
    String? source,
    String? assignee,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      done: done ?? this.done,
      source: source ?? this.source,
      assignee: assignee ?? this.assignee,
    );
  }

  bool get isOverdue {
    if (done) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'done': done,
      'source': source,
      'assignee': assignee,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
