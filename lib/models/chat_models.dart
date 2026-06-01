/// Models cho phần Chat V3 (bám kiến trúc Agent V2 của web finwealth).
///
/// Pipeline backend (agent_service.run_pipeline) stream qua SSE các sự kiện:
///   classify -> agent_start/agent_done (mỗi agent) -> answer(token...) -> [DONE]
/// Các model dưới đây biểu diễn đầy đủ vòng đời đó để UI hiển thị tiến trình.

/// Chế độ phân tích — khớp field `mode` của request `/api/chat/send/`.
enum ChatMode { flash, pro }

extension ChatModeX on ChatMode {
  String get wire => this == ChatMode.pro ? 'pro' : 'flash';
  String get label => this == ChatMode.pro ? 'Pro' : 'Flash';

  static ChatMode fromWire(String? v) =>
      (v == 'pro') ? ChatMode.pro : ChatMode.flash;
}

/// Trạng thái một bước agent trong pipeline.
enum AgentStepStatus { running, done, cached, error }

/// Một bước chạy của agent (sự kiện `agent_start` / `agent_done` / `agent_error`).
class AgentStep {
  final String roleId;
  String label;
  String icon;
  AgentStepStatus status;
  int elapsedMs;
  String? summary;
  String? error;

  AgentStep({
    required this.roleId,
    required this.label,
    this.icon = '',
    this.status = AgentStepStatus.running,
    this.elapsedMs = 0,
    this.summary,
    this.error,
  });

  factory AgentStep.fromStart(Map<String, dynamic> json) {
    final roleId = json['role_id']?.toString() ?? '';
    return AgentStep(
      roleId: roleId,
      label: json['label']?.toString() ??
          (roleId.isNotEmpty ? roleId : 'Agent'),
      icon: json['icon']?.toString() ?? '',
    );
  }

  void applyDone(Map<String, dynamic> json) {
    status = (json['status']?.toString() == 'cached')
        ? AgentStepStatus.cached
        : AgentStepStatus.done;
    final e = json['elapsed_ms'];
    if (e is num) elapsedMs = e.toInt();
    summary = json['summary']?.toString();
  }

  void applyError(Map<String, dynamic> json) {
    status = AgentStepStatus.error;
    error = json['error']?.toString();
  }
}

/// Kết quả phân loại (sự kiện `type: classify`).
class ClassifyEvent {
  final String intent;
  final String ticker;
  final List<String> activatedAgents;
  final String reasoning;
  final ChatMode mode;

  ClassifyEvent({
    required this.intent,
    required this.ticker,
    required this.activatedAgents,
    required this.reasoning,
    required this.mode,
  });

  factory ClassifyEvent.fromJson(Map<String, dynamic> json) {
    return ClassifyEvent(
      intent: json['intent']?.toString() ?? '',
      ticker: json['ticker']?.toString() ?? '',
      activatedAgents: (json['activated_agents'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      reasoning: json['reasoning']?.toString() ?? '',
      mode: ChatModeX.fromWire(json['mode']?.toString()),
    );
  }
}

/// Một tin nhắn trong khung chat (UI model — có thể thay đổi khi stream).
class ChatMessage {
  String? id; // backend message_id (dùng cho feedback)
  final bool fromUser;
  String text;
  ChatMode mode;
  String? ticker;
  String? category;
  ClassifyEvent? classify;
  final List<AgentStep> steps;
  String? rating; // 'like' | 'dislike' | null
  bool isStreaming;
  bool hasError;

  ChatMessage({
    this.id,
    required this.fromUser,
    this.text = '',
    this.mode = ChatMode.flash,
    this.ticker,
    this.category,
    this.classify,
    List<AgentStep>? steps,
    this.rating,
    this.isStreaming = false,
    this.hasError = false,
  }) : steps = steps ?? [];

  /// Dựng từ một item lịch sử đã chuẩn hoá (xem ChatHistoryService.loadChatHistory).
  factory ChatMessage.history(Map<String, dynamic> m) {
    return ChatMessage(
      id: m['id']?.toString(),
      fromUser: m['role'] == 'user',
      text: m['content']?.toString() ?? '',
    );
  }
}

/// Payload feedback gửi lên `/api/chat/feedback/`.
class ChatFeedback {
  final String messageId;
  final String rating; // 'like' | 'dislike'
  final String? comment;

  ChatFeedback({required this.messageId, required this.rating, this.comment});

  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      };
}

/// Tóm tắt một cuộc hội thoại (cho danh sách / drawer).
class ChatConversationSummary {
  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatConversationSummary({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatConversationSummary.fromJson(Map<String, dynamic> json) {
    DateTime? parseTs(dynamic v) {
      if (v == null) return null;
      if (v is num) {
        return DateTime.fromMillisecondsSinceEpoch((v * 1000).toInt());
      }
      return DateTime.tryParse(v.toString());
    }

    return ChatConversationSummary(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['title'] ?? 'Cuộc trò chuyện').toString(),
      createdAt: parseTs(json['created_at']),
      updatedAt: parseTs(json['updated_at']),
    );
  }
}
