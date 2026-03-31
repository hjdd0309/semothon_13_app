import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/project_detail_model.dart';

class ProjectService {
  final String baseUrl;
  final http.Client client;

  String? _accessToken;

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
        'members': const [],
        'schedules': const [],
        'roles': const [],
        'chatMessages': const [],
        'notifications': const [],
        'isMock': false,
      });
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
      'isMock': false,
    });
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
    });
  }

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
    throw UnsupportedError(
      '현재 백엔드 명세에는 팀원 수정 API가 없습니다.',
    );
  }

  Future<void> deleteMember({
    required String projectNumber,
    required int memberId,
  }) async {
    throw UnsupportedError(
      '현재 백엔드 명세에는 팀원 삭제 API가 없습니다.',
    );
  }

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

  Future<void> createTask({
    required String projectNumber,
    required int roleId,
    required String title,
    required DateTime dueDate,
    required String priority,
    required String source,
  }) async {
    throw UnsupportedError(
      '현재 백엔드 명세에는 역할/업무 생성 API가 없습니다.',
    );
  }

  Future<void> updateTask({
    required String projectNumber,
    required int roleId,
    required int taskId,
    DateTime? dueDate,
    bool? done,
  }) async {
    throw UnsupportedError(
      '현재 백엔드 명세에는 역할/업무 수정 API가 없습니다.',
    );
  }

  Future<void> deleteTask({
    required String projectNumber,
    required int roleId,
    required int taskId,
  }) async {
    throw UnsupportedError(
      '현재 백엔드 명세에는 역할/업무 삭제 API가 없습니다.',
    );
  }

  Future<void> sendChat({
    required String projectNumber,
    required String message,
    required bool isFile,
  }) async {
    throw UnsupportedError(
      '현재 백엔드 명세에는 채팅 전송 API가 없습니다.',
    );
  }

  Future<void> readAllNotifications(String projectNumber) async {
    throw UnsupportedError(
      '현재 백엔드 명세에는 알림 읽음 처리 API가 없습니다.',
    );
  }

  Future<void> readAllChat(String projectNumber) async {
    throw UnsupportedError(
      '현재 백엔드 명세에는 채팅 읽음 처리 API가 없습니다.',
    );
  }

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
