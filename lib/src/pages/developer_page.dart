import 'package:flutter/material.dart';
import 'package:foxhu_bot_offline/src/services/storage_service.dart';

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  final Map<String, dynamic> _data = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final apiConfig = await StorageService.getApiConfig();
    final contextMaxSize = await StorageService.getContextMaxSize();
    final chatHistory = await StorageService.getChatHistory();

    setState(() {
      _data['apiUrl'] = apiConfig?['apiUrl'] ?? '';
      _data['apiKey'] = apiConfig?['apiKey'] ?? '';
      _data['modelName'] = apiConfig?['modelName'] ?? '';
      _data['contextMaxSize'] = contextMaxSize.toString();
      _data['chatHistory'] = chatHistory ?? '';

      _controllers['apiUrl'] = TextEditingController(text: _data['apiUrl']);
      _controllers['apiKey'] = TextEditingController(text: _data['apiKey']);
      _controllers['modelName'] = TextEditingController(text: _data['modelName']);
      _controllers['contextMaxSize'] = TextEditingController(text: _data['contextMaxSize']);
      _controllers['chatHistory'] = TextEditingController(text: _data['chatHistory']);

      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    try {
      await StorageService.saveApiConfig(
        apiUrl: _controllers['apiUrl']!.text,
        apiKey: _controllers['apiKey']!.text,
        modelName: _controllers['modelName']!.text,
      );

      final contextSize = int.tryParse(_controllers['contextMaxSize']!.text) ?? 64;
      await StorageService.saveContextMaxSize(contextSize);

      await StorageService.saveChatHistory(_controllers['chatHistory']!.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有数据吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearApiConfig();
      await StorageService.clearChatHistory();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清除所有数据')),
        );
      }
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key, {int maxLines = 3, bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        TextField(
          controller: _controllers[key],
          maxLines: maxLines,
          obscureText: obscure,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('开发者模式'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveData,
            tooltip: '保存',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearAllData,
            tooltip: '清除所有数据',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildSection('API配置', [
                  _buildTextField('API URL', 'apiUrl'),
                  _buildTextField('API Key', 'apiKey', obscure: true, maxLines: 1),
                  _buildTextField('模型名称', 'modelName'),
                ]),
                _buildSection('上下文设置', [
                  _buildTextField('上下文最大大小 (KB)', 'contextMaxSize', maxLines: 1),
                ]),
                _buildSection('聊天记录', [
                  _buildTextField('Chat History (JSON)', 'chatHistory', maxLines: 15),
                ]),
              ],
            ),
    );
  }
}
