import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String baseUrl = 'https://semothon13app-production.up.railway.app';

  // 1. 아이스브레이킹 결과 API
  // parameters: roomId, roomName, userProfile (optional)
  // response: Map with AI result
  static Future<Map<String, dynamic>> getIcebreakingResult(int roomId, String subject, List<Map<String, dynamic>> answers) async {
    final url = Uri.parse('$baseUrl/api/ai/ice-breaking');
    
    // Convert current answers array into the format backend expects:
    // "answers": [{"user_id": ..., "answers": ["..", ".."]}]

    final Map<String, dynamic> body = {
      "room_id": roomId,
      "title": subject,
      "question": "아이스브레이킹 성향 질문들",
      "context_json": {"members": answers}, 
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to load icebreaking result: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 2. 특정 과목의 주제 선정 폼 리스트 가져오기
  static Future<Map<String, dynamic>> getTopicQuestions(String subject) async {
    final url = Uri.parse('$baseUrl/api/ai/topics/questions?subject=$subject');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to load topic questions');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 3. 주제 추천 결과 제출 및 받기
  static Future<Map<String, dynamic>> submitTopicAnswersAndGetRecommendation(int roomId, String subject, List<Map<String, dynamic>> memberAnswers) async {
    final url = Uri.parse('$baseUrl/api/ai/topics');
    
    final Map<String, dynamic> body = {
      "room_id": roomId,
      "subject": subject,
      "member_answers": memberAnswers
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to get recommendation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 4. 역할 및 업무 분배 API (DB 저장 포함)
  static Future<Map<String, dynamic>> distributeTasks(int roomId, String finalTopic) async {
    final url = Uri.parse('$baseUrl/api/ai/distribute');
    
    // ignore: avoid_print
    print('🚀 [DEBUG] DISTRIBUTE REQUEST - roomId: $roomId, finalTopic: "$finalTopic"');

    final Map<String, dynamic> body = {
      "room_id": roomId,
      "final_topic": finalTopic,
      "deadline": null // 향후 필요 시 추가 가능
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to distribute tasks: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
