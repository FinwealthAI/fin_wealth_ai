import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:convert';
import '../services/chat_history_service.dart';
import '../respositories/auth_repository.dart';
import 'package:flutter_html/flutter_html.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? initialMessage;
  final Map<String, dynamic>? chatInputs;
  const ChatScreen({Key? key, required this.userData, this.initialMessage, this.chatInputs}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _tickerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _conversations = [];
  
  bool _sending = false;
  bool _isTyping = false;
  bool _loadingHistory = false;
  bool _loadingConversations = false;
  
  String? _currentConversationId;
  String? _currentTaskId;
  String _selectedCategory = 'PORTFOLIO_STRATEGY';
  String? _currentTicker;

  // Smart Tags aligned with smart_tags.html
  final List<Map<String, String>> _smartTags = [
    {'id': 'PORTFOLIO_STRATEGY', 'label': 'Chiến lược', 'icon': 'assets/icons/strategy.png'}, 
    {'id': 'CORPORATE_ANALYST', 'label': 'Phân tích', 'icon': 'assets/icons/analysis.png'},
    {'id': 'FUNDAMENTAL', 'label': 'Dữ liệu', 'icon': 'assets/icons/data.png'},
    {'id': 'FINANCE_GENERAL', 'label': 'Kiến thức', 'icon': 'assets/icons/knowledge.png'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.chatInputs?['category'] != null) {
      _selectedCategory = widget.chatInputs!['category'];
    }
    if (widget.chatInputs?['ticker'] != null) {
      _currentTicker = widget.chatInputs!['ticker'];
      _tickerController.text = _currentTicker ?? '';
    }

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _controller.text = widget.initialMessage!;
    }
    
    _loadConversations();
    _loadChatHistory();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMessage != null && widget.initialMessage != oldWidget.initialMessage && widget.initialMessage!.isNotEmpty) {
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

  Future<void> _loadChatHistory({String? conversationId}) async {
    setState(() {
      _loadingHistory = true;
      if (conversationId != null) _currentConversationId = conversationId;
    });

    try {
      final username = widget.userData['username'] ?? 'user123';
      
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

  void _startNewChat() {
    setState(() {
      _currentConversationId = null;
      _messages = [];
    });
    Navigator.of(context).pop(); 
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      final username = widget.userData['username'] ?? 'user123';
      await ChatHistoryService.clearChatHistory(
        username, 
        conversationId, 
        token: _accessToken,
      );
      
      if (_currentConversationId == conversationId) {
        _startNewChat();
      } else {
        _loadConversations();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xóa hội thoại: $e')),
      );
    }
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
    });
  }

  void _onTickerSubmitted(String value) {
    final ticker = value.trim().toUpperCase();
    if (ticker.length == 3) {
      setState(() {
        _currentTicker = ticker;
        _tickerController.text = ticker;
      });
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
      
      // Construct inputs matching ChatInputHandler.getInputs()
      final inputs = Map<String, dynamic>.from(widget.chatInputs ?? {});
      inputs['category'] = _selectedCategory;
      if (_currentTicker != null && _currentTicker!.isNotEmpty) {
          inputs['ticker'] = _currentTicker;
          inputs['category_detail'] = 'phân tích cơ hội'; // Enforced by rule
      } else {
          inputs['category_detail'] = 'default';
      }

      final response = await ChatHistoryService.sendMessage(
        message: text,
        username: username,
        conversationId: _currentConversationId,
        token: _accessToken,
        inputs: inputs,
      );

      if (response.statusCode == 200) {
        final responseBody = response.data;
        StringBuffer messageBuffer = StringBuffer();
        String? conversationId;

        final stream = responseBody.stream.cast<List<int>>().transform(utf8.decoder);
        StringBuffer partial = StringBuffer();

        await for (final chunk in stream) {
          if (!_isTyping) break;
          partial.write(chunk);
          var lines = partial.toString().split('\n');
          partial.clear();
          if (lines.isNotEmpty && !lines.last.trim().endsWith('}')) {
             partial.write(lines.removeLast());
          }

          for (final line in lines) {
            String cleanLine = line.trim();
            if (!cleanLine.startsWith('data: ')) continue;
            final dataStr = cleanLine.substring(6).trim();
            if (dataStr.isEmpty || dataStr == '[DONE]') continue;

            try {
              final jsonData = jsonDecode(dataStr);

              if (jsonData['event'] == 'message' && jsonData['answer'] != null) {
                messageBuffer.write(jsonData['answer']);
                setState(() {
                  _messages[assistantMessageIndex]['content'] = messageBuffer.toString();
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
          _loadConversations();
        }

        if (messageBuffer.isEmpty && _isTyping) {
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

  Future<void> _sendFeedback(int index, String messageId, String rating) async {
    try {
      final username = widget.userData['username'] ?? 'user123';
      final currentRating = _messages[index]['rating'];
      String apiRating = rating;
      String? uiRating = rating;

      if (currentRating == rating) {
        apiRating = ''; 
        uiRating = null;
      }
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

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép tin nhắn')),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: _buildDrawer(),
      body: Column(
        children: [
            // Header with Gradient
           Container(
             padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16), // Siêu mỏng: padding 4
             decoration: const BoxDecoration(
               gradient: LinearGradient(
                 colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
               ),
             ),
             child: Row(
               children: [
                 if (Navigator.of(context).canPop())
                   IconButton(
                     padding: EdgeInsets.zero, // Bỏ padding của icon back để gọn hơn
                     constraints: const BoxConstraints(), // Icon nhỏ gọn nhất có thể
                     icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                     onPressed: () => Navigator.of(context).pop(),
                   ),
                 const SizedBox(width: 12), // Giãn cách sau nút back
                 Container(
                   padding: const EdgeInsets.all(1),
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.3),
                     shape: BoxShape.circle,
                   ),
                   child: const CircleAvatar(
                     radius: 14, // Giảm size avatar xuống 14 cho vừa vặn
                     backgroundImage: AssetImage('assets/images/mr_wealth_avatar.png'),
                   ),
                 ),
                 const SizedBox(width: 8),
                 const Text(
                   "Mr Wealth",
                   style: TextStyle(
                     color: Colors.white,
                     fontWeight: FontWeight.bold,
                     fontSize: 14, // Giảm font size một chút cho cân đối
                   ),
                 ),
                 const SizedBox(width: 6),
                 // Chấm xanh online ngay cạnh tên
                 Container(
                   width: 8,
                   height: 8,
                   decoration: BoxDecoration(
                     color: const Color(0xFF00E676), // Xanh lá sáng hơn
                     shape: BoxShape.circle,
                     border: Border.all(color: Colors.white, width: 1.5), // Viền trắng cho nổi bật
                   ),
                 ),
                 const Spacer(), // Đẩy các widget khác (nếu có) sang phải
               ],
             ),
           ),
           
           Expanded(
            child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: Column(
              children: [
                if (_selectedCategory == 'CORPORATE_ANALYST')
                    _buildTickerPromptBanner(),

                Expanded(
                  child: Stack(
                children: [
                  _messages.isEmpty && !_isTyping && !_loadingHistory
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("👋", style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 16),
                              Text(
                                "Xin chào, ${widget.userData['username'] ?? 'User'}!",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              const Text("Tôi có thể giúp gì cho danh mục của bạn?", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
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
                  // Only show scroll button when not at bottom
                  // This needs a listener to be reactive, but simple check in build works for initial render
                  // Usually done with NotificationListener.
                ],
              ),
            ), ],
              ),
            ),
           ),
            
            // Smart Tags
            Container(
               height: 40,
               margin: const EdgeInsets.symmetric(vertical: 8),
               child: ListView.separated(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 scrollDirection: Axis.horizontal,
                 itemCount: _smartTags.length,
                 separatorBuilder: (_, __) => const SizedBox(width: 8),
                 itemBuilder: (context, index) {
                   final tag = _smartTags[index];
                   final isActive = tag['id'] == _selectedCategory;
                   return InkWell(
                     onTap: () => _onCategorySelected(tag['id']!),
                     borderRadius: BorderRadius.circular(20),
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                       decoration: BoxDecoration(
                         color: isActive ? Colors.blue.withOpacity(0.1) : Colors.white,
                         border: Border.all(color: isActive ? Colors.blue : Colors.grey.shade300),
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: Row(
                         children: [
                           // Using icon assets if available or fallback
                           Icon(isActive ? Icons.check_circle : Icons.circle_outlined, size: 14, color: isActive ? Colors.blue : Colors.grey),
                           const SizedBox(width: 4),
                           Text(
                             tag['label']!,
                             style: TextStyle(
                               fontSize: 12,
                               fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                               color: isActive ? Colors.blue : Colors.grey.shade700,
                             ),
                           ),
                         ],
                       ),
                     ),
                   );
                 },
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
    );
  }

  Widget _buildTickerPromptBanner() {
      return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
              children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: _tickerController,
                          decoration: const InputDecoration(
                              hintText: "Nhập mã CP (VD: HPG)",
                              border: InputBorder.none,
                              isDense: true,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: _onTickerSubmitted,
                          onChanged: (val) {
                              if (val.length == 3) _onTickerSubmitted(val);
                          },
                      ),
                  ),
                  if (_currentTicker != null)
                      IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                          onPressed: () {
                              setState(() {
                                  _currentTicker = null;
                                  _tickerController.clear();
                              });
                          },
                      )
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

  Widget _buildMessage(int index, Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final messageId = msg['id'];
    final rating = msg['rating']; 

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
                    backgroundImage: const AssetImage('assets/images/mr_wealth_avatar.png'),
                    backgroundColor: const Color(0xFF6C5DD3),
                  ),
                ),
              
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF5B4DBC) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
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
                  child: Html(
                    data: _markdownToHtml(msg['content'] ?? ''),
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: FontSize(15),
                        lineHeight: LineHeight(1.4),
                        fontFamily: 'Roboto',
                      ),
                      "p": Style(margin: Margins.only(bottom: 8)),
                    },
                  ),
                ),
              ),
              
              if (isUser) const SizedBox(width: 8),
            ],
          ),
          
          if (!isUser && messageId != null)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                    onPressed: () => _copyMessage(msg['content'] ?? ''),
                    tooltip: 'Sao chép',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  
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

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 50, bottom: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            _buildDot(1),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
      return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
          ),
      );
  }

  String _markdownToHtml(String markdown) {
    // Basic Markdown processing for consistency with Flutter Html
    String html = markdown
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) => '<b>${match.group(1)}</b>')
        .replaceAllMapped(RegExp(r'\*(.*?)\*'), (match) => '<i>${match.group(1)}</i>')
        .replaceAll('\n', '<br/>');
    return html;
  }
}
