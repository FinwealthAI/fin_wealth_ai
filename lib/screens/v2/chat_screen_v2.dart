import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../models/chat_models.dart';
import '../../respositories/auth_repository.dart';
import '../../services/chat_history_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/fw_app_bar.dart';
import '../../widgets/common/fw_filter_pill.dart';

/// Bộ text-style dùng riêng cho màn chat (dark-first), tránh phụ thuộc
/// vào BuildContext khi dựng các widget con.
class _Ts {
  _Ts._();
  static const h2 = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.darkTextPrimary,
      height: 1.3);
  static const h3 = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      height: 1.4);
  static const bodyLarge = TextStyle(
      fontSize: 15, color: AppColors.darkTextPrimary, height: 1.5);
  static const bodyMedium = TextStyle(
      fontSize: 14, color: AppColors.darkTextPrimary, height: 1.5);
  static const bodySmall = TextStyle(
      fontSize: 12, color: AppColors.darkTextSecondary, height: 1.45);
  static const caption =
      TextStyle(fontSize: 11, color: AppColors.darkTextMuted);
}

const List<String> _suggestions = [
  'Phân tích cổ phiếu HPG',
  'Thị trường hôm nay thế nào?',
  'Cổ phiếu nào đang có tín hiệu mua?',
  'Đánh giá danh mục đầu tư của tôi',
];

/// Màn hình Chat V3 — bám pipeline Agent V2 của web finwealth.
class ChatScreenV2 extends StatefulWidget {
  final String? initialTicker;
  const ChatScreenV2({super.key, this.initialTicker});

  @override
  State<ChatScreenV2> createState() => _ChatScreenV2State();
}

class _ChatScreenV2State extends State<ChatScreenV2> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late final AuthRepository _authRepo = context.read<AuthRepository>();

  final List<ChatMessage> _messages = [];
  List<String> _validTickers = const [];

  String? _conversationId;
  String? _currentTaskId;
  ChatMode _mode = ChatMode.flash;
  bool _isTyping = false;
  bool _loadingHistory = false;
  bool _showScrollToBottom = false;

  StreamSubscription<Map<String, dynamic>>? _sub;

  bool get isGuest => _authRepo.accessToken == null;
  String get _username => _authRepo.username ?? '';
  String? get _token => _authRepo.accessToken;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    if (!isGuest) {
      _initConversation();
      ChatHistoryService.getValidTickers(token: _token).then((t) {
        if (mounted) _validTickers = t;
      });
    }
    if (widget.initialTicker != null) {
      _input.text = 'Phân tích ${widget.initialTicker}';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  Future<void> _initConversation() async {
    setState(() => _loadingHistory = true);
    try {
      final convId = await ChatHistoryService.getOrCreateConversationId(
        _username,
        token: _token,
      );
      _conversationId = convId.isEmpty ? null : convId;
      if (_conversationId != null) {
        await _loadHistory(_conversationId!);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
      _scrollToBottom();
    }
  }

  Future<void> _loadHistory(String conversationId) async {
    final history = await ChatHistoryService.loadChatHistory(
      conversationId: conversationId,
      token: _token,
    );
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(history.map(ChatMessage.history));
    });
  }

  String? _detectTicker(String query) {
    if (_validTickers.isEmpty) return null;
    final set = _validTickers.toSet();
    for (final match in RegExp(r'\b[A-Za-z]{3}\b').allMatches(query)) {
      final t = match.group(0)!.toUpperCase();
      if (set.contains(t)) return t;
    }
    return null;
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _isTyping) return;
    if (isGuest) {
      _showLoginPrompt();
      return;
    }

    final ticker = _detectTicker(text);
    final mode = _mode;

    final assistant =
        ChatMessage(fromUser: false, mode: mode, isStreaming: true);
    setState(() {
      _messages.add(ChatMessage(fromUser: true, text: text, ticker: ticker));
      _messages.add(assistant);
      _isTyping = true;
    });
    _input.clear();
    _scrollToBottom();

    final inputs = <String, dynamic>{
      if (ticker != null) 'ticker': ticker,
    };

    try {
      final stream = ChatHistoryService.streamMessage(
        message: text,
        conversationId: _conversationId,
        mode: mode,
        inputs: inputs,
        token: _token,
      );

      final completer = Completer<void>();
      _sub = stream.listen(
        (event) => _handleEvent(event, assistant),
        onError: (e) {
          assistant
            ..text = assistant.text.isEmpty
                ? '❌ Lỗi khi gửi tin nhắn: $e'
                : assistant.text
            ..hasError = true;
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );
      await completer.future;

      if (assistant.text.isEmpty && !assistant.hasError) {
        assistant.text = 'Không nhận được phản hồi từ server.';
      }
    } catch (e) {
      assistant
        ..text = '❌ Lỗi khi gửi tin nhắn: $e'
        ..hasError = true;
    } finally {
      await _sub?.cancel();
      _sub = null;
      if (mounted) {
        setState(() {
          assistant.isStreaming = false;
          _isTyping = false;
        });
      }
      _scrollToBottom();
    }
  }

  void _handleEvent(Map<String, dynamic> event, ChatMessage assistant) {
    final type = event['type']?.toString();

    if (type == '__done__') return;

    if (event['conversation_id'] != null) {
      final id = event['conversation_id'].toString();
      _conversationId = id;
      ChatHistoryService.saveConversationId(_username, id);
    }
    if (event['task_id'] != null) {
      _currentTaskId = event['task_id'].toString();
    }
    if (event['message_id'] != null) {
      assistant.id = event['message_id'].toString();
    }

    switch (type) {
      case 'classify':
        setState(() => assistant.classify = ClassifyEvent.fromJson(event));
        return;
      case 'agent_start':
        setState(() => assistant.steps.add(AgentStep.fromStart(event)));
        return;
      case 'agent_done':
      case 'agent_cached':
        final roleId = event['role_id']?.toString();
        final step = _findStep(assistant, roleId);
        if (step != null) setState(() => step.applyDone(event));
        return;
      case 'agent_error':
        final roleId = event['role_id']?.toString();
        final step = _findStep(assistant, roleId);
        if (step != null) {
          setState(() => step.applyError(event));
        }
        return;
    }

    if (event['answer'] != null) {
      setState(() => assistant.text += event['answer'].toString());
      _followStream();
    }
  }

  AgentStep? _findStep(ChatMessage m, String? roleId) {
    if (roleId == null) return m.steps.isNotEmpty ? m.steps.last : null;
    for (final s in m.steps) {
      if (s.roleId == roleId) return s;
    }
    return null;
  }

  Future<void> _stop() async {
    setState(() => _isTyping = false);
    await _sub?.cancel();
    _sub = null;
    final taskId = _currentTaskId;
    if (taskId == null) return;
    try {
      await ChatHistoryService.stopGenerate(taskId: taskId, token: _token);
    } catch (_) {}
  }

  Future<void> _newConversation() async {
    await ChatHistoryService.clearSavedConversationId(_username);
    setState(() {
      _messages.clear();
      _conversationId = null;
    });
  }

  Future<void> _openConversation(ChatConversationSummary c) async {
    Navigator.of(context).maybePop();
    setState(() {
      _loadingHistory = true;
      _conversationId = c.id;
    });
    await ChatHistoryService.saveConversationId(_username, c.id);
    try {
      await _loadHistory(c.id);
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendRating(ChatMessage m, String rating) async {
    if (m.id == null || m.rating != null) return;
    setState(() => m.rating = rating);
    try {
      await ChatHistoryService.sendFeedback(
        messageId: m.id!,
        rating: rating,
        token: _token,
      );
    } catch (_) {
      if (mounted) setState(() => m.rating = null);
    }
  }

  // ---------------------------------------------------------------------------
  // Scroll
  // ---------------------------------------------------------------------------

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final show = _scroll.offset < _scroll.position.maxScrollExtent - 200;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }
  }

  /// Bám đáy khi gửi/mở hội thoại (có animation cho mượt).
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 60), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Bám đáy theo từng chunk text khi đang stream — nhảy ngay (không animation
  /// chồng nhau) để theo kịp tốc độ token. Chỉ tự cuộn nếu người dùng đang ở
  /// gần đáy; nếu họ kéo lên đọc thì tôn trọng vị trí hiện tại.
  void _followStream() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final atBottom = pos.maxScrollExtent - pos.pixels < 120;
    if (!atBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      endDrawer: isGuest ? null : _buildConversationsDrawer(),
      appBar: FwAppBar(
        title: 'Mr.Wealth',
        subtitle: 'AI Cố vấn đầu tư',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: isGuest ? null : _newConversation,
          ),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Lịch sử trò chuyện',
              onPressed:
                  isGuest ? null : () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _loadingHistory
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? _buildWelcome()
                        : _buildMessages(),
              ),
              _buildComposer(),
            ],
          ),
          if (_showScrollToBottom)
            Positioned(
              right: AppSpacing.lg,
              bottom: 96,
              child: FloatingActionButton.small(
                // Khi bot đang trả lời và người dùng cuộn lên: nút nổi bật
                // để báo có nội dung mới; bấm vào sẽ bám đáy trở lại.
                backgroundColor: _isTyping
                    ? AppColors.brandPrimary
                    : AppColors.darkSurfaceElevated,
                shape: _isTyping
                    ? const CircleBorder(
                        side: BorderSide(
                            color: AppColors.brandPrimaryDark, width: 2))
                    : null,
                onPressed: _scrollToBottom,
                child: Icon(
                  _isTyping
                      ? Icons.keyboard_double_arrow_down
                      : Icons.arrow_downward,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Welcome -------------------------------------------------------------

  Widget _buildWelcome() {
    final name = _username;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.brandPrimary, AppColors.brandSecondary],
              ),
              boxShadow: AppShadows.purpleGlow,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isGuest
                ? 'Đăng nhập để bắt đầu trò chuyện'
                : 'Xin chào${name.isNotEmpty ? ', $name' : ''}!',
            style: _Ts.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isGuest
                ? 'Đăng nhập để sử dụng Mr.Wealth'
                : 'Bạn cần phân tích gì hôm nay?',
            style: _Ts.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
            textAlign: TextAlign.center,
          ),
          if (!isGuest) ...[
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: _suggestions
                  .map((s) => FwFilterPill(
                        label: s,
                        icon: Icons.bolt,
                        active: false,
                        onTap: () => _send(s),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // --- Messages ------------------------------------------------------------

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(ChatMessage m) {
    if (m.fromUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  m.text,
                  style: _Ts.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Khối tiến trình agent chỉ hiện khi đang stream; ẩn khi xong.
                if (m.isStreaming && (m.classify != null || m.steps.isNotEmpty))
                  _buildStepsPanel(m),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: (m.text.isEmpty && m.isStreaming)
                      ? const _TypingDots()
                      : _buildRichText(m.text.isEmpty ? '...' : m.text),
                ),
                if (!m.isStreaming && m.text.isNotEmpty && !m.hasError)
                  _buildMessageActions(m),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsPanel(ChatMessage m) {
    final classify = m.classify;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (classify != null)
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 14, color: AppColors.brandPrimaryDark),
                const SizedBox(width: AppSpacing.xs),
                if (classify.ticker.isNotEmpty) ...[
                  Text(classify.ticker,
                      style: _Ts.bodySmall.copyWith(
                          color: AppColors.darkTextPrimary,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: AppSpacing.xs),
                ],
                _modeBadge(classify.mode),
                if (classify.intent.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      classify.intent,
                      overflow: TextOverflow.ellipsis,
                      style: _Ts.caption,
                    ),
                  ),
                ],
              ],
            ),
          ...m.steps.map(_buildStepRow),
        ],
      ),
    );
  }

  Widget _buildStepRow(AgentStep s) {
    Widget leading;
    switch (s.status) {
      case AgentStepStatus.running:
        leading = const _TypingDots(dotSize: 4, color: AppColors.brandPrimaryDark);
        break;
      case AgentStepStatus.error:
        leading =
            const Icon(Icons.error_outline, size: 14, color: AppColors.danger);
        break;
      default:
        leading =
            const Icon(Icons.check_circle, size: 14, color: AppColors.success);
    }

    final trailing = s.status == AgentStepStatus.error
        ? (s.error ?? 'lỗi')
        : s.status == AgentStepStatus.running
            ? 'đang chạy...'
            : (s.status == AgentStepStatus.cached
                ? 'đã lưu'
                : '${s.elapsedMs}ms');

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              s.label,
              overflow: TextOverflow.ellipsis,
              style:
                  _Ts.bodySmall.copyWith(color: AppColors.darkTextSecondary),
            ),
          ),
          Text(trailing, style: _Ts.caption),
        ],
      ),
    );
  }

  Widget _modeBadge(ChatMode mode) {
    final isPro = mode == ChatMode.pro;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 1),
      decoration: BoxDecoration(
        color: (isPro ? AppColors.brandPrimary : AppColors.brandSecondary)
            .withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        mode.label.toUpperCase(),
        style: _Ts.caption.copyWith(
          color:
              isPro ? AppColors.brandPrimaryDark : AppColors.brandSecondaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMessageActions(ChatMessage m) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          _actionIcon(Icons.copy, 'Sao chép', () {
            Clipboard.setData(ClipboardData(text: m.text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Đã sao chép'),
                  duration: Duration(seconds: 1)),
            );
          }),
          _actionIcon(
            m.rating == 'like' ? Icons.thumb_up : Icons.thumb_up_outlined,
            'Hữu ích',
            () => _sendRating(m, 'like'),
            active: m.rating == 'like',
          ),
          _actionIcon(
            m.rating == 'dislike'
                ? Icons.thumb_down
                : Icons.thumb_down_outlined,
            'Chưa tốt',
            () => _sendRating(m, 'dislike'),
            active: m.rating == 'dislike',
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, String tooltip, VoidCallback onTap,
      {bool active = false}) {
    return IconButton(
      icon: Icon(icon, size: 16),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      color: active ? AppColors.brandPrimaryDark : AppColors.darkTextMuted,
      onPressed: onTap,
    );
  }

  Widget _buildAvatar() {
    return const CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.brandPrimary,
      backgroundImage: AssetImage('assets/images/mr_wealth_avatar.png'),
    );
  }

  MarkdownStyleSheet _markdownStyle() {
    return MarkdownStyleSheet(
      p: _Ts.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
      h1: _Ts.h2,
      h2: _Ts.h3,
      h3: _Ts.bodyLarge,
      code: _Ts.bodySmall.copyWith(
        backgroundColor: AppColors.darkSurface,
        fontFamily: 'monospace',
      ),
      blockquote:
          _Ts.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
    );
  }

  Widget _buildRichText(String text) {
    return MarkdownBody(
      data: text,
      selectable: true,
      styleSheet: _markdownStyle(),
      builders: {
        'table': _ScrollableTableBuilder(),
      },
      onTapLink: (text, href, title) {
        if (href != null) {
          final uri = Uri.tryParse(href);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
    );
  }

  // --- Composer ------------------------------------------------------------

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isGuest)
              Align(
                alignment: Alignment.centerLeft,
                child: _modeToggle(),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !_isTyping,
                    style: _Ts.bodyMedium
                        .copyWith(color: AppColors.darkTextPrimary),
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: isGuest
                          ? 'Đăng nhập để bắt đầu...'
                          : 'Nhập câu hỏi về cổ phiếu...',
                      hintStyle: _Ts.bodyMedium
                          .copyWith(color: AppColors.darkTextMuted),
                      filled: true,
                      fillColor: AppColors.darkSurfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildSendButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeToggle() {
    Widget seg(ChatMode mode) {
      final active = _mode == mode;
      return GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.brandPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                mode == ChatMode.pro ? Icons.workspace_premium : Icons.bolt,
                size: 14,
                color: active ? Colors.white : AppColors.darkTextSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                mode.label,
                style: _Ts.bodySmall.copyWith(
                  color: active ? Colors.white : AppColors.darkTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg(ChatMode.flash), seg(ChatMode.pro)],
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _isTyping ? _stop : _send,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.brandPrimary, AppColors.brandSecondary],
          ),
        ),
        child: Icon(
          _isTyping ? Icons.stop : Icons.send,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // --- Conversations drawer -------------------------------------------------

  Widget _buildConversationsDrawer() {
    return Drawer(
      backgroundColor: AppColors.darkSurface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Lịch sử trò chuyện', style: _Ts.h3),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).maybePop();
                      _newConversation();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Mới'),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.darkBorder, height: 1),
            Expanded(
              child: FutureBuilder<List<ChatConversationSummary>>(
                future: ChatHistoryService.listConversations(token: _token),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final convs = snap.data ?? const [];
                  if (convs.isEmpty) {
                    return const Center(
                      child: Text('Chưa có cuộc trò chuyện nào',
                          style: _Ts.bodySmall),
                    );
                  }
                  return ListView.builder(
                    itemCount: convs.length,
                    itemBuilder: (context, i) {
                      final c = convs[i];
                      final selected = c.id == _conversationId;
                      return ListTile(
                        selected: selected,
                        selectedTileColor: AppColors.darkSurfaceElevated,
                        leading: const Icon(Icons.chat_bubble_outline,
                            size: 18, color: AppColors.darkTextSecondary),
                        title: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _Ts.bodyMedium,
                        ),
                        onTap: () => _openConversation(c),
                        trailing: PopupMenuButton<String>(
                          color: AppColors.darkSurfaceElevated,
                          icon: const Icon(Icons.more_vert,
                              size: 18, color: AppColors.darkTextMuted),
                          onSelected: (v) {
                            if (v == 'rename') _renameDialog(c);
                            if (v == 'delete') _deleteConversation(c);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'rename', child: Text('Đổi tên')),
                            PopupMenuItem(value: 'delete', child: Text('Xóa')),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameDialog(ChatConversationSummary c) async {
    final controller = TextEditingController(text: c.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Đổi tên', style: _Ts.h3),
        content: TextField(
          controller: controller,
          style: _Ts.bodyMedium,
          decoration: const InputDecoration(hintText: 'Tên cuộc trò chuyện'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      try {
        await ChatHistoryService.renameConversation(c.id, name, token: _token);
      } catch (_) {}
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteConversation(ChatConversationSummary c) async {
    try {
      await ChatHistoryService.deleteConversation(c.id, token: _token);
    } catch (_) {}
    if (c.id == _conversationId) {
      await ChatHistoryService.clearSavedConversationId(_username);
      if (mounted) {
        setState(() {
          _messages.clear();
          _conversationId = null;
        });
      }
    } else if (mounted) {
      setState(() {});
    }
  }

  // --- Misc ----------------------------------------------------------------

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Đăng nhập', style: _Ts.h3),
        content: Text(
          'Vui lòng đăng nhập để sử dụng tính năng này.',
          style: _Ts.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login-v2');
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }
}

/// Render bảng markdown thành khối CUỘN NGANG (giống cách Claude/ChatGPT/Gemini
/// hiển thị bảng trên mobile) — cột giữ độ rộng tự nhiên, không bị bóp vỡ chữ.
class _ScrollableTableBuilder extends MarkdownElementBuilder {
  static const _headerStyle = TextStyle(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextPrimary,
  );
  static const _cellStyle = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: AppColors.darkTextSecondary,
  );

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final rows = <List<_TableCell>>[];

    for (final section in element.children!.whereType<md.Element>()) {
      final isHead = section.tag == 'thead';
      for (final row in section.children!.whereType<md.Element>()) {
        if (row.tag != 'tr') continue;
        final cells = <_TableCell>[];
        for (final cell in row.children!.whereType<md.Element>()) {
          cells.add(_TableCell(
            cell.textContent.trim(),
            isHead || cell.tag == 'th',
          ));
        }
        if (cells.isNotEmpty) rows.add(cells);
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    Widget buildCell(_TableCell c) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56, maxWidth: 220),
            child: Text(c.text, style: c.header ? _headerStyle : _cellStyle),
          ),
        );

    final tableRows = <TableRow>[];
    for (var i = 0; i < rows.length; i++) {
      final isHeaderRow = rows[i].every((c) => c.header);
      tableRows.add(TableRow(
        decoration: BoxDecoration(
          color: isHeaderRow
              ? AppColors.darkSurface
              : (i.isEven
                  ? AppColors.darkSurfaceElevated
                  : Colors.transparent),
        ),
        children: rows[i].map(buildCell).toList(),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.darkBorder),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          clipBehavior: Clip.antiAlias,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: const TableBorder.symmetric(
              inside: BorderSide(color: AppColors.darkBorder),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: tableRows,
          ),
        ),
      ),
    );
  }
}

class _TableCell {
  final String text;
  final bool header;
  const _TableCell(this.text, this.header);
}

/// Hiệu ứng "đang gõ" — 3 chấm nhấp nháy lần lượt (giống web).
class _TypingDots extends StatefulWidget {
  final double dotSize;
  final Color color;
  const _TypingDots({this.dotSize = 7, this.color = AppColors.darkTextMuted});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            // Mỗi chấm lệch pha 1/3 chu kỳ.
            final t = (_ctrl.value - i * 0.2) % 1.0;
            final opacity = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? widget.dotSize * 0.6 : 0),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
