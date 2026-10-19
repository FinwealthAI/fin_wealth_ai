/// Nền tảng không phải web dùng Dio (`ResponseType.stream`) — xem
/// `ChatHistoryService.streamMessage`. Hàm này chỉ để biên dịch.
Stream<List<int>> postSseStream({
  required String url,
  required Map<String, String> headers,
  required String body,
  required Duration idleTimeout,
}) =>
    throw UnsupportedError('postSseStream chỉ dùng trên web');
