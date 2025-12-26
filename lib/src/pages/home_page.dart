import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foxhu_bot_offline/src/services/openai_service.dart';
import 'package:foxhu_bot_offline/src/pages/settings_page.dart';
import 'package:foxhu_bot_offline/src/pages/about_page.dart';
import 'package:foxhu_bot_offline/src/services/storage_service.dart';

class Message {
  final String id;
  final String content;
  final bool isUser;

  Message({required this.id, required this.content, required this.isUser});

  // 从JSON创建Message对象
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
    );
  }

  // 将Message对象转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
    };
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  // 加载聊天记录
  Future<void> _loadChatHistory() async {
    try {
      final chatHistoryJson = await StorageService.getChatHistory();
      if (chatHistoryJson != null && chatHistoryJson.isNotEmpty) {
        final List<dynamic> chatHistoryList = jsonDecode(chatHistoryJson);
        setState(() {
          _messages.clear();
          _messages.addAll(
            chatHistoryList.map((json) => Message.fromJson(json as Map<String, dynamic>)),
          );
        });
      }
    } catch (e) {
      debugPrint('加载聊天记录失败: $e');
    }
  }

  // 保存聊天记录
  Future<void> _saveChatHistory() async {
    try {
      final chatHistoryJson = jsonEncode(_messages.map((msg) => msg.toJson()).toList());
      await StorageService.saveChatHistory(chatHistoryJson);
    } catch (e) {
      debugPrint('保存聊天记录失败: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _textController.text.trim();
    setState(() {
      _messages.add(Message(
        id: '${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(1000)}',
        content: userMessage, 
        isUser: true
      ));
      _textController.clear();
      _isLoading = true;
      // 添加一个临时的AI消息，用于显示流式输出
      _messages.add(Message(
        id: '${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(1000)}',
        content: '', 
        isUser: false
      ));
    });

    try {
      // 准备上下文
      final contextLength = await StorageService.getContextMaxSize();
      final context = _prepareContext(contextLength);

      // 使用OpenAI服务获取流式响应
      final stream = OpenAIService.getAIStreamResponse(userMessage, context: context);
      
      await for (final chunk in stream) {
        setState(() {
          // 更新最后一条AI消息的内容
          _messages[_messages.length - 1] = Message(
            id: _messages[_messages.length - 1].id,
            content: _messages[_messages.length - 1].content + chunk,
            isUser: false,
          );
        });
      }
      
      // 保存聊天记录
      await _saveChatHistory();
    } catch (e) {
      setState(() {
        // 更新最后一条AI消息为错误信息
        _messages[_messages.length - 1] = Message(
          id: _messages[_messages.length - 1].id,
          content: '获取响应失败: $e',
          isUser: false,
        );
      });
      
      // 即使发生错误也保存聊天记录
      await _saveChatHistory();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 准备上下文消息（基于数据大小）
  List<Map<String, dynamic>> _prepareContext(int maxSizeKB) {
    if (maxSizeKB <= 0) return [];
    
    final context = <Map<String, dynamic>>[];
    int totalSize = 0;
    
    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final messageData = {
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.content,
      };
      final messageYaml = _toYamlLine(messageData);
      final messageSize = messageYaml.length;
      
      if (totalSize + messageSize > maxSizeKB * 1024) {
        break;
      }
      
      context.add(messageData);
      totalSize += messageSize;
    }
    
    return context;
  }
  
  String _toYamlLine(Map<String, dynamic> msg) {
    return '- role: ${msg['role']}\n  content: |\n${(msg['content'] as String).split('\n').map((line) => '    $line').join('\n')}\n';
  }

  void _showMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(double.infinity, 80, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'settings',
          child: Text('设置'),
        ),
        const PopupMenuItem(
          value: 'about',
          child: Text('关于'),
        ),
      ],
    ).then((value) {
      if (!mounted) return;
      
      if (value == 'settings') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      } else if (value == 'about') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutPage()),
        );
      }
    });
  }

  // 复制消息内容到剪贴板
  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('内容已复制到剪贴板')),
    );
  }

  // 删除指定的消息（同时删除用户和AI的消息对）
  void _deleteMessage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条聊天记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        setState(() {
          final indicesToRemove = <int>{};
          
          if (_messages[index].isUser) {
            indicesToRemove.add(index);
            if (index + 1 < _messages.length && !_messages[index + 1].isUser) {
              indicesToRemove.add(index + 1);
            }
          } else {
            if (index - 1 >= 0 && _messages[index - 1].isUser) {
              indicesToRemove.add(index - 1);
            }
            indicesToRemove.add(index);
          }
          
          final sortedIndices = indicesToRemove.toList()..sort((a, b) => b.compareTo(a));
          for (final idx in sortedIndices) {
            _messages.removeAt(idx);
          }
        });
        _saveChatHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('狐狐伯特 - Offline节点'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _showMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: message.isUser ? Colors.blue[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: message.isUser
                        ? Text(
                            message.content,
                            style: TextStyle(
                              color: message.isUser ? Colors.blue[900] : Colors.black,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  message.content,
                                  style: TextStyle(
                                    color: message.isUser ? Colors.blue[900] : Colors.black,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16),
                                    onPressed: () => _copyMessage(message.content),
                                    padding: const EdgeInsets.all(4.0),
                                    constraints: const BoxConstraints(),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16),
                                    onPressed: () => _deleteMessage(index),
                                    padding: const EdgeInsets.all(4.0),
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),

          // 输入区域
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12.0),
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),

          // 加载指示器
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
