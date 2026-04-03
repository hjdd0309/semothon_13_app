import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/project_detail_model.dart';
import '../models/chat_message_model.dart';

class ProjectService {
  final String baseUrl;
  final http.Client client;

  String? _accessToken;
  int? _currentUserId;

  String? get accessToken => _accessToken;
  int? get currentUserId => _currentUserId;

  ProjectService({
    required this.baseUrl,
    http.Client? client,
    String? accessToken,
  })  : client = client ?? http.Client(),
        _accessToken = accessToken;

  void setAccessToken(String token) {
    _accessToken = token;
  }

  void clearAccessToken() {
    _accessToken = null;
  }

  void setCurrentUserId(int id) {
    _currentUserId = id;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final token = _accessToken?.trim();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // =========================
  // 프로젝트
  // =========================

  Future<List<ProjectDetailModel>> fetchProjects() async {
    final response = await client.get(
      Uri.parse('$baseUrl/rooms'),
      headers: _headers,
    );

    _throwIfFailed(response, '프로젝트 목록 조회 실패');

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('프로젝트 목록 응답 형식이 올바르지 않습니다.');
    }

    return decoded.map<ProjectDetailModel>((item) {
      final map = Map<String, dynamic>.from(item as Map);

      return ProjectDetailModel.fromJson({
        'projectNumber': (map['id'] ?? '').toString(),
        'projectTitle': map['title'] ?? '',
        'projectGoal': map['description'] ?? '프로젝트 목표를 입력하세요.',
        'members': List.generate(
          (map['member_count'] as int?) ?? 0,
              (i) => {'id': i, 'name': '멤버${i + 1}', 'studentId': ''},
        ),
        'schedules': const [],
        'roles': const [],
        'chatMessages': const [],
        'notifications': const [],
        'isMock': false,
      },_currentUserId ?? -1);
    }).toList();
  }

  Future<ProjectDetailModel> fetchProjectDetail(String projectNumber) async {
    final roomId = int.tryParse(projectNumber);
    if (roomId == null) {
      throw Exception('유효하지 않은 프로젝트 번호입니다: $projectNumber');
    }

    final response = await client.get(
      Uri.parse('$baseUrl/rooms/$roomId'),
      headers: _headers,
    );

    _throwIfFailed(response, '프로젝트 상세 조회 실패');

    final data = _decodeMap(response.body);

    return ProjectDetailModel.fromJson({
      'projectNumber': (data['id'] ?? '').toString(),
      'projectTitle': data['title'] ?? '',
      'projectGoal': data['description'] ?? '프로젝트 목표를 입력하세요.',
      'members': data['members'] ?? const [],
      'schedules': const [],
      'roles': const [],
      'chatMessages': const [],
      'notifications': const [],
      'inviteCode': data['invite_code'] ?? '',
      'isMock': false,
    },_currentUserId ?? -1);
  }

  Future<ProjectDetailModel> createProject({
    required String title,
    required String goal,
    int maxMembers = 10,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/rooms'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'description': goal,
        'max_members': maxMembers,
      }),
    );

    _throwIfFailed(response, '프로젝트 생성 실패', allow201: true);

    final data = _decodeMap(response.body);

    return ProjectDetailModel.fromJson({
      'projectNumber': (data['id'] ?? '').toString(),
      'projectTitle': data['title'] ?? '',
      'projectGoal': data['description'] ?? goal,
      'members': const [],
      'schedules': const [],
      'roles': const [],
      'chatMessages': const [],
      'notifications': const [],
      'isMock': false,
    },_currentUserId ?? -1);
  }

  // =========================
  // 팀원 (현재 백엔드 없음 → fallback용)
  // =========================

  Future<void> createMember({
    required String projectNumber,
    required String name,
    required String studentId,
  }) async {
    throw UnsupportedError(
      '현재 백엔드에서는 팀원 추가 시 user_id가 필요합니다.',
    );
  }

  Future<void> updateMember({
    required String projectNumber,
    required int memberId,
    required String name,
    required String studentId,
  }) async {
    throw UnsupportedError('팀원 수정 API 없음');
  }

  Future<void> deleteMember({
    required String projectNumber,
    required int memberId,
  }) async {
    throw UnsupportedError('팀원 삭제 API 없음');
  }

  // =========================
  // 역할 (🔥 핵심 추가 부분)
  // =========================

  Future<void> createRole({
    required String projectNumber,
    required String title,
    required int assigneeId,
  }) async {
    throw UnsupportedError(
      '현재 백엔드 명세에는 역할 생성 API가 없습니다.',
    );
  }

  Future<void> updateRole({
    required String projectNumber,
    required int roleId,
    required String title,
    required int assigneeId,
  }) async {
    throw UnsupportedError(
      '현재 백엔드 명세에는 역할 수정 API가 없습니다.',
    );
  }

  Future<void> deleteRole({
    required String projectNumber,
    required int roleId,
  }) async {
    throw UnsupportedError(
      '현재 백엔드 명세에는 역할 삭제 API가 없습니다.',
    );
  }

  // =========================
  // 일정
  // =========================

  Future<void> createSchedule({
    required String projectNumber,
    required String title,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/schedules'),
      headers: _headers,
      body: jsonEncode({
        'day': _weekdayToApiValue(date),
        'start_time': _timeToApiString(startTime),
        'end_time': _timeToApiString(endTime),
        'name': title,
        'location': null,
        'description': '프로젝트 #$projectNumber 일정',
      }),
    );

    _throwIfFailed(response, '일정 추가 실패', allow201: true);
  }

  Future<void> updateSchedule({
    required String projectNumber,
    required int scheduleId,
    required String title,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    final response = await client.patch(
      Uri.parse('$baseUrl/schedules/$scheduleId'),
      headers: _headers,
      body: jsonEncode({
        'day': _weekdayToApiValue(date),
        'start_time': _timeToApiString(startTime),
        'end_time': _timeToApiString(endTime),
        'name': title,
        'location': null,
        'description': '프로젝트 #$projectNumber 일정',
      }),
    );

    _throwIfFailed(response, '일정 수정 실패');
  }

  Future<void> deleteSchedule({
    required String projectNumber,
    required int scheduleId,
  }) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/schedules/$scheduleId'),
      headers: _headers,
    );

    _throwIfFailed(response, '일정 삭제 실패', allow204: true);
  }

  // =========================
  // Task / Chat / Notification
  // =========================

  Future<void> createTask({
    required String projectNumber,
    required int roleId,
    required String title,
    required DateTime dueDate,
    required String priority,
    required String source,
  }) async {
    throw UnsupportedError('업무 생성 API 없음');
  }

  Future<void> updateTask({
    required String projectNumber,
    required int roleId,
    required int taskId,
    DateTime? dueDate,
    bool? done,
  }) async {
    throw UnsupportedError('업무 수정 API 없음');
  }

  Future<void> deleteTask({
    required String projectNumber,
    required int roleId,
    required int taskId,
  }) async {
    throw UnsupportedError('업무 삭제 API 없음');
  }


  Future<void> sendChat({
    required String projectNumber,
    required String message,
    required bool isFile,
  }) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('로그인이 필요합니다. access token이 없습니다.');
    }

    final roomId = projectNumber.trim();

    if (roomId.isEmpty) {
      throw Exception('room id가 비어 있습니다.');
    }

    if (message.trim().isEmpty) {
      throw Exception('메시지 내용이 비어 있습니다.');
    }

    final uri = Uri.parse('$baseUrl/chat/rooms/$roomId/messages');

    final body = {
      'message_type': isFile ? 'FILE' : 'TEXT',
      'content': message.trim(),
    };

    final response = await client.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    String errorMessage = '채팅 전송에 실패했습니다. (${response.statusCode})';

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        errorMessage = decoded['detail']?.toString() ??
            decoded['message']?.toString() ??
            errorMessage;
      }
    } catch (_) {}

    throw Exception(errorMessage);
  }

  Future<List<ChatMessageModel>> fetchChatMessages({
    required String projectNumber,
  }) async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('로그인이 필요합니다. access token이 없습니다.');
    }

    final roomId = projectNumber.trim();

    if (roomId.isEmpty) {
      throw Exception('room id가 비어 있습니다.');
    }

    final uri = Uri.parse('$baseUrl/chat/rooms/$roomId/messages');

    final response = await client.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode != 200) {
      String errorMessage = '채팅 목록 조회에 실패했습니다. (${response.statusCode})';

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          errorMessage =
              decoded['detail']?.toString() ??
                  decoded['message']?.toString() ??
                  errorMessage;
        }
      } catch (_) {}

      throw Exception(errorMessage);
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('채팅 목록 응답 형식이 올바르지 않습니다. Map이 아닙니다.');
    }

    final rawMessages = decoded['messages'];

    if (rawMessages is! List) {
      throw Exception('채팅 목록 응답 형식이 올바르지 않습니다. messages가 List가 아닙니다.');
    }

    final currentUserId = _currentUserId ?? -1;

    return rawMessages.map<ChatMessageModel>((item) {
      return ChatMessageModel.fromJson(
        item as Map<String, dynamic>,
        currentUserId,
      );
    }).toList();
  }

  Future<void> readAllChat(String projectNumber) async {
    throw UnsupportedError('채팅 읽음 API 없음');
  }

  // =========================
  // 공통
  // =========================

  void _throwIfFailed(
    http.Response response,
    String message, {
    bool allow201 = false,
    bool allow204 = false,
  }) {
    final valid = <int>{200};
    if (allow201) valid.add(201);
    if (allow204) valid.add(204);

    if (!valid.contains(response.statusCode)) {
      String detail = '';

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['detail'] != null) {
            detail = decoded['detail'].toString();
          } else if (decoded['message'] != null) {
            detail = decoded['message'].toString();
          }
        }
      } catch (_) {}

      if (detail.isNotEmpty) {
        throw Exception('$message (${response.statusCode}): $detail');
      }
      throw Exception('$message (${response.statusCode})');
    }
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('응답 형식이 올바르지 않습니다.');
    }
    return decoded;
  }

  static String _timeToApiString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  static String _weekdayToApiValue(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return 'monday';
    }
  }
}
