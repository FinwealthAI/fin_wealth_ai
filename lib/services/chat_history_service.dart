import 'package:dio/dio.dart';
import 'package:fin_wealth/config/api_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatHistoryService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  static const String _conversationKey = 'user_conversation';

  /// Gửi tin nhắn chat
  static Future<Response> sendMessage({
    required String message,
    required String username,
    String? conversationId,
    Map<String, dynamic>? inputs,
    String? token,
  }) async {
    final options = Options(
      responseType: ResponseType.stream,
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );

    return _dio.post(
      '/api/chat/send/',
      data: {
        'query': message,
        'user': username,
        'inputs': inputs ?? {},
        'conversation_id': conversationId,
        'response_mode': 'streaming',
      },
      options: options,
    );
  }

  /// Dừng generate tin nhắn
  static Future<void> stopGenerate({
    required String taskId,
    required String username,
    String? token,
  }) async {
    try {
      await _dio.post(
        '/api/chat/stop/',
        data: {
          'task_id': taskId,
          'user': username,
        },
        options: token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null,
      );
    } catch (e) {
      print('Lỗi dừng generate: $e');
    }
  }

  /// Gửi feedback cho tin nhắn
  static Future<void> sendFeedback({
    required String messageId,
    required String rating, // 'like' or 'dislike'
    required String username,
    String? token,
  }) async {
    try {
      await _dio.post(
        '/api/chat/feedback/',
        data: {
          'message_id': messageId,
          'rating': rating,
          'user': username,
        },
        options: token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null,
      );
    } catch (e) {
      if (e is DioException) {
        print('Lỗi gửi feedback: ${e.message}');
        print('Response data: ${e.response?.data}');
      } else {
        print('Lỗi gửi feedback: $e');
      }
    }
  }

  /// Tải lịch sử chat từ API
  static Future<List<Map<String, dynamic>>> loadChatHistory(
    String username, {
    String? conversationId,
    String? token,
  }) async {
    try {
      String path = '/api/chat/conversations/messages/';
      if (conversationId != null && conversationId.isNotEmpty) {
        path = '/api/chat/conversations/$conversationId/messages/';
      }

      final response = await _dio.get(
        path,
        queryParameters: {
          'user': username,
        },
        options: token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null,
      );

      if (response.data != null && response.data['data'] is List) {
        final List<dynamic> data = response.data['data'];
        final List<Map<String, dynamic>> messages = [];

        for (final item in data) {
          if (item['query'] != null && item['query'].toString().isNotEmpty) {
            messages.add({
              'role': 'user',
              'content': item['query'],
              'id': item['id'],
              'conversation_id': item['conversation_id'],
            });
          }

          if (item['answer'] != null && item['answer'].toString().isNotEmpty) {
            messages.add({
              'role': 'assistant',
              'content': item['answer'],
              'id': item['id'],
              'conversation_id': item['conversation_id'],
            });
          }
        }
        return messages;
      }
      return [];
    } catch (e) {
      print('Lỗi khi tải lịch sử chat từ API: $e');
      return [];
    }
  }

  /// Xóa cuộc hội thoại
  static Future<void> clearChatHistory(String username, String conversationId, {String? token}) async {
    if (conversationId.isEmpty) return;
    try {
      await _dio.delete(
        '/api/chat/conversations/$conversationId/delete/',
        data: {
          'user': username,
        },
        options: token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null,
      );
    } catch (e) {
      print('Lỗi khi xóa conversation $conversationId: $e');
      rethrow;
    }
  }

  /// Lấy danh sách conversations của user
  static Future<List<Map<String, dynamic>>> getUserConversations(
    String username, {
    int limit = 20,
    String? token,
  }) async {
    try {
      final response = await _dio.get(
        '/api/chat/conversations/',
        queryParameters: {
          'user': username,
          'limit': limit,
        },
        options: token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null,
      );

      if (response.data != null && response.data['data'] is List) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      print('Lỗi khi lấy danh sách conversations: $e');
      return [];
    }
  }

  /// Lấy conversation mới nhất
  static Future<String?> getLatestConversationId(String username, {String? token}) async {
    try {
      final conversations = await getUserConversations(username, limit: 1, token: token);
      if (conversations.isNotEmpty) {
        return conversations.first['id'];
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy conversation mới nhất: $e');
      return null;
    }
  }

  /// Lấy conversation_id đã lưu cho user
  static Future<String?> getSavedConversationId(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = '${_conversationKey}_$username';
      return prefs.getString(userKey);
    } catch (e) {
      print('Lỗi khi lấy conversation_id đã lưu: $e');
      return null;
    }
  }

  /// Lưu conversation_id cho user
  static Future<void> saveConversationId(String username, String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = '${_conversationKey}_$username';
      await prefs.setString(userKey, conversationId);
    } catch (e) {
      print('Lỗi khi lưu conversation_id: $e');
    }
  }

  /// Xóa conversation_id đã lưu
  static Future<void> clearSavedConversationId(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = '${_conversationKey}_$username';
      await prefs.remove(userKey);
    } catch (e) {
      print('Lỗi khi xóa conversation_id: $e');
    }
  }

  /// Lấy hoặc tạo conversation_id cho user
  static Future<String> getOrCreateConversationId(String username, {String? token}) async {
    try {
      String? savedId = await getSavedConversationId(username);
      if (savedId != null && savedId.isNotEmpty) {
        return savedId;
      }

      String? latestId = await getLatestConversationId(username, token: token);
      if (latestId != null && latestId.isNotEmpty) {
        await saveConversationId(username, latestId);
        return latestId;
      }

      return '';
    } catch (e) {
      print('Lỗi khi lấy/tạo conversation_id: $e');
      return '';
    }
  }
}