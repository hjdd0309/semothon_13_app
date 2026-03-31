class AppNotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;

  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: _toInt(json['id']),
      type: _toString(json['type']),
      title: _toString(json['title']),
      body: _toString(json['body']),
      isRead: _toBool(json['isRead'] ?? json['is_read']),
    );
  }

  AppNotificationModel copyWith({
    int? id,
    String? type,
    String? title,
    String? body,
    bool? isRead,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'isRead': isRead,
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
}
