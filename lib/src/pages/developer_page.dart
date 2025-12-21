import 'package:flutter/material.dart';
import 'package:foxhu_bot_offline/src/services/storage_service.dart';

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  String _aiMemoryContent = '';
  String _chatHistoryContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 加载AI记忆文件
      final aiMemory = await StorageService.getAIMemory() ?? '无AI记忆内容';
      
      // 加载聊天记录文件
      final chatHistory = await StorageService.getChatHistory() ?? '无聊天记录内容';

      setState(() {
        _aiMemoryContent = aiMemory;
        _chatHistoryContent = chatHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiMemoryContent = '加载AI记忆失败: $e';
        _chatHistoryContent = '加载聊天记录失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('开发者页面'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI记忆文件内容
                  const Text(
                    'AI记忆文件内容:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        _aiMemoryContent,
                        style: const TextStyle(fontFamily: 'Monospace'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 聊天记录文件内容
                  const Text(
                    '聊天记录文件内容:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        _chatHistoryContent,
                        style: const TextStyle(fontFamily: 'Monospace'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}