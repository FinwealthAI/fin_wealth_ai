class ChatMessage {
  final String? id; // Message ID from backend (for feedback)
  final String? query; // User question
  final String? answer; // Bot answer
  final String role; // 'user' or 'bot'
  final DateTime? timestamp;
  final String? conversationId;
  final String? avatarUrl; // Custom avatar URL if provided

  ChatMessage({
    this.id,
    this.query,
    this.answer,
    required this.role,
    this.timestamp,
    this.conversationId,
    this.avatarUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      query: json['query'] as String?,
      answer: json['answer'] as String?,
      role: json['role'] as String? ?? 'user', // Default to user if unknown, though 'bot' context implies answer
      timestamp: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : DateTime.now(),
      conversationId: json['conversation_id'] as String?,
      avatarUrl: json['avatar_url'] as String?, // Ensure backend sends this or client sets it
    );
  }

  ChatMessage copyWith({
    String? id,
    String? query,
    String? answer,
    String? role,
    DateTime? timestamp,
    String? conversationId,
    String? avatarUrl,
    String? text, // Temporary helper to match usage in screen
  }) {
    return ChatMessage(
      id: id ?? this.id,
      query: query ?? this.query,
      answer: text ?? answer ?? this.answer,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      conversationId: conversationId ?? this.conversationId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  /// Convenience getter for display text depending on role
  String get content => role == 'user' ? (query ?? '') : (answer ?? '');
}

class ChatFeedback {
  final String messageId;
  final String rating; // 'like' or 'dislike'

  ChatFeedback({required this.messageId, required this.rating});

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'rating': rating,
    };
  }
}
