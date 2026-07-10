import 'dart:io';

import 'package:dio/dio.dart';

/// Phân loại lỗi khi gọi Chat SSE — thay cho việc show exception thô ra UI.
///
/// Mỗi loại có thông điệp tiếng Việt thân thiện + cờ [canRetry] (có nên hiện
/// nút "Thử lại" không) và [shouldResume] (có nên thử fetch lại câu trả lời
/// server đã lưu ở background không — xem ChatHistoryService.fetchLatestAssistantAnswer).
enum ChatErrorType {
  /// Mất kết nối mạng (không Wi-Fi/4G, DNS fail, host unreachable).
  noNetwork,

  /// Kết nối được nhưng server phản hồi chậm quá ngưỡng (connect/receive timeout).
  /// Server VẪN có thể đã hoàn tất & lưu câu trả lời → nên resume.
  timeout,

  /// Server trả 5xx (đang bận / worker bị kill / deploy).
  serverBusy,

  /// 403 — chưa đủ điểm Wealth để dùng Trợ lý AI.
  forbidden,

  /// 429 — đang có cuộc hội thoại khác xử lý (cap đồng thời).
  tooManyRequests,

  /// Không phân loại được.
  unknown,
}

class ChatError implements Exception {
  final ChatErrorType type;

  /// Thông điệp hiển thị cho user (đã tiếng Việt hoá).
  final String message;

  /// Chi tiết kỹ thuật (log/debug) — KHÔNG hiển thị cho user.
  final String? detail;

  const ChatError(this.type, this.message, {this.detail});

  /// Có nên hiện nút "Thử lại" không. Lỗi gate điểm (403) không retry được.
  bool get canRetry => type != ChatErrorType.forbidden;

  /// Có nên thử lấy lại câu trả lời server đã persist ở background không.
  /// Chỉ với các lỗi mà pipeline server VẪN chạy tiếp tới cùng (timeout/đứt
  /// kết nối giữa chừng) — KHÔNG áp cho 403/429 (server chưa hề xử lý).
  bool get shouldResume =>
      type == ChatErrorType.timeout ||
      type == ChatErrorType.noNetwork ||
      type == ChatErrorType.serverBusy;

  /// Map từ bất kỳ exception nào (chủ yếu [DioException]) sang [ChatError].
  factory ChatError.from(Object e) {
    if (e is ChatError) return e;

    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.transformTimeout:
          return const ChatError(
            ChatErrorType.timeout,
            'Máy chủ phản hồi chậm. Câu trả lời có thể vẫn đang được xử lý — '
            'thử lại sau giây lát.',
          );
        case DioExceptionType.connectionError:
          return ChatError(
            ChatErrorType.noNetwork,
            'Không có kết nối mạng. Kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại.',
            detail: e.message,
          );
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode ?? 0;
          if (code == 403) {
            return ChatError(
              ChatErrorType.forbidden,
              _detailOr(e,
                  'Bạn chưa đủ điểm Wealth để sử dụng Trợ lý AI.'),
              detail: 'HTTP 403',
            );
          }
          if (code == 429) {
            return const ChatError(
              ChatErrorType.tooManyRequests,
              'Bạn đang có một cuộc hội thoại khác đang xử lý. '
              'Vui lòng đợi xong rồi thử lại.',
              detail: 'HTTP 429',
            );
          }
          if (code >= 500) {
            return ChatError(
              ChatErrorType.serverBusy,
              'Máy chủ đang bận. Vui lòng thử lại sau giây lát.',
              detail: 'HTTP $code',
            );
          }
          return ChatError(
            ChatErrorType.unknown,
            'Có lỗi xảy ra khi gửi tin nhắn. Vui lòng thử lại.',
            detail: 'HTTP $code',
          );
        case DioExceptionType.cancel:
          // Người dùng chủ động dừng — không phải lỗi thực sự.
          return const ChatError(
            ChatErrorType.unknown,
            'Đã dừng.',
            detail: 'cancelled',
          );
        case DioExceptionType.unknown:
        case DioExceptionType.badCertificate:
          if (e.error is SocketException) {
            return ChatError(
              ChatErrorType.noNetwork,
              'Không có kết nối mạng. Kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại.',
              detail: e.message,
            );
          }
          return ChatError(
            ChatErrorType.unknown,
            'Có lỗi xảy ra khi gửi tin nhắn. Vui lòng thử lại.',
            detail: e.message,
          );
      }
    }

    if (e is SocketException) {
      return const ChatError(
        ChatErrorType.noNetwork,
        'Không có kết nối mạng. Kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại.',
      );
    }

    return ChatError(
      ChatErrorType.unknown,
      'Có lỗi xảy ra khi gửi tin nhắn. Vui lòng thử lại.',
      detail: e.toString(),
    );
  }

  /// Lấy `detail` từ body 403 nếu Dio đã gom sẵn thành Map/String; nếu là
  /// stream (ResponseType.stream) thì không đọc được ở đây → dùng [fallback].
  static String _detailOr(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    if (data is String && data.isNotEmpty && data.length < 300) {
      return data;
    }
    return fallback;
  }

  @override
  String toString() => 'ChatError($type): $message${detail != null ? ' [$detail]' : ''}';
}
