import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:convert';
import '../services/chat_history_service.dart';
import '../respositories/auth_repository.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? initialMessage;
  const ChatScreen({Key? key, required this.userData, this.initialMessage}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _conversations = []; // Danh sách lịch sử chat
  
  bool _sending = false;
  bool _isTyping = false;
  bool _loadingHistory = false;
  bool _loadingConversations = false;
  
  String? _currentConversationId;
  String? _currentTaskId;

  @override
  void initState() {
    super.initState();
    // Set initial message if provided
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _controller.text = widget.initialMessage!;
    }
    _loadConversations(); // Tải danh sách hội thoại
    _loadChatHistory();   // Tải hội thoại hiện tại/mới nhất
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMessage != oldWidget.initialMessage && 
        widget.initialMessage != null && 
        widget.initialMessage!.isNotEmpty) {
      _controller.text = widget.initialMessage!;
    }
  }

  String? get _accessToken {
    try {
      return context.read<AuthRepository>().accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Tải danh sách các cuộc hội thoại
  Future<void> _loadConversations() async {
    setState(() => _loadingConversations = true);
    try {
      final username = widget.userData['username'] ?? 'user123';
      final convs = await ChatHistoryService.getUserConversations(
        username, 
        token: _accessToken,
      );
      setState(() {
        _conversations = convs;
      });
    } catch (e) {
      print('Lỗi tải danh sách hội thoại: $e');
    } finally {
      setState(() => _loadingConversations = false);
    }
  }

  /// Tải nội dung cuộc hội thoại
  Future<void> _loadChatHistory({String? conversationId}) async {
    setState(() {
      _loadingHistory = true;
      if (conversationId != null) _currentConversationId = conversationId;
    });

    try {
      final username = widget.userData['username'] ?? 'user123';
      
      // Nếu chưa có ID, lấy hoặc tạo mới
      if (_currentConversationId == null) {
        _currentConversationId = await ChatHistoryService.getOrCreateConversationId(
          username, 
          token: _accessToken,
        );
      }
      
      final history = await ChatHistoryService.loadChatHistory(
        username,
        conversationId: _currentConversationId,
        token: _accessToken,
      );
      
      setState(() {
        _messages = history;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Lỗi khi tải lịch sử chat: $e');
    } finally {
      setState(() {
        _loadingHistory = false;
      });
    }
  }

  /// Bắt đầu cuộc trò chuyện mới
  void _startNewChat() {
    setState(() {
      _currentConversationId = null;
      _messages = [];
    });
    Navigator.of(context).pop(); // Đóng drawer
  }

  /// Xóa cuộc hội thoại
  Future<void> _deleteConversation(String conversationId) async {
    try {
      final username = widget.userData['username'] ?? 'user123';
      await ChatHistoryService.clearChatHistory(
        username, 
        conversationId, 
        token: _accessToken,
      );
      
      // Nếu đang xem cuộc hội thoại bị xóa, reset
      if (_currentConversationId == conversationId) {
        _startNewChat();
      } else {
        // Reload danh sách
        _loadConversations();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xóa hội thoại: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _sending = true;
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final assistantMessageIndex = _messages.length;
      _messages.add({'role': 'assistant', 'content': ''});

      final username = widget.userData['username'] ?? 'user123';
      
      final response = await ChatHistoryService.sendMessage(
        message: text,
        username: username, // Sử dụng username trực tiếp
        conversationId: _currentConversationId,
        token: _accessToken,
      );

      if (response.statusCode == 200) {
        final responseBody = response.data;
        StringBuffer messageBuffer = StringBuffer();
        String? conversationId;

        final stream = responseBody.stream.transform(utf8.decoder);
        StringBuffer partial = StringBuffer();

        await for (final chunk in stream) {
          if (!_isTyping) break;
          partial.write(chunk);
          var lines = partial.toString().split('\n');
          partial.clear();
          if (!lines.last.trim().endsWith('}')) {
            partial.write(lines.removeLast());
          }

          for (final line in lines) {
            if (!line.startsWith('data: ')) continue;
            final dataStr = line.substring(6).trim();
            if (dataStr.isEmpty) continue;

            try {
              final jsonData = jsonDecode(dataStr);

              if (jsonData['event'] == 'message' && jsonData['answer'] != null) {
                messageBuffer.write(jsonData['answer']);
                setState(() {
                  _messages[assistantMessageIndex]['content'] = messageBuffer.toString();
                  // Lưu message_id để feedback nếu cần
                  if (jsonData['message_id'] != null) {
                    _messages[assistantMessageIndex]['id'] = jsonData['message_id'];
                  }
                });
                _scrollToBottom();
              }

              if (jsonData['conversation_id'] != null) {
                conversationId = jsonData['conversation_id'];
                _currentConversationId = conversationId;
              }

              if (jsonData['task_id'] != null) {
                _currentTaskId = jsonData['task_id'];
              }

              if (jsonData['event'] == 'message_end') {
                break;
              }
            } catch (_) {}
          }
        }

        if (conversationId != null) {
          await ChatHistoryService.saveConversationId(username, conversationId);
          _loadConversations(); // Cập nhật danh sách bên sidebar
        }

        if (messageBuffer.isEmpty) {
          setState(() {
            _messages[assistantMessageIndex]['content'] = 'Không nhận được phản hồi từ server';
          });
        }
      } else {
        throw 'Lỗi server: ${response.statusCode}';
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '❌ Lỗi khi gửi tin nhắn: $e',
        });
      });
    } finally {
      setState(() {
        _sending = false;
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _stopGenerate() async {
    if (_currentTaskId == null || !_isTyping) return;
    try {
      await ChatHistoryService.stopGenerate(
        taskId: _currentTaskId!,
        username: widget.userData['username'] ?? 'user123',
        token: _accessToken,
      );
      setState(() {
        _isTyping = false;
        _currentTaskId = null;
      });
    } catch (e) {
      print('Lỗi dừng generate: $e');
    }
  }

  /// Gửi feedback (Like/Dislike)
  Future<void> _sendFeedback(int index, String messageId, String rating) async {
    try {
      final username = widget.userData['username'] ?? 'user123';
      final currentRating = _messages[index]['rating'];
      
      String apiRating = rating;
      String? uiRating = rating;

      // Toggle logic
      if (currentRating == rating) {
        apiRating = ''; // Send empty string to remove evaluation
        uiRating = null;    // Reset UI
      }

      // Update UI immediately
      setState(() {
        _messages[index]['rating'] = uiRating;
      });

      await ChatHistoryService.sendFeedback(
        messageId: messageId,
        rating: apiRating,
        username: username,
        token: _accessToken,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi đánh giá: $e')),
      );
    }
  }

  /// Copy nội dung tin nhắn
  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép tin nhắn')),
    );
  }

  /// Paste nội dung vào ô nhập liệu
  Future<void> _pasteContent() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _controller.text += data!.text!;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(int index, Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final messageId = msg['id'];
    final rating = msg['rating']; // 'like', 'dislike', or null

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF6C5DD3),
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                  ),
                ),
              
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF5B4DBC) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    boxShadow: isUser ? [] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isUser ? null : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    msg['content'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              
              if (isUser) const SizedBox(width: 8),
            ],
          ),
          
          // Action buttons for assistant messages (Bottom Row)
          if (!isUser && messageId != null)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Copy Button
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                    onPressed: () => _copyMessage(msg['content'] ?? ''),
                    tooltip: 'Sao chép',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  
                  // Like Button
                  IconButton(
                    icon: Icon(
                      rating == 'like' ? Icons.thumb_up_alt : Icons.thumb_up_outlined,
                      size: 18, 
                      color: rating == 'like' ? Colors.blue : Colors.grey
                    ),
                    onPressed: () => _sendFeedback(index, messageId, 'like'),
                    tooltip: 'Thích',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  
                  // Dislike Button
                  IconButton(
                    icon: Icon(
                      rating == 'dislike' ? Icons.thumb_down_alt : Icons.thumb_down_outlined,
                      size: 18, 
                      color: rating == 'dislike' ? Colors.red : Colors.grey
                    ),
                    onPressed: () => _sendFeedback(index, messageId, 'dislike'),
                    tooltip: 'Không thích',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FinWealth AI',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _startNewChat,
                  icon: const Icon(Icons.add, color: Color(0xFF6C5DD3)),
                  label: const Text('Chat mới', style: TextStyle(color: Color(0xFF6C5DD3))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingConversations
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _conversations.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final conv = _conversations[index];
                      final isSelected = conv['id'] == _currentConversationId;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.purple.withOpacity(0.1),
                        leading: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                        title: Text(
                          conv['name'] ?? 'Cuộc trò chuyện mới',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          _loadChatHistory(conversationId: conv['id']);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                          onPressed: () => _deleteConversation(conv['id']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: _buildDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.history, color: Colors.white), // Changed to History icon
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "FinWealth Assistant",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "Sẵn sàng hỗ trợ",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          elevation: 0,
          // Removed actions (Close button)
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessage(index, _messages[index]);
                    },
                  ),
                  if (_scrollController.hasClients && _scrollController.offset < _scrollController.position.maxScrollExtent - 100)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        onPressed: _scrollToBottom,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.arrow_downward, color: Color(0xFF6C5DD3)),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.content_paste, color: Color(0xFF6C5DD3)),
                      onPressed: _pasteContent,
                      tooltip: 'Dán',
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF6C5DD3).withOpacity(0.5)),
                        ),
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 3,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: "Nhập tin nhắn...",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isTyping ? _stopGenerate : (_sending ? null : _sendMessage),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _isTyping ? Colors.redAccent : const Color(0xFF8E2DE2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isTyping ? Colors.redAccent : const Color(0xFF8E2DE2)).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _sending && !_isTyping
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isTyping ? Icons.stop : Icons.send,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 50, bottom: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text("FinWealth đang trả lời", style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(width: 4),
            AnimatedDots(),
          ],
        ),
      ),
    );
  }
}

class AnimatedDots extends StatefulWidget {
  const AnimatedDots({Key? key}) : super(key: key);

  @override
  State<AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots> {
  int _dotCount = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) {
        setState(() => _dotCount = (_dotCount % 3) + 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('.' * _dotCount, style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold));
  }
}
