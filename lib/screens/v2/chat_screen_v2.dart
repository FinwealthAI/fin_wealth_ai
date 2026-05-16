import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../respositories/auth_repository.dart';
import '../../services/chat_history_service.dart';
import '../../theme/theme.dart';
import '../../widgets/common/common.dart';

class ChatScreenV2 extends StatefulWidget {
  final String? initialTicker;
  const ChatScreenV2({super.key, this.initialTicker});

  @override
  State<ChatScreenV2> createState() => _ChatScreenV2State();
}

class _ChatScreenV2State extends State<ChatScreenV2> {
  final TextEditingController _input = TextEditingController();
  final List<_Msg> _messages = [];
  final ScrollController _scroll = ScrollController();

  late final AuthRepository _authRepo = context.read<AuthRepository>();
  String? _conversationId;
  String? _currentTaskId;
  bool _isTyping = false;
  bool _loadingHistory = false;

  final _smartTags = const [
    'Phân tích VNM',
    'So sánh FPT vs CMG',
    'Định giá HPG',
    'Cổ phiếu tăng trưởng',
    'Chiến lược pullback',
  ];

  @override
  void initState() {
    super.initState();
    if (_authRepo.accessToken != null) {
      _initConversation();
    }
    if (widget.initialTicker != null) {
      _input.text = 'Phân tích ${widget.initialTicker}';
    }
  }

  Future<void> _initConversation() async {
    final username = _authRepo.username;
    final token = _authRepo.accessToken;
    if (username == null || token == null) return;

    setState(() => _loadingHistory = true);
    try {
      final convId = await ChatHistoryService.getOrCreateConversationId(
        username,
        token: token,
      );
      _conversationId = convId.isEmpty ? null : convId;

      if (_conversationId != null) {
        final history = await ChatHistoryService.loadChatHistory(
          username,
          conversationId: _conversationId,
          token: token,
        );
        if (!mounted) return;
        setState(() {
          _messages.clear();
          _messages.addAll(history.map((m) => _Msg(
                text: m['content'] as String? ?? '',
                fromUser: m['role'] == 'user',
                id: m['id']?.toString(),
              )));
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    Future.delayed(const Duration(milliseconds: 60), () {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    if (_authRepo.accessToken == null) {
      _showLoginPrompt();
      return;
    }
    final text = _input.text.trim();
    if (text.isEmpty || _isTyping) return;
    _input.clear();

    final username = _authRepo.username ?? 'user';
    final token = _authRepo.accessToken!;

    setState(() {
      _messages.add(_Msg(text: text, fromUser: true));
      _messages.add(_Msg(text: '', fromUser: false));
      _isTyping = true;
    });
    _scrollToBottom();

    final assistantIndex = _messages.length - 1;

    try {
      final response = await ChatHistoryService.sendMessage(
        message: text,
        username: username,
        conversationId: _conversationId,
        token: token,
        inputs: {'category': 'general', 'category_detail': 'default'},
      );

      if (response.statusCode != 200) {
        throw 'Lỗi server: ${response.statusCode}';
      }

      final stream = response.data.stream
          .cast<List<int>>()
          .transform(utf8.decoder);
      final buffer = StringBuffer();
      final partial = StringBuffer();
      String? newConvId;

      await for (final chunk in stream) {
        if (!_isTyping) break;
        partial.write(chunk);
        var lines = partial.toString().split('\n');
        partial.clear();
        if (lines.isNotEmpty && !lines.last.trim().endsWith('}')) {
          partial.write(lines.removeLast());
        }
        for (final line in lines) {
          final clean = line.trim();
          if (!clean.startsWith('data: ')) continue;
          final dataStr = clean.substring(6).trim();
          if (dataStr.isEmpty) continue;
          if (dataStr == '[DONE]') break;
          
          try {
            final j = jsonDecode(dataStr);
            
            // Cập nhật conversation_id và task_id nếu có
            if (j['conversation_id'] != null) {
              newConvId = j['conversation_id'].toString();
            }
            if (j['task_id'] != null) {
              _currentTaskId = j['task_id'].toString();
            }
            
            // Xử lý nội dung câu trả lời (Native agent trả về trực tiếp trong trường 'answer')
            if (j['answer'] != null) {
              buffer.write(j['answer']);
              if (mounted) {
                setState(() {
                  _messages[assistantIndex] =
                      _messages[assistantIndex].copyWith(
                    text: buffer.toString(),
                    id: j['message_id']?.toString() ??
                        _messages[assistantIndex].id,
                  );
                });
              }
              _scrollToBottom();
            } else if (j['message_id'] != null) {
              // Cập nhật ID tin nhắn ngay cả khi chưa có nội dung (chunk đầu tiên)
              if (mounted) {
                setState(() {
                  _messages[assistantIndex] =
                      _messages[assistantIndex].copyWith(
                    id: j['message_id'].toString(),
                  );
                });
              }
            }
          } catch (_) {}
        }
      }

      if (newConvId != null) {
        _conversationId = newConvId;
        await ChatHistoryService.saveConversationId(username, newConvId);
      }

      if (buffer.isEmpty && mounted) {
        setState(() {
          _messages[assistantIndex] = _messages[assistantIndex]
              .copyWith(text: 'Không nhận được phản hồi từ server.');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages[assistantIndex] = _messages[assistantIndex]
            .copyWith(text: '❌ Lỗi khi gửi tin nhắn: $e');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _currentTaskId = null;
        });
      }
      _scrollToBottom();
    }
  }

  Future<void> _stopGenerate() async {
    if (_currentTaskId == null || !_isTyping) return;
    final taskId = _currentTaskId!;
    final username = _authRepo.username ?? 'user';
    final token = _authRepo.accessToken;
    setState(() => _isTyping = false);
    try {
      await ChatHistoryService.stopGenerate(
        taskId: taskId,
        username: username,
        token: token,
      );
    } catch (_) {}
  }

  Future<void> _clearConversation() async {
    if (_conversationId == null) {
      setState(_messages.clear);
      return;
    }
    final username = _authRepo.username ?? 'user';
    final token = _authRepo.accessToken;
    try {
      await ChatHistoryService.clearChatHistory(
        username,
        _conversationId!,
        token: token,
      );
      await ChatHistoryService.clearSavedConversationId(username);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _conversationId = null;
    });
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng nhập để chat với Mr.Wealth'),
        content: const Text(
            'Tính năng AI cần đăng nhập để lưu lịch sử và cá nhân hoá phản hồi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamed('/login-v2');
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _authRepo.accessToken == null;
    return Scaffold(
      appBar: FwAppBar(
        title: 'Mr.Wealth',
        subtitle: 'AI Cố vấn đầu tư',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: isGuest ? null : _clearConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildWelcome()
                    : _buildMessages(),
          ),
          if (!isGuest) _buildSmartTags(),
          _buildInput(isGuest),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    final text = Theme.of(context).textTheme;
    final name = _authRepo.username ?? 'bạn';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  AppColors.brandPrimary,
                  AppColors.brandSecondary,
                ]),
                boxShadow: AppShadows.purpleGlow,
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 44, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Xin chào, $name 👋',
                style: text.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _authRepo.accessToken == null
                  ? 'Đăng nhập để bắt đầu trò chuyện với Mr.Wealth.'
                  : 'Bạn cần phân tích mã cổ phiếu nào hôm nay?',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) {
        final m = _messages[i];
        return Align(
          alignment:
              m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              color: m.fromUser
                  ? AppColors.brandPrimary
                  : AppColors.darkSurfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.lg).copyWith(
                bottomRight: m.fromUser ? const Radius.circular(4) : null,
                bottomLeft: m.fromUser ? null : const Radius.circular(4),
              ),
              border: m.fromUser
                  ? null
                  : Border.all(
                      color: AppColors.brandPrimary
                          .withValues(alpha: 0.3)),
              boxShadow: m.fromUser ? null : AppShadows.purpleGlow,
            ),
            child: m.text.isEmpty && !m.fromUser
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : m.fromUser
                    ? Text(
                        m.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                      )
                    : MarkdownBody(
                        data: m.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14, height: 1.5),
                          h1: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                          h2: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 17, fontWeight: FontWeight.w700),
                          h3: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                          strong: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700),
                          em: const TextStyle(color: AppColors.darkTextPrimary, fontStyle: FontStyle.italic),
                          listBullet: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
                          code: TextStyle(
                            color: AppColors.brandSecondaryDark,
                            backgroundColor: AppColors.darkBg.withValues(alpha: 0.5),
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: AppColors.darkBg.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          blockquote: const TextStyle(color: AppColors.darkTextSecondary, fontStyle: FontStyle.italic),
                          blockquoteDecoration: const BoxDecoration(
                            border: Border(left: BorderSide(color: AppColors.brandPrimary, width: 3)),
                          ),
                        ),
                      ),
          ),
        );
      },
    );
  }

  Widget _buildSmartTags() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _smartTags.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (ctx, i) => FwFilterPill(
          label: _smartTags[i],
          icon: Icons.flash_on,
          active: false,
          onTap: () {
            _input.text = _smartTags[i];
          },
        ),
      ),
    );
  }

  Widget _buildInput(bool isGuest) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.darkBg,
          border: Border(
            top: BorderSide(color: AppColors.darkBorder),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                maxLines: 4,
                minLines: 1,
                enabled: !_isTyping,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: isGuest
                      ? 'Đăng nhập để bắt đầu...'
                      : 'Nhập câu hỏi về cổ phiếu...',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  AppColors.brandPrimary,
                  AppColors.brandSecondary,
                ]),
                boxShadow: AppShadows.purpleGlow,
              ),
              child: IconButton(
                icon: Icon(_isTyping ? Icons.stop : Icons.send,
                    color: Colors.white),
                onPressed: _isTyping ? _stopGenerate : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool fromUser;
  final String? id;
  _Msg({required this.text, required this.fromUser, this.id});

  _Msg copyWith({String? text, String? id}) =>
      _Msg(text: text ?? this.text, fromUser: fromUser, id: id ?? this.id);
}
