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

/// Skill được nạp trong 1 bước agent (sự kiện `skill_loaded`).
class AgentSkill {
  final String skill;
  final String displayName;
  const AgentSkill({required this.skill, required this.displayName});

  factory AgentSkill.fromJson(Map<String, dynamic> json) => AgentSkill(
        skill: json['skill']?.toString() ?? '',
        displayName: json['display_name']?.toString() ??
            json['skill']?.toString() ??
            '',
      );
}

/// Một bước chạy của agent (sự kiện `agent_start` / `agent_done` / `agent_error`).
class AgentStep {
  final String roleId;
  String label;
  String icon;
  AgentStepStatus status;
  int elapsedMs;
  String? summary;
  String? error;

  /// Các skill đã nạp trong bước này (sự kiện `skill_loaded`).
  final List<AgentSkill> skills;

  AgentStep({
    required this.roleId,
    required this.label,
    this.icon = '',
    this.status = AgentStepStatus.running,
    this.elapsedMs = 0,
    this.summary,
    this.error,
    List<AgentSkill>? skills,
  }) : skills = skills ?? [];

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

/// Thẻ dữ liệu inline (sự kiện `type: card`). Render DƯỚI prose.
/// `variant`: stock | action | market | comparison | opportunity | portfolio
///            | strategy | chart.
class ChatCard {
  final String variant;
  final String? ticker;
  final Map<String, dynamic> data;

  ChatCard({required this.variant, this.ticker, required this.data});

  factory ChatCard.fromJson(Map<String, dynamic> json) => ChatCard(
        variant: json['variant']?.toString() ?? '',
        ticker: json['ticker']?.toString(),
        data: (json['data'] is Map)
            ? Map<String, dynamic>.from(json['data'])
            : const {},
      );
}

/// Một lựa chọn trong popup user_choice (vd 1 danh mục).
class ChoiceOption {
  final dynamic value;
  final String label;
  final String? sublabel;

  ChoiceOption({required this.value, required this.label, this.sublabel});

  factory ChoiceOption.fromJson(Map<String, dynamic> json) => ChoiceOption(
        value: json['value'],
        label: json['label']?.toString() ?? '',
        sublabel: json['sublabel']?.toString(),
      );
}

/// Popup tương tác ngược (sự kiện `type: user_choice`).
/// `choiceKey`: 'portfolio' (chọn danh mục) | 'input_position' (nhập vị thế).
class UserChoice {
  final String choiceKey;
  final String prompt;
  final List<ChoiceOption> options;
  final String resendQuery;
  final String? ticker;

  UserChoice({
    required this.choiceKey,
    required this.prompt,
    required this.options,
    required this.resendQuery,
    this.ticker,
  });

  factory UserChoice.fromJson(Map<String, dynamic> json) => UserChoice(
        choiceKey: json['choice_key']?.toString() ?? 'portfolio',
        prompt: json['prompt']?.toString() ?? 'Vui lòng chọn',
        options: (json['options'] as List?)
                ?.map((e) => ChoiceOption.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        resendQuery: json['resend_query']?.toString() ?? '',
        ticker: json['ticker']?.toString(),
      );
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

  /// Thẻ dữ liệu inline phát kèm câu trả lời (render dưới prose).
  final List<ChatCard> cards;

  /// Popup tương tác ngược (chọn danh mục / nhập vị thế). Khi != null, bubble
  /// hiển thị nút mở popup thay cho prose trống.
  UserChoice? userChoice;

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
    List<ChatCard>? cards,
    this.userChoice,
    this.rating,
    this.isStreaming = false,
    this.hasError = false,
  })  : steps = steps ?? [],
        cards = cards ?? [];

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

  /// Có bản tin định kỳ (proactive) chưa đọc trong hội thoại này không.
  final bool hasUnread;

  ChatConversationSummary({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.hasUnread = false,
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
      hasUnread: json['has_unread'] == true,
    );
  }
}

/// Một lịch hỏi tự động (scheduled chat). Mr. Wealth tự gửi định kỳ và tạo
/// "bản tin định kỳ" trong một hội thoại mới mỗi lần chạy.
///
/// Khớp payload `/api/super-broker/schedules/`:
/// `{id, title, query, schedule, enabled, last_status}`.
class ScheduledChat {
  final int id;
  final String title;
  final String query;

  /// Mô tả lịch dễ đọc (vd "Mỗi ngày 08:00").
  final String schedule;
  final bool enabled;
  final String? lastStatus;

  ScheduledChat({
    required this.id,
    required this.title,
    required this.query,
    required this.schedule,
    required this.enabled,
    this.lastStatus,
  });

  factory ScheduledChat.fromJson(Map<String, dynamic> json) => ScheduledChat(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: (json['title'] ?? json['query'] ?? 'Lịch hỏi').toString(),
        query: json['query']?.toString() ?? '',
        schedule: json['schedule']?.toString() ?? '',
        enabled: json['enabled'] != false,
        lastStatus: json['last_status']?.toString(),
      );
}

/// Kết quả truy vấn lịch hỏi tự động (kèm trạng thái đủ điều kiện dùng).
class ScheduleListResult {
  final bool eligible;
  final int minPoints;
  final List<ScheduledChat> schedules;

  ScheduleListResult({
    required this.eligible,
    required this.minPoints,
    required this.schedules,
  });
}

/// Tóm tắt bản tin định kỳ (proactive) chưa đọc — cho badge + toast nhắc nhở.
/// Khớp payload `/api/chat/proactive/unread/`:
/// `{count, items: [{id, title}], latest_title}`.
class ProactiveUnread {
  final int count;

  /// Danh sách hội thoại có tin chưa đọc (id + tiêu đề), mới nhất trước.
  final List<({String id, String title})> items;
  final String latestTitle;

  ProactiveUnread({
    required this.count,
    required this.items,
    required this.latestTitle,
  });

  static ProactiveUnread empty() =>
      ProactiveUnread(count: 0, items: const [], latestTitle: '');

  factory ProactiveUnread.fromJson(Map<String, dynamic> json) {
    final raw = (json['items'] as List?) ?? const [];
    final items = raw
        .whereType<Map>()
        .map((e) => (
              id: e['id']?.toString() ?? '',
              title: (e['title'] ?? 'Bản tin định kỳ').toString(),
            ))
        .where((e) => e.id.isNotEmpty)
        .toList();
    return ProactiveUnread(
      count: (json['count'] as num?)?.toInt() ?? 0,
      items: items,
      latestTitle: json['latest_title']?.toString() ?? '',
    );
  }
}
