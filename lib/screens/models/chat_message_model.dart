class ChatMessageModel {
  final int id;
  final String sender;
  final String message;
  final String time;
  final bool isMe;
  final bool isRead;
  final bool isAi;
  final bool isFile;
  final String roleTag;

  const ChatMessageModel({
    required this.id,
    required this.sender,
    required this.message,
    required this.time,
    this.isMe = false,
    this.isRead = false,
    this.isAi = false,
    this.isFile = false,
    this.roleTag = '',
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: _toInt(json['id']),
      sender: _toString(json['sender']),
      message: _toString(json['message']),
      time: _toString(json['time']),
      isMe: _toBool(json['isMe'] ?? json['is_me']),
      isRead: _toBool(json['isRead'] ?? json['is_read']),
      isAi: _toBool(json['isAi'] ?? json['is_ai']),
      isFile: _toBool(json['isFile'] ?? json['is_file']),
      roleTag: _toString(json['roleTag'] ?? json['role_tag']),
    );
  }

  ChatMessageModel copyWith({
    int? id,
    String? sender,
    String? message,
    String? time,
    bool? isMe,
    bool? isRead,
    bool? isAi,
    bool? isFile,
    String? roleTag,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      time: time ?? this.time,
      isMe: isMe ?? this.isMe,
      isRead: isRead ?? this.isRead,
      isAi: isAi ?? this.isAi,
      isFile: isFile ?? this.isFile,
      roleTag: roleTag ?? this.roleTag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'time': time,
      'isMe': isMe,
      'isRead': isRead,
      'isAi': isAi,
      'isFile': isFile,
      'roleTag': roleTag,
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
