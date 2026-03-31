import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl =
      'https://semothon13app-production.up.railway.app';

  Future<String> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final Map<String, dynamic> data = _decodeMap(response);

    if (response.statusCode == 200) {
      final token = data['access_token']?.toString() ?? '';
      if (token.isEmpty) {
        throw Exception('로그인 응답에 access_token이 없습니다.');
      }
      return token;
    }

    final message = data['detail']?.toString() ??
        data['message']?.toString() ??
        '로그인에 실패했어요.';
    throw Exception(message);
  }

  Future<void> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final Map<String, dynamic> data = _decodeMap(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    final message = data['detail']?.toString() ??
        data['message']?.toString() ??
        '회원가입에 실패했어요.';
    throw Exception(message);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
