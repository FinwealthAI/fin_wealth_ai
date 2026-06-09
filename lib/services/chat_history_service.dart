import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/chat_models.dart';

/// Service cho phần Chat V3 — nói chuyện với Agent V2 backend (`/api/chat/...`).
///
/// Điểm khác V2: `sendMessage` cũ chỉ trả `Response` rồi để màn hình tự parse.
/// V3 cung cấp `streamMessage(...)` trả `Stream<Map>` đã decode sẵn từng sự kiện
/// SSE (`{type: classify}`, `{type: agent_start}`, `{answer: ...}`, ...), kèm
/// sự kiện kết thúc `{'type': '__done__'}`.
class ChatHistoryService {
  static final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  static Options _opts({String? token, ResponseType? responseType}) => Options(
        responseType: responseType,
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

  // ---------------------------------------------------------------------------
  // Gửi tin nhắn — stream SSE đã decode
  // ---------------------------------------------------------------------------

  /// Gửi câu hỏi tới Agent V2 và stream các sự kiện đã decode.
  ///
  /// Mỗi phần tử là 1 object JSON từ dòng `data: {...}`. Khi gặp `data: [DONE]`
  /// sẽ phát `{'type': '__done__'}` rồi kết thúc stream.
  static Stream<Map<String, dynamic>> streamMessage({
    required String message,
    String? conversationId,
    ChatMode mode = ChatMode.flash,
    Map<String, dynamic>? inputs,
    String? token,
  }) async* {
    final response = await _dio.post(
      '/api/chat/send/',
      data: {
        'query': message,
        'conversation_id': conversationId,
        'mode': mode.wire,
        'inputs': inputs ?? const {},
        'source': 'mobile',
      },
      options: _opts(token: token, responseType: ResponseType.stream),
    );

    final stream = (response.data.stream as Stream)
        .cast<List<int>>()
        .transform(utf8.decoder);

    final partial = StringBuffer();

    Map<String, dynamic>? decode(String raw) {
      final clean = raw.trim();
      if (!clean.startsWith('data:')) return null;
      final dataStr = clean.substring(clean.indexOf(':') + 1).trim();
      if (dataStr.isEmpty) return null;
      if (dataStr == '[DONE]') return {'type': '__done__'};
      try {
        final j = jsonDecode(dataStr);
        if (j is Map<String, dynamic>) return j;
      } catch (_) {}
      return null;
    }

    await for (final chunk in stream) {
      partial.write(chunk);
      final lines = partial.toString().split('\n');
      // Giữ lại đoạn cuối (có thể là dòng JSON chưa hoàn chỉnh).
      partial
        ..clear()
        ..write(lines.removeLast());
      for (final line in lines) {
        final event = decode(line);
        if (event == null) continue;
        yield event;
        if (event['type'] == '__done__') return;
      }
    }

    // Flush phần còn lại sau khi stream đóng.
    final leftover = decode(partial.toString());
    if (leftover != null && leftover['type'] != '__done__') {
      yield leftover;
    }
    yield {'type': '__done__'};
  }

  // ---------------------------------------------------------------------------
  // Stop / Feedback
  // ---------------------------------------------------------------------------

  /// Dừng việc generate response (backend hủy task theo `task_id`).
  static Future<void> stopGenerate({
    required String taskId,
    String? token,
  }) async {
    await _dio.post(
      '/api/chat/stop/',
      data: {'task_id': taskId},
      options: _opts(token: token),
    );
  }

  /// Gửi feedback (like/dislike) cho tin nhắn.
  static Future<void> sendFeedback({
    required String messageId,
    required String rating, // 'like' | 'dislike'
    String? comment,
    String? token,
  }) async {
    await _dio.post(
      '/api/chat/feedback/',
      data: {
        'message_id': messageId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      },
      options: _opts(token: token),
    );
  }

  // ---------------------------------------------------------------------------
  // Conversations
  // ---------------------------------------------------------------------------

  /// Danh sách hội thoại của user.
  static Future<List<ChatConversationSummary>> listConversations({
    int limit = 30,
    String? token,
  }) async {
    try {
      final response = await _dio.get(
        '/api/chat/conversations/',
        queryParameters: {'limit': limit},
        options: _opts(token: token),
      );
      final data = response.data?['data'] as List? ?? const [];
      return data
          .map((e) =>
              ChatConversationSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Tải lịch sử tin nhắn + trạng thái giới hạn hội thoại.
  ///
  /// `limitStatus`: 'locked' (đã khóa) | 'warning' (sắp đầy) | null/khác.
  static Future<({List<Map<String, dynamic>> messages, String? limitStatus})>
      loadChatHistory({
    String? conversationId,
    String? token,
    bool markRead = false,
  }) async {
    String path = '/api/chat/conversations/messages/';
    if (conversationId != null && conversationId.isNotEmpty) {
      path = '/api/chat/conversations/$conversationId/messages/';
    }

    final response = await _dio.get(
      path,
      // mark_read=1 → backend đánh dấu các bản tin định kỳ trong cuộc là đã đọc.
      queryParameters: markRead ? const {'mark_read': '1'} : null,
      options: _opts(token: token),
    );

    final List<Map<String, dynamic>> messages = [];
    final data = response.data?['data'] as List?;
    if (data != null) {
      for (final item in data) {
        if (item['query'] != null && item['query'].toString().isNotEmpty) {
          messages.add({
            'role': 'user',
            'content': item['query'],
            'id': item['id'],
          });
        }
        if (item['answer'] != null && item['answer'].toString().isNotEmpty) {
          messages.add({
            'role': 'assistant',
            'content': item['answer'],
            'id': item['id'],
          });
        }
      }
    }
    return (
      messages: messages,
      limitStatus: response.data?['limit_status']?.toString(),
    );
  }

  /// Đổi tên hội thoại.
  static Future<void> renameConversation(
    String conversationId,
    String name, {
    String? token,
  }) async {
    await _dio.post(
      '/api/chat/conversations/$conversationId/rename/',
      data: {'name': name},
      options: _opts(token: token),
    );
  }

  /// Xóa hội thoại.
  static Future<void> deleteConversation(
    String conversationId, {
    String? token,
  }) async {
    await _dio.delete(
      '/api/chat/conversations/$conversationId/delete/',
      options: _opts(token: token),
    );
  }

  // ---------------------------------------------------------------------------
  // Bản tin định kỳ (proactive) chưa đọc — badge + toast nhắc nhở
  // ---------------------------------------------------------------------------

  /// Đếm bản tin định kỳ chưa đọc của user (số hội thoại có tin chủ động mới).
  static Future<ProactiveUnread> fetchProactiveUnread({String? token}) async {
    if (token == null) return ProactiveUnread.empty();
    try {
      final response = await _dio.get(
        '/api/chat/proactive/unread/',
        options: _opts(token: token),
      );
      final data = response.data;
      if (data is Map) {
        return ProactiveUnread.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return ProactiveUnread.empty();
  }

  // ---------------------------------------------------------------------------
  // Lịch hỏi tự động (scheduled chat) — quản lý từ nút lịch ở header
  // ---------------------------------------------------------------------------

  /// Danh sách lịch hỏi tự động + trạng thái đủ điều kiện dùng tính năng.
  static Future<ScheduleListResult> listSchedules({String? token}) async {
    if (token == null) {
      return ScheduleListResult(eligible: false, minPoints: 0, schedules: const []);
    }
    try {
      final response = await _dio.get(
        '/api/super-broker/schedules/',
        options: _opts(token: token),
      );
      final data = response.data as Map? ?? const {};
      final raw = (data['schedules'] as List?) ?? const [];
      return ScheduleListResult(
        eligible: data['eligible'] == true,
        minPoints: (data['min_points'] as num?)?.toInt() ?? 0,
        schedules: raw
            .whereType<Map>()
            .map((e) => ScheduledChat.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } catch (_) {
      return ScheduleListResult(eligible: false, minPoints: 0, schedules: const []);
    }
  }

  /// Bật/tắt một lịch (không xóa).
  static Future<bool> toggleSchedule({
    required int scheduleId,
    required bool enabled,
    String? token,
  }) async {
    try {
      final response = await _dio.post(
        '/api/super-broker/schedules/toggle/',
        data: {'schedule_id': scheduleId, 'enabled': enabled},
        options: _opts(token: token),
      );
      return (response.data as Map?)?['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Xóa một lịch hỏi tự động.
  static Future<bool> deleteSchedule({
    required int scheduleId,
    String? token,
  }) async {
    try {
      final response = await _dio.post(
        '/api/super-broker/schedules/delete/',
        data: {'schedule_id': scheduleId},
        options: _opts(token: token),
      );
      return (response.data as Map?)?['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Hồ sơ đầu tư — cờ đã điền đủ chưa (để nhắc bổ sung trong chat)
  // ---------------------------------------------------------------------------

  /// Trả về `has_complete_profile` từ `/api/investment-profile/`.
  /// `true`: đã có hồ sơ · `false`: chưa · `null`: chưa rõ (lỗi/khách).
  static Future<bool?> hasCompleteProfile({String? token}) async {
    if (token == null) return null;
    try {
      final resp = await _dio.get(
        '/api/investment-profile/',
        options: _opts(token: token),
      );
      final v = resp.data?['has_complete_profile'];
      return v is bool ? v : null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Valid tickers (cho ticker detection trong ô nhập)
  // ---------------------------------------------------------------------------

  static List<String>? _tickerCache;

  static Future<List<String>> getValidTickers({String? token}) async {
    if (_tickerCache != null) return _tickerCache!;
    try {
      final response = await _dio.get(
        '/api/chat/valid-tickers/',
        options: _opts(token: token),
      );
      final list = (response.data?['tickers'] as List?)
              ?.map((e) => e.toString().toUpperCase())
              .toList() ??
          <String>[];
      _tickerCache = list;
      return list;
    } catch (_) {
      return _tickerCache ?? const [];
    }
  }

  // ---------------------------------------------------------------------------
  // Conversation id persistence (per user)
  // ---------------------------------------------------------------------------

  static String _key(String username) => 'user_conversation_$username';

  static Future<void> saveConversationId(
      String username, String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(username), conversationId);
  }

  static Future<String?> getSavedConversationId(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(username));
  }

  static Future<void> clearSavedConversationId(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(username));
  }

  static Future<String?> getLatestConversationId({String? token}) async {
    final convs = await listConversations(limit: 1, token: token);
    return convs.isNotEmpty ? convs.first.id : null;
  }

  /// Lấy conversation id đã lưu, nếu chưa có thì lấy hội thoại mới nhất.
  static Future<String> getOrCreateConversationId(
    String username, {
    String? token,
  }) async {
    final savedId = await getSavedConversationId(username);
    if (savedId != null && savedId.isNotEmpty) return savedId;

    final latestId = await getLatestConversationId(token: token);
    if (latestId != null && latestId.isNotEmpty) {
      await saveConversationId(username, latestId);
      return latestId;
    }
    return '';
  }
}
