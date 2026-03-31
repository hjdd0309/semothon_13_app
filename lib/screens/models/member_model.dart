class MemberModel {
  final int id;
  final String name;
  final String studentId;

  const MemberModel({
    required this.id,
    required this.name,
    required this.studentId,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: _toInt(json['id'] ?? json['user_id']),
      name: _toString(
        json['name'] ?? json['display_name'] ?? json['username'],
      ),
      studentId: _toString(
        json['studentId'] ?? json['student_id'] ?? json['username'],
      ),
    );
  }

  MemberModel copyWith({
    int? id,
    String? name,
    String? studentId,
  }) {
    return MemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'studentId': studentId,
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
