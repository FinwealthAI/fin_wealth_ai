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
import '../../services/onboarding_prefs.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/chat/chat_card_widget.dart';
import '../../widgets/common/fw_app_bar.dart';
import '../../widgets/common/fw_filter_pill.dart';
import '../../widgets/onboarding/onboarding.dart';
import '../investment_profile_screen.dart';
import 'stock_detail_screen_v2.dart';

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

  /// Khi mở từ luồng onboarding hợp nhất (sau tour app) → chạy thẳng tour chat
  /// (không hiện welcome dialog), kết thúc thì đánh dấu đã xem hướng dẫn.
  final bool runTourOnOpen;

  const ChatScreenV2({
    super.key,
    this.initialTicker,
    this.runTourOnOpen = false,
  });

  @override
  State<ChatScreenV2> createState() => _ChatScreenV2State();
}

class _ChatScreenV2State extends State<ChatScreenV2> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late final AuthRepository _authRepo = context.read<AuthRepository>();

  // GlobalKeys cho tour hướng dẫn lần đầu (coach-mark spotlight).
  final GlobalKey _kSuggest = GlobalKey();
  final GlobalKey _kInput = GlobalKey();
  final GlobalKey _kMode = GlobalKey();
  final GlobalKey _kNewChat = GlobalKey();
  final GlobalKey _kSchedule = GlobalKey();
  final GlobalKey _kHistory = GlobalKey();

  /// Đang chạy onboarding rồi → tránh kích hoạt lần hai.
  bool _onboardingStarted = false;

  final List<ChatMessage> _messages = [];
  List<String> _validTickers = const [];

  String? _conversationId;
  String? _currentTaskId;
  ChatMode _mode = ChatMode.flash;
  bool _isTyping = false;
  bool _loadingHistory = false;
  bool _showScrollToBottom = false;

  /// Hội thoại đã chạm giới hạn (sự kiện `limit_reached`) → khóa khung nhập.
  bool _chatLocked = false;

  /// Sắp chạm giới hạn (sự kiện `soft_warning`) → hiện banner nhắc nhở.
  bool _softWarning = false;

  /// Hồ sơ đầu tư đã điền đủ chưa (null = chưa rõ). Dùng để nhắc bổ sung ở
  /// màn welcome. `false` → hiện prompt "Điền hồ sơ".
  bool? _profileComplete;

  /// User bấm "Để sau" trong phiên/cuộc hiện tại → ẩn prompt. Reset khi mở
  /// cuộc trò chuyện mới (nhắc lại).
  bool _profilePromptDismissed = false;

  /// User đủ điều kiện dùng "Lịch hỏi tự động" (đủ điểm) → hiện nút lịch.
  bool _scheduleEligible = false;

  /// Số bản tin định kỳ (proactive) chưa đọc → badge trên nút lịch sử + toast.
  int _proactiveUnread = 0;

  /// Toast nhắc bản tin định kỳ chỉ hiện 1 lần mỗi lần vào màn.
  bool _proactiveToastShown = false;

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
      _checkProfile();
      _loadScheduleEligibility();
      _refreshProactive(showToast: true);
      ChatHistoryService.getValidTickers(token: _token).then((t) {
        if (mounted) _validTickers = t;
      });
      // Tour chat CHỈ chạy khi đến từ luồng onboarding hợp nhất (sau tour app).
      if (widget.runTourOnOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startChatTour());
      }
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

  /// Phần CHAT của luồng hướng dẫn hợp nhất: tour spotlight các nút chính của
  /// màn Mr.Wealth. Vào thẳng (không welcome dialog) vì luồng app đã chào ở
  /// bước trước. Kết thúc/bỏ qua → đánh dấu đã xem (cờ chung 1 lần/đời).
  Future<void> _startChatTour() async {
    if (_onboardingStarted || isGuest || !mounted) return;
    _onboardingStarted = true;

    // Đợi hết frame để chắc chắn các widget mục tiêu đã layout xong.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final steps = <CoachStep>[
      CoachStep(_kSuggest, '✨ Bắt đầu chỉ với 1 chạm',
          'Chưa biết hỏi gì? Chạm một gợi ý để xem ngay Mr.Wealth làm được gì cho bạn.'),
      CoachStep(_kInput, '💬 Hỏi bất cứ điều gì về đầu tư',
          'Gõ câu hỏi như đang nhắn tin: "FPT có nên mua?", "Vĩ mô tuần này ra sao?". Mr.Wealth phân tích kèm số liệu — chờ vài chục giây để có câu trả lời chắc tay.'),
      CoachStep(_kMode, '⚡ Chọn độ sâu phân tích',
          'Flash trả lời nhanh cho câu hỏi thường ngày; Pro phân tích sâu hơn cho quyết định quan trọng.'),
      CoachStep(_kNewChat, '🆕 Cuộc trò chuyện mới',
          'Bắt đầu chủ đề mới để câu trả lời luôn tập trung và chất lượng.',
          circle: true),
      CoachStep(_kSchedule, '⏰ Để Mr.Wealth làm việc khi bạn bận',
          'Đặt lịch hỏi định kỳ — ví dụ mỗi sáng tự gửi tóm tắt thị trường hay rà soát danh mục. Cơ hội & rủi ro tự tìm đến bạn.',
          circle: true),
      CoachStep(_kHistory, '🕑 Xem lại mọi hội thoại',
          'Tất cả phân tích đều được lưu lại để bạn mở lại và đối chiếu bất cứ lúc nào.',
          circle: true),
    ];

    runCoachMarks(context, steps,
        onDone: (_) => OnboardingPrefs.markSeen(_username));
  }

  /// Lấy trạng thái hồ sơ để quyết định có nhắc bổ sung không.
  Future<void> _checkProfile() async {
    final complete =
        await ChatHistoryService.hasCompleteProfile(token: _token);
    if (mounted) setState(() => _profileComplete = complete);
  }

  /// Mở màn điền hồ sơ; điền xong (pop true) → kiểm tra lại để ẩn prompt.
  Future<void> _openProfile() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const InvestmentProfileScreen()),
    );
    if (result == true) {
      await _checkProfile();
    }
  }

  Future<void> _loadHistory(String conversationId) async {
    final history = await ChatHistoryService.loadChatHistory(
      conversationId: conversationId,
      token: _token,
      // Mở cuộc = đã xem → đánh dấu bản tin định kỳ trong cuộc là đã đọc.
      markRead: true,
    );
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(history.messages.map(ChatMessage.history));
      _chatLocked = history.limitStatus == 'locked';
      _softWarning = history.limitStatus == 'warning';
    });
    // Vừa đánh dấu đã đọc → cập nhật lại badge.
    _refreshProactive();
  }

  /// Kiểm tra user có đủ điểm dùng "Lịch hỏi tự động" không → hiện nút lịch.
  Future<void> _loadScheduleEligibility() async {
    final result = await ChatHistoryService.listSchedules(token: _token);
    if (mounted) setState(() => _scheduleEligible = result.eligible);
  }

  /// Cập nhật số bản tin định kỳ chưa đọc; tùy chọn hiện toast nhắc nhở 1 lần.
  Future<void> _refreshProactive({bool showToast = false}) async {
    final data = await ChatHistoryService.fetchProactiveUnread(token: _token);
    if (!mounted) return;
    setState(() => _proactiveUnread = data.count);
    if (showToast && data.count > 0 && !_proactiveToastShown) {
      _proactiveToastShown = true;
      _showProactiveToast(data);
    }
  }

  /// Toast nhắc có bản tin định kỳ mới — bấm "Xem" mở hội thoại mới nhất.
  void _showProactiveToast(ProactiveUnread data) {
    final title = data.count > 1
        ? 'Bạn có ${data.count} bản tin định kỳ mới từ Mr. Wealth'
        : 'Mr. Wealth có bản tin định kỳ mới cho bạn';
    final targetId = data.items.isNotEmpty ? data.items.first.id : null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.darkSurfaceElevated,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.event_available,
                size: 20, color: AppColors.brandPrimaryDark),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: _Ts.bodySmall
                          .copyWith(color: AppColors.darkTextPrimary)),
                  if (data.latestTitle.isNotEmpty)
                    Text(data.latestTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _Ts.caption),
                ],
              ),
            ),
          ],
        ),
        action: targetId != null
            ? SnackBarAction(
                label: 'Xem',
                textColor: AppColors.brandPrimaryDark,
                onPressed: () => _openConversationById(targetId),
              )
            : null,
      ),
    );
  }

  /// Mở một hội thoại theo id (dùng cho toast bản tin định kỳ).
  Future<void> _openConversationById(String id) async {
    setState(() {
      _loadingHistory = true;
      _conversationId = id;
      _chatLocked = false;
      _softWarning = false;
    });
    await ChatHistoryService.saveConversationId(_username, id);
    try {
      await _loadHistory(id);
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
      _scrollToBottom();
    }
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

  /// Gửi câu hỏi. `extraInputs` dùng khi GỬI LẠI sau popup user_choice
  /// (vd kèm `profile_id` của danh mục vừa chọn).
  Future<void> _send([String? preset, Map<String, dynamic>? extraInputs]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _isTyping) return;
    if (isGuest) {
      _showLoginPrompt();
      return;
    }
    if (_chatLocked) return;

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
      ...?extraInputs,
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

      // Không báo "trống" nếu lượt này kết thúc bằng popup user_choice hoặc đã
      // hiển thị thẻ dữ liệu (cards) — đó là phản hồi hợp lệ, chỉ không có prose.
      if (assistant.text.isEmpty &&
          !assistant.hasError &&
          assistant.userChoice == null &&
          assistant.cards.isEmpty) {
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
      case 'skill_loaded':
        final step = _findStep(assistant, event['agent_id']?.toString());
        if (step != null) {
          setState(() => step.skills.add(AgentSkill.fromJson(event)));
        }
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
      case 'card':
        setState(() => assistant.cards.add(ChatCard.fromJson(event)));
        _followStream();
        return;
      case 'user_choice':
        // Popup tương tác ngược — backend kết thúc stream ngay sau sự kiện này.
        setState(() => assistant.userChoice = UserChoice.fromJson(event));
        return;
      case 'limit_reached':
        setState(() {
          _chatLocked = true;
          if (assistant.text.isEmpty) {
            assistant
              ..text =
                  'Cuộc trò chuyện đã đạt giới hạn. Hãy bắt đầu cuộc trò chuyện mới để tiếp tục.'
              ..hasError = true;
          }
        });
        return;
      case 'soft_warning':
        setState(() => _softWarning = true);
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
      _chatLocked = false;
      _softWarning = false;
      // Mở cuộc mới → nhắc lại hồ sơ (nếu vẫn chưa điền).
      _profilePromptDismissed = false;
    });
    _checkProfile();
  }

  Future<void> _openConversation(ChatConversationSummary c) async {
    Navigator.of(context).maybePop();
    setState(() {
      _loadingHistory = true;
      _conversationId = c.id;
      _chatLocked = false;
      _softWarning = false;
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
          if (!isGuest && _scheduleEligible)
            IconButton(
              key: _kSchedule,
              icon: const Icon(Icons.event_available_outlined),
              tooltip: 'Lịch hỏi tự động',
              color: AppColors.success,
              onPressed: _openScheduleSheet,
            ),
          IconButton(
            key: _kNewChat,
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: isGuest ? null : _newConversation,
          ),
          Builder(
            builder: (ctx) => IconButton(
              key: _kHistory,
              icon: _withBadge(const Icon(Icons.history), _proactiveUnread),
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
          if (!isGuest &&
              _profileComplete == false &&
              !_profilePromptDismissed) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildProfilePrompt(),
          ],
          if (!isGuest) ...[
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              key: _kSuggest,
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

  /// Card nhắc bổ sung hồ sơ (giống banner "Tùy chỉnh trợ lý AI" của web).
  /// Hiện ở welcome khi user chưa có hồ sơ; nhắc lại mỗi lần mở cuộc mới.
  Widget _buildProfilePrompt() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandPrimary.withValues(alpha: 0.18),
            AppColors.brandSecondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline,
                  color: AppColors.brandPrimaryDark, size: 20),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Tùy chỉnh trợ lý AI',
                    style: TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Hãy cho Mr.Wealth biết thêm về khẩu vị đầu tư của bạn để được tư vấn phù hợp hơn.',
            style: _Ts.bodySmall.copyWith(color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Điền hồ sơ'),
                onPressed: _openProfile,
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () =>
                    setState(() => _profilePromptDismissed = true),
                child: const Text('Để sau'),
              ),
            ],
          ),
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
      itemBuilder: (context, i) {
        final m = _messages[i];
        // Bản tin định kỳ (proactive): gộp câu hỏi (tin user) + câu trả lời
        // thành 1 card duy nhất — KHỚP web (addNewsletterCard).
        if (m.isProactive) {
          if (m.fromUser) return const SizedBox.shrink(); // gộp vào card dưới
          final query = (i - 1 >= 0 &&
                  _messages[i - 1].fromUser &&
                  _messages[i - 1].isProactive)
              ? _messages[i - 1].text
              : '';
          return _buildNewsletterCard(m, query);
        }
        return _buildBubble(m);
      },
    );
  }

  /// Card "bản tin định kỳ" — Mr. Wealth tự gửi theo lịch / digest. Gộp câu hỏi
  /// + câu trả lời, viền nhấn xanh, badge "Tự động" (khớp web newsletter card).
  Widget _buildNewsletterCard(ChatMessage m, String query) {
    final (label, icon) = _newsletterMeta(query);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.success.withValues(alpha: 0.14),
              AppColors.darkSurfaceElevated,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.successDark.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon + nhãn loại bản tin + badge "Tự động".
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: AppColors.successDark.withValues(alpha: 0.18)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: AppColors.successDark),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$label · Mr. Wealth',
                            style: _Ts.bodySmall.copyWith(
                                color: AppColors.successDark,
                                fontWeight: FontWeight.w700)),
                        if (query.isNotEmpty)
                          Text('"$query"',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _Ts.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt,
                            size: 11, color: AppColors.successDark),
                        const SizedBox(width: 3),
                        Text('Tự động',
                            style: _Ts.caption
                                .copyWith(color: AppColors.successDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Body: nội dung bản tin.
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildRichText(m.text.isEmpty ? '...' : m.text),
            ),
            // Feedback actions (giống tin thường).
            if (!m.hasError && m.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    bottom: AppSpacing.xs),
                child: _buildMessageActions(m),
              ),
          ],
        ),
      ),
    );
  }

  /// Suy ra nhãn + icon loại bản tin từ nội dung câu hỏi (khớp web getNewsletterMeta).
  (String, IconData) _newsletterMeta(String query) {
    final q = query.toLowerCase();
    if (q.contains('danh mục')) {
      return ('Tác động danh mục', Icons.show_chart);
    }
    if (q.contains('chuỗi') || q.contains('tác động')) {
      return ('Phân tích chuỗi giá trị', Icons.account_tree_outlined);
    }
    return ('Bản tin định kỳ', Icons.event_available);
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
                // Bong bóng prose — ẩn nếu chỉ có popup user_choice (không prose).
                if (m.text.isNotEmpty ||
                    (m.isStreaming && m.userChoice == null))
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
                // Thẻ dữ liệu inline (stock/action/market/...).
                if (m.cards.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ...m.cards.map((c) => ChatCardWidget(card: c)),
                ],
                // Popup tương tác ngược (chọn danh mục / nhập vị thế).
                if (m.userChoice != null) _buildChoice(m),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  s.label,
                  overflow: TextOverflow.ellipsis,
                  style: _Ts.bodySmall
                      .copyWith(color: AppColors.darkTextSecondary),
                ),
              ),
              Text(trailing, style: _Ts.caption),
            ],
          ),
          // Skill đã nạp trong bước này (sự kiện skill_loaded).
          ...s.skills.map((sk) => Padding(
                padding: const EdgeInsets.only(left: 22, top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.bolt,
                        size: 11, color: AppColors.brandPrimaryDark),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        sk.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: _Ts.caption,
                      ),
                    ),
                  ],
                ),
              )),
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

  // --- user_choice popup -----------------------------------------------------

  /// Khối nút inline cho sự kiện `user_choice` (chọn danh mục / nhập vị thế).
  Widget _buildChoice(ChatMessage m) {
    final uc = m.userChoice!;
    final isPosition = uc.choiceKey == 'input_position';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRichText(uc.prompt),
          const SizedBox(height: AppSpacing.sm),
          if (isPosition)
            // Mobile chưa quản lý vị thế margin → điều hướng sang chi tiết mã.
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text('Mở chi tiết ${uc.ticker ?? ''}'.trim()),
              onPressed: () => _openTickerDetail(uc.ticker),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary),
              icon: const Icon(Icons.folder_open, size: 16),
              label: const Text('Chọn danh mục'),
              onPressed: () => _openChoicePopup(m, uc),
            ),
        ],
      ),
    );
  }

  void _openTickerDetail(String? ticker) {
    final t = (ticker ?? '').toUpperCase();
    if (t.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StockDetailScreenV2(ticker: t)),
    );
  }

  Future<void> _openChoicePopup(ChatMessage m, UserChoice uc) async {
    final selected = await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(uc.prompt, style: _Ts.h3),
            ),
            const Divider(color: AppColors.darkBorder, height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: uc.options
                    .map((o) => ListTile(
                          leading: const Icon(Icons.account_balance_wallet,
                              size: 20, color: AppColors.brandPrimaryDark),
                          title: Text(o.label, style: _Ts.bodyMedium),
                          subtitle: o.sublabel != null
                              ? Text(o.sublabel!, style: _Ts.bodySmall)
                              : null,
                          onTap: () => Navigator.pop(context, o.value),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    _resendAfterChoice(m, uc, {'profile_id': selected});
  }

  /// Sau khi chọn: gỡ cặp tin nhắn (user + assistant) của lượt hỏi này rồi gửi
  /// lại câu hỏi gốc kèm `extraInputs` (giống web).
  void _resendAfterChoice(
      ChatMessage m, UserChoice uc, Map<String, dynamic> extraInputs) {
    final idx = _messages.indexOf(m);
    setState(() {
      if (idx >= 0) {
        _messages.removeAt(idx);
        if (idx - 1 >= 0 && _messages[idx - 1].fromUser) {
          _messages.removeAt(idx - 1);
        }
      }
    });
    _send(uc.resendQuery, extraInputs);
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
        child: _chatLocked
            ? _buildLockedPanel()
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_softWarning) _buildSoftWarning(),
            if (!isGuest)
              Align(
                alignment: Alignment.centerLeft,
                child: KeyedSubtree(key: _kMode, child: _modeToggle()),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: _kInput,
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

  /// Banner nhắc nhở khi hội thoại sắp chạm giới hạn (`soft_warning`).
  Widget _buildSoftWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warningDark.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warningDark.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 16, color: AppColors.warningDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Cuộc trò chuyện đang dài. Cân nhắc bắt đầu cuộc mới để giữ chất lượng trả lời.',
              style: _Ts.bodySmall.copyWith(color: AppColors.warningDark),
            ),
          ),
        ],
      ),
    );
  }

  /// Khung thay thế ô nhập khi hội thoại đã bị khóa (`limit_reached`).
  Widget _buildLockedPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Cuộc trò chuyện đã đạt giới hạn.',
          style: _Ts.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          style:
              FilledButton.styleFrom(backgroundColor: AppColors.brandPrimary),
          icon: const Icon(Icons.add_comment_outlined, size: 18),
          label: const Text('Bắt đầu cuộc trò chuyện mới'),
          onPressed: _newConversation,
        ),
      ],
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
                        title: Row(
                          children: [
                            if (c.hasUnread) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Expanded(
                              child: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _Ts.bodyMedium.copyWith(
                                  fontWeight: c.hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
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

  // --- Badge & schedule ----------------------------------------------------

  /// Bọc một icon kèm chấm đỏ + số đếm khi `count > 0`.
  Widget _withBadge(Widget child, int count) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              count > 9 ? '9+' : '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom sheet quản lý "Lịch hỏi tự động": liệt kê, bật/tắt, xóa.
  /// Lịch mới được tạo bằng cách nhắn cho Mr. Wealth (vd "tổng hợp thị trường
  /// mỗi sáng 8h"), nên sheet này chỉ quản lý lịch đã có.
  Future<void> _openScheduleSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _ScheduleSheet(token: _token),
    );
    // Sheet có thể đã bật/tắt lịch → làm mới điều kiện hiển thị nút.
    _loadScheduleEligibility();
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

/// Bottom sheet "Lịch hỏi tự động" — liệt kê, bật/tắt, xóa các lịch của user.
class _ScheduleSheet extends StatefulWidget {
  final String? token;
  const _ScheduleSheet({required this.token});

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  bool _loading = true;
  List<ScheduledChat> _schedules = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ChatHistoryService.listSchedules(token: widget.token);
    if (!mounted) return;
    setState(() {
      _schedules = result.schedules;
      _loading = false;
    });
  }

  Future<void> _toggle(ScheduledChat s) async {
    final ok = await ChatHistoryService.toggleSchedule(
      scheduleId: s.id,
      enabled: !s.enabled,
      token: widget.token,
    );
    if (ok) _load();
  }

  Future<void> _delete(ScheduledChat s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Xóa lịch', style: _Ts.h3),
        content: Text(
          'Xóa lịch "${s.title}"? Mr. Wealth sẽ không gửi bản tin này nữa.',
          style: _Ts.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok =
        await ChatHistoryService.deleteSchedule(scheduleId: s.id, token: widget.token);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available,
                    size: 20, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text('Lịch hỏi tự động', style: _Ts.h3),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh,
                      size: 20, color: AppColors.darkTextMuted),
                  tooltip: 'Làm mới',
                  onPressed: _loading ? null : _load,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Mr. Wealth tự gửi bản tin định kỳ theo các lịch dưới đây. '
              'Để đặt lịch mới, nhắn cho Mr. Wealth — vd: "tổng hợp thị trường mỗi sáng 8h".',
              style: _Ts.bodySmall.copyWith(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_schedules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  'Chưa có lịch nào.\nNhắn cho Mr. Wealth để đặt lịch.',
                  textAlign: TextAlign.center,
                  style: _Ts.bodySmall
                      .copyWith(color: AppColors.darkTextMuted),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _schedules.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _scheduleTile(_schedules[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleTile(ScheduledChat s) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _Ts.bodyMedium.copyWith(
                    color: s.enabled
                        ? AppColors.darkTextPrimary
                        : AppColors.darkTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 12, color: AppColors.success),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        s.enabled
                            ? s.schedule
                            : '${s.schedule} · đã tắt',
                        overflow: TextOverflow.ellipsis,
                        style: _Ts.caption.copyWith(
                          color: s.enabled
                              ? AppColors.success
                              : AppColors.darkTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bật/tắt nhanh.
          Switch(
            value: s.enabled,
            activeThumbColor: AppColors.success,
            onChanged: (_) => _toggle(s),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppColors.danger),
            tooltip: 'Xóa',
            onPressed: () => _delete(s),
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
