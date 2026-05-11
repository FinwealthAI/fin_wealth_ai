import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../config/api_config.dart';
import '../../respositories/auth_repository.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

enum AiReportMode { deepReport, financialAnalysis }

class AiReportScreenV2 extends StatefulWidget {
  final AiReportMode mode;
  final String? initialTicker;

  const AiReportScreenV2({
    super.key,
    required this.mode,
    this.initialTicker,
  });

  @override
  State<AiReportScreenV2> createState() => _AiReportScreenV2State();
}

class _AiReportScreenV2State extends State<AiReportScreenV2> {
  final TextEditingController _tickerInput = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _isLoading = false;
  Timer? _pollingTimer;

  late final AuthRepository _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthRepository>();

    // Greeting message from M.A.I
    _addAiMsg(
      _greetingText,
      avatar: _Avatar.mai,
    );

    // Auto-run if ticker provided
    if (widget.initialTicker != null && widget.initialTicker!.isNotEmpty) {
      _tickerInput.text = widget.initialTicker!.toUpperCase();
      WidgetsBinding.instance.addPostFrameCallback((_) => _runWorkflow());
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tickerInput.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _greetingText {
    if (widget.mode == AiReportMode.deepReport) {
      return 'Xin chào! Em là M.A.I, trợ lý của Mr. Wealth. Vui lòng nhập mã cổ phiếu để Mr. Wealth phân tích chuyên sâu nhé ạ.';
    }
    return 'Xin chào! Em là M.A.I. Vui lòng nhập mã cổ phiếu để Mr. Wealth phân tích Báo cáo Tài chính nhé ạ.';
  }

  String get _title {
    return widget.mode == AiReportMode.deepReport ? 'Báo cáo sâu' : 'Báo cáo TC';
  }

  String get _subtitle {
    return widget.mode == AiReportMode.deepReport
        ? 'Phân tích đa chiều mã cổ phiếu'
        : 'Phân tích Báo cáo Tài chính';
  }

  void _addAiMsg(String text, {required _Avatar avatar, bool isHtml = false}) {
    setState(() {
      _messages.add(_ChatMsg(text: text, avatar: avatar, isHtml: isHtml));
    });
    _scrollToBottom();
  }

  void _addUserMsg(String text) {
    setState(() {
      _messages.add(_ChatMsg(text: text, avatar: _Avatar.user));
    });
    _scrollToBottom();
  }

  void _addTyping() {
    setState(() {
      _messages.add(_ChatMsg(text: '', avatar: _Avatar.mrWealth, isTyping: true));
    });
    _scrollToBottom();
  }

  void _removeTyping() {
    setState(() {
      _messages.removeWhere((m) => m.isTyping);
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runWorkflow() async {
    final ticker = _tickerInput.text.trim().toUpperCase();
    if (ticker.isEmpty || _isLoading) return;

    final token = _auth.accessToken;
    if (token == null) {
      _addAiMsg('Bạn cần đăng nhập để sử dụng tính năng này ạ.', avatar: _Avatar.mai);
      return;
    }

    _addUserMsg('Phân tích mã: $ticker');
    setState(() => _isLoading = true);

    if (widget.mode == AiReportMode.deepReport) {
      await _runDeepReport(ticker, token);
    } else {
      await _runFinancialAnalysis(ticker, token);
    }
  }

  Future<void> _runDeepReport(String ticker, String token) async {
    _addAiMsg(
      'Dạ, em sẽ mời chuyên gia Mr. Wealth phân tích giúp ạ. Vui lòng chờ một chút nhé...',
      avatar: _Avatar.mai,
    );
    _addTyping();

    final dio = Dio();
    try {
      final res = await dio.get(
        ApiConfig.runWorkflow(ticker),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = res.data;
      if (data['success'] != true) {
        _removeTyping();
        String msg = data['message'] ?? 'Đã xảy ra lỗi. Vui lòng thử lại sau ạ.';
        if (msg.contains('quá nhiều')) {
          msg = 'Dạ hiện tại Mr. Wealth có quá nhiều yêu cầu. Anh/Chị vui lòng thử lại sau ạ.';
        } else if (msg.contains('vượt quá')) {
          msg = 'Dạ hôm nay đã hết lượt yêu cầu. Hẹn Anh/Chị ngày mai nhé!';
        } else if (msg.contains('không tồn tại')) {
          msg = 'Dạ mã cổ phiếu này chưa tồn tại hoặc Finwealth chưa có dữ liệu ạ.';
        }
        _addAiMsg(msg, avatar: _Avatar.mai);
        setState(() => _isLoading = false);
        return;
      }

      // Cache hit - show immediately after delay
      if (data['immediate'] == true) {
        await Future.delayed(const Duration(seconds: 2));
        _removeTyping();
        _addAiMsg('Đây là báo cáo phân tích đã được Mr. Wealth chuẩn bị ạ:', avatar: _Avatar.mrWealth);
        await Future.delayed(const Duration(milliseconds: 500));
        _addAiMsg(data['content'] ?? '', avatar: _Avatar.mrWealth, isHtml: true);
        _addFollowUp();
        setState(() => _isLoading = false);
        return;
      }

      // Background task - start polling
      final taskId = data['task_id']?.toString();
      if (taskId == null) {
        _removeTyping();
        _addAiMsg('Dạ không nhận được task ID. Vui lòng thử lại sau ạ.', avatar: _Avatar.mai);
        setState(() => _isLoading = false);
        return;
      }

      _startPolling(taskId, token);
    } on DioException catch (e) {
      _removeTyping();
      _addAiMsg('Dạ kết nối đang không ổn định. Anh/Chị thử lại sau giúp em nhé!', avatar: _Avatar.mai);
      setState(() => _isLoading = false);
    }
  }

  void _startPolling(String taskId, String token) {
    int elapsed = 0;
    const interval = 3;
    const maxSeconds = 240;

    _pollingTimer = Timer.periodic(const Duration(seconds: interval), (timer) async {
      elapsed += interval;
      if (elapsed > maxSeconds) {
        timer.cancel();
        _removeTyping();
        _addAiMsg('Dạ hệ thống mất quá nhiều thời gian xử lý. Vui lòng thử lại sau ạ.', avatar: _Avatar.mai);
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      try {
        final dio = Dio();
        final res = await dio.get(
          ApiConfig.checkTask(taskId),
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        final data = res.data;
        if (data['success'] == true) {
          timer.cancel();
          _removeTyping();
          _addAiMsg('Đây là báo cáo phân tích đã được Mr. Wealth chuẩn bị ạ:', avatar: _Avatar.mrWealth);
          await Future.delayed(const Duration(milliseconds: 300));
          _addAiMsg(data['content'] ?? '', avatar: _Avatar.mrWealth, isHtml: true);
          _addFollowUp();
          if (mounted) setState(() => _isLoading = false);
        } else if (data['status'] == 'FAILURE' || data['status'] == 'REVOKED') {
          timer.cancel();
          _removeTyping();
          _addAiMsg(data['message'] ?? 'Dạ đã xảy ra lỗi. Vui lòng thử lại sau ạ.', avatar: _Avatar.mai);
          if (mounted) setState(() => _isLoading = false);
        }
      } catch (_) {}
    });
  }

  Future<void> _runFinancialAnalysis(String ticker, String token) async {
    _addAiMsg(
      'Dạ, em đang yêu cầu Mr. Wealth phân tích Báo cáo Tài chính của mã $ticker. Quá trình này có thể mất 15–30 giây, Anh/Chị vui lòng chờ nhé...',
      avatar: _Avatar.mai,
    );
    _addTyping();

    final dio = Dio();
    try {
      final res = await dio.post(
        ApiConfig.financialAnalysis,
        data: jsonEncode({
          'ticker': ticker,
          'num_quarters': 4,
          'report_type': '',
        }),
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
      );

      _removeTyping();
      final data = res.data;

      if (data['error'] != null) {
        _addAiMsg('Dạ có lỗi xảy ra: ${data['error']}', avatar: _Avatar.mai);
        setState(() => _isLoading = false);
        return;
      }

      if (data['status'] == 'task_started') {
        _addAiMsg(
          data['message'] ?? 'Yêu cầu đã được ghi nhận. Mr. Wealth đang xử lý và sẽ thông báo qua Discord khi hoàn tất ạ!',
          avatar: _Avatar.mai,
        );
        setState(() => _isLoading = false);
        return;
      }

      if (data['summary'] != null && (data['summary'] as String).isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        _addAiMsg(
          'Dạ đây là báo cáo phân tích tài chính từ Mr. Wealth dành cho mã $ticker ạ:',
          avatar: _Avatar.mrWealth,
        );
        await Future.delayed(const Duration(milliseconds: 300));
        _addAiMsg(data['summary'], avatar: _Avatar.mrWealth, isHtml: true);
        _addFollowUp();
      } else {
        _addAiMsg(
          'Dạ yêu cầu phân tích đang được xử lý. Anh/Chị vui lòng chờ thông báo từ Mr. Wealth qua Discord sau ít phút nhé!',
          avatar: _Avatar.mai,
        );
      }
    } on DioException catch (_) {
      _removeTyping();
      _addAiMsg('Dạ kết nối đang không ổn định. Anh/Chị thử lại sau giúp em nhé!', avatar: _Avatar.mai);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addFollowUp() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _addAiMsg('Anh/Chị có muốn phân tích mã cổ phiếu khác không ạ?', avatar: _Avatar.mai);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: FwAppBar(title: _title, subtitle: _subtitle),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildMessage(_messages[i]),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessage(_ChatMsg msg) {
    if (msg.avatar == _Avatar.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary,
            borderRadius: BorderRadius.circular(AppRadius.lg)
                .copyWith(bottomRight: const Radius.circular(4)),
          ),
          child: Text(msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
        ),
      );
    }

    final avatarAsset = msg.avatar == _Avatar.mrWealth
        ? 'assets/images/mr_wealth_avatar.png'
        : 'assets/images/mai_avatar.png';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
            child: ClipOval(
              child: SizedBox(
                width: 36,
                height: 36,
                child: msg.avatar == _Avatar.mrWealth
                    ? Image.asset(
                        'assets/images/mr_wealth_avatar.png',
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/images/mai_avatar.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.brandPrimary,
                          child: const Icon(Icons.smart_toy_outlined,
                              size: 18, color: Colors.white),
                        ),
                      ),
              ),
            ),
          ),
          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.lg)
                    .copyWith(bottomLeft: const Radius.circular(4)),
                border: Border.all(
                    color: AppColors.brandPrimary.withValues(alpha: 0.2)),
              ),
              child: msg.isTyping
                  ? _TypingIndicator()
                  : msg.isHtml
                      ? Html(
                          data: msg.text,
                          style: {
                            'body': Style(
                              color: AppColors.darkTextPrimary,
                              fontSize: FontSize(14),
                              lineHeight: LineHeight(1.6),
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                            ),
                            'h1': Style(color: AppColors.darkTextPrimary, fontSize: FontSize(20), fontWeight: FontWeight.w700, margin: Margins.only(top: 16, bottom: 8)),
                            'h2': Style(color: AppColors.darkTextPrimary, fontSize: FontSize(17), fontWeight: FontWeight.w700, margin: Margins.only(top: 14, bottom: 6)),
                            'h3': Style(color: AppColors.darkTextPrimary, fontSize: FontSize(15), fontWeight: FontWeight.w600, margin: Margins.only(top: 12, bottom: 4)),
                            'p': Style(color: AppColors.darkTextPrimary, fontSize: FontSize(14), lineHeight: LineHeight(1.6), margin: Margins.only(bottom: 10)),
                            'strong,b': Style(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700),
                            'ul,ol': Style(margin: Margins.only(bottom: 10, left: 4)),
                            'li': Style(color: AppColors.darkTextPrimary, fontSize: FontSize(14), lineHeight: LineHeight(1.6), margin: Margins.only(bottom: 4)),
                            'a': Style(color: AppColors.brandPrimaryDark, textDecoration: TextDecoration.underline),
                          },
                        )
                      : Text(
                          msg.text,
                          style: const TextStyle(
                              color: AppColors.darkTextPrimary,
                              fontSize: 14,
                              height: 1.6),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.darkBg,
          border: Border(top: BorderSide(color: AppColors.darkBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tickerInput,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _runWorkflow(),
                decoration: InputDecoration(
                  hintText: 'Nhập mã cổ phiếu (VD: VNM, HPG...)',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppColors.darkTextMuted),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.darkTextMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: AppSpacing.lg),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(
                        color: AppColors.brandPrimaryDark, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [
                  AppColors.brandPrimary,
                  AppColors.brandSecondary,
                ]),
                boxShadow: AppShadows.purpleGlow,
              ),
              child: IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _isLoading ? null : _runWorkflow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Avatar { user, mai, mrWealth }

class _ChatMsg {
  final String text;
  final _Avatar avatar;
  final bool isTyping;
  final bool isHtml;

  const _ChatMsg({
    required this.text,
    required this.avatar,
    this.isTyping = false,
    this.isHtml = false,
  });
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final phase = (_controller.value * 3 - i).clamp(0.0, 1.0);
            final offset = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
            return Transform.translate(
              offset: Offset(0, -4 * offset),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimaryDark
                      .withValues(alpha: 0.4 + 0.6 * offset),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
