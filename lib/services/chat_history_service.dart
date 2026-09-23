import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/chat_models.dart';
import 'chat_error.dart';

/// Service cho phần Chat V3 — nói chuyện với Agent V2 backend (`/api/chat/...`).
///
/// Điểm khác V2: `sendMessage` cũ chỉ trả `Response` rồi để màn hình tự parse.
/// V3 cung cấp `streamMessage(...)` trả `Stream<Map>` đã decode sẵn từng sự kiện
/// SSE (`{type: classify}`, `{type: agent_start}`, `{answer: ...}`, ...), kèm
/// sự kiện kết thúc `{'type': '__done__'}`.
class ChatHistoryService {
  // receiveTimeout PHẢI lớn hơn nhịp heartbeat của server (SSE comment ": ping"
  // ~12s, xem agent/views.py) để không cắt nhầm khi pipeline đang tính toán lâu;
  // 30s = 2.5 chu kỳ heartbeat → chỉ đứt khi thực sự mất byte kéo dài.
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

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
    // Chú ý: SSE comment (dòng bắt đầu bằng ':' như heartbeat ": ping") KHÔNG có
    // prefix "data:" nên `decode` trả null → tự bỏ qua, chỉ giữ kết nối sống.
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

    // Mọi lỗi mạng/HTTP → ChatError có kiểu (xem chat_error.dart) để UI hiển thị
    // thông điệp thân thiện + quyết định resume/retry. `rethrow` giữ nguyên nếu
    // đã là ChatError (không bọc chồng).
    try {
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
          // [DONE] THẬT từ server → kết thúc SẠCH.
          if (event['type'] == '__done__') return;
        }
      }

      // Flush phần còn lại sau khi stream đóng.
      final leftover = decode(partial.toString());
      if (leftover != null && leftover['type'] != '__done__') {
        yield leftover;
      }
      // Tới đây = stream đóng mà KHÔNG có [DONE] → bị CẮT giữa chừng (proxy/mạng
      // rớt, worker bị kill). Phải đánh dấu `clean: false` để UI biết mà RESUME:
      // pipeline server vẫn chạy nốt ở thread riêng rồi persist (agent/views.py
      // `_produce`). Trước đây luôn phát `__done__` trơn nên cắt im lặng bị hiểu
      // nhầm là xong → mất hẳn câu trả lời. Đối ứng `meta.clean` bên web.
      yield {'type': '__done__', 'clean': false};
    } on ChatError {
      rethrow;
    } catch (e) {
      throw ChatError.from(e);
    }
  }

  /// Giãn cách giữa các lần thử lấy lại (tổng ~44s). Giữ ĐỒNG BỘ với web
  /// `agent/static/dify/js/chat_error.js` (RESUME_DELAYS_MS).
  static const List<int> _resumeDelaysMs = [0, 1500, 2500, 4000, 6000, 8000, 10000, 12000];

  /// Một lần quét: câu trả lời assistant của lượt SAU [afterMessageId].
  static Future<String?> _fetchTurnAnswer({
    required String conversationId,
    required String afterMessageId,
    String? token,
  }) async {
    try {
      final anchor = int.tryParse(afterMessageId);
      if (anchor == null) return null;
      final result =
          await loadChatHistory(conversationId: conversationId, token: token);
      for (final m in result.messages.reversed) {
        if (m['role'] != 'assistant') continue;
        final id = int.tryParse(m['id']?.toString() ?? '');
        if (id == null) continue;
        if (id <= anchor) break; // đã lùi qua lượt cũ → dừng
        final content = m['content']?.toString() ?? '';
        if (content.trim().isNotEmpty) return content;
      }
    } catch (_) {}
    return null;
  }

  /// RESUME: lấy câu trả lời đã persist của ĐÚNG lượt vừa bị cắt.
  ///
  /// [afterMessageId] = `message_id` phát ở SSE Event 2 — id của message USER lượt
  /// này. Assistant message chỉ ra đời ở `_save_turn`, tức SAU khi pipeline chạy
  /// xong, nên lúc stream đứt nó gần như luôn CHƯA tồn tại (99% độ trễ nằm trước
  /// ký tự đầu tiên). Hai hệ quả bắt buộc xử lý:
  ///   1. NEO THEO ID: chỉ nhận assistant có id > afterMessageId. Bản cũ lấy
  ///      "answer mới nhất của hội thoại" → khi lượt này chưa lưu sẽ trả về câu
  ///      trả lời của LƯỢT TRƯỚC và hiển thị như trả lời cho câu hỏi mới.
  ///   2. CHỜ: thử lại có giãn cách cho tới khi server persist xong.
  ///
  /// [onWait] được gọi trước mỗi lần chờ → UI báo "đang lấy lại".
  /// Best-effort — KHÔNG ném lỗi ra ngoài.
  static Future<String?> resumeTurnAnswer({
    required String conversationId,
    required String afterMessageId,
    String? token,
    void Function()? onWait,
  }) async {
    for (final wait in _resumeDelaysMs) {
      if (wait > 0) {
        onWait?.call();
        await Future<void>.delayed(Duration(milliseconds: wait));
      }
      final ans = await _fetchTurnAnswer(
        conversationId: conversationId,
        afterMessageId: afterMessageId,
        token: token,
      );
      if (ans != null) return ans;
    }
    return null;
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
  ///
  /// [kind]: 'user' (chat do user tạo) | 'proactive' (bản tin định kỳ) |
  /// 'all' (mặc định — giữ hành vi cũ). Khớp query param `kind` của backend
  /// `list_conversations` — tách luồng để chat user không bị bản tin tự động
  /// (2 lần/ngày) chôn vùi khỏi danh sách gần nhất.
  static Future<List<ChatConversationSummary>> listConversations({
    int limit = 30,
    String kind = 'all',
    String? token,
  }) async {
    try {
      final response = await _dio.get(
        '/api/chat/conversations/',
        queryParameters: {
          'limit': limit,
          if (kind != 'all') 'kind': kind,
        },
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
        // kind: 'user_reply' | 'proactive' — phân biệt bản tin định kỳ (web).
        final kind = item['kind'];
        if (item['query'] != null && item['query'].toString().isNotEmpty) {
          messages.add({
            'role': 'user',
            'content': item['query'],
            'id': item['id'],
            'kind': kind,
          });
        }
        if (item['answer'] != null && item['answer'].toString().isNotEmpty) {
          messages.add({
            'role': 'assistant',
            'content': item['answer'],
            'id': item['id'],
            'kind': kind,
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

  /// Trả về `has_profile` từ `/api/super-broker/profile-summary/` — cùng nguồn
  /// dữ liệu mà `InvestmentProfileScreen` dùng để quyết định hiện TÓM TẮT hay
  /// bài khảo sát. Field `has_complete_profile` ở `/api/investment-profile/`
  /// là check V1 cũ (4 field legacy), không được cập nhật khi làm khảo sát
  /// Super Broker → khiến banner nhắc hồ sơ hiện lại dù đã khảo sát xong.
  /// `true`: đã có hồ sơ · `false`: chưa · `null`: chưa rõ (lỗi/khách).
  static Future<bool?> hasCompleteProfile({String? token}) async {
    if (token == null) return null;
    try {
      final resp = await _dio.get(
        '/api/super-broker/profile-summary/',
        options: _opts(token: token),
      );
      final v = resp.data?['has_profile'];
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
    // kind 'user': khi resume, mở lại chat user gần nhất thay vì bản tin
    // tự động vừa được gửi (bản tin có thể "mới hơn" mọi chat thật).
    final convs = await listConversations(limit: 1, kind: 'user', token: token);
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
