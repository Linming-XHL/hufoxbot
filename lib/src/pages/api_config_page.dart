import 'package:flutter/material.dart';
import 'package:foxhu_bot_offline/src/services/storage_service.dart';
import 'package:foxhu_bot_offline/src/pages/home_page.dart';

class ApiConfigPage extends StatefulWidget {
  const ApiConfigPage({super.key});

  @override
  State<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends State<ApiConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _apiUrlController = TextEditingController(
    text: 'https://api.openai.com/v1', // 默认OpenAI API地址
  );
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelNameController = TextEditingController(
    text: 'gpt-3.5-turbo', // 默认模型
  );
  bool _isSaving = false;

  Future<void> _saveApiConfig() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      try {
        // 保存API配置信息
        await StorageService.saveApiConfig(
          apiUrl: _apiUrlController.text.trim(),
          apiKey: _apiKeyController.text.trim(),
          modelName: _modelNameController.text.trim(),
        );

        // 标记为已完成首次设置
        await StorageService.setFirstUse(false);

        // 导航到主页面
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API配置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '欢迎使用狐狐伯特 - Offline节点',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '请输入您的OpenAI API信息，以便应用能够与OpenAI服务通信。',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // API地址输入框
              TextFormField(
                controller: _apiUrlController,
                decoration: const InputDecoration(
                  labelText: 'OpenAI API地址',
                  hintText: 'https://api.openai.com/v1',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入API地址';
                  }
                  if (!value.startsWith('http')) {
                    return '请输入有效的URL地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // API Key输入框
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'OpenAI API Key',
                  hintText: 'sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入API Key';
                }
                return null;
              },
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // 模型名称输入框
              TextFormField(
                controller: _modelNameController,
                decoration: const InputDecoration(
                  labelText: '模型名称',
                  hintText: 'gpt-3.5-turbo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入模型名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveApiConfig,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('保存并继续'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }
}
