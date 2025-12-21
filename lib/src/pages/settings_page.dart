import 'package:flutter/material.dart';
import 'package:foxhu_bot_offline/src/services/storage_service.dart';
import 'package:foxhu_bot_offline/src/services/openai_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelNameController = TextEditingController();
  int _contextLength = 4;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    try {
      final config = await StorageService.getApiConfig();
      if (config != null) {
        _apiUrlController.text = config['apiUrl']!;
        _apiKeyController.text = config['apiKey']!;
        _modelNameController.text = config['modelName']!;
      }

      // 加载上下文长度设置
      _contextLength = await StorageService.getContextLength();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载配置失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

        // 保存上下文长度设置
        await StorageService.saveContextLength(_contextLength);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('配置已保存')),
          );
          // 返回上一页
          Navigator.pop(context);
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

  Future<void> _clearAIMemory() async {
    try {
      // 获取当前AI记忆
      final memory = await StorageService.getAIMemory();
      String confirmationMessage = '确定要清除AI记忆吗？此操作不可恢复。';
      
      // 如果有记忆，调用AI生成挽留文本
      if (memory != null && memory.isNotEmpty) {
        setState(() {
          _isLoading = true;
        });
        
        // 调用AI生成挽留文本
        final prompt = '请帮我生成一段简短的提示语，用于确认是否要清除AI记忆。提示语要友好、有挽留性，不要太长。以下是当前的记忆内容：\n$memory';
        final retentionMessage = await OpenAIService.getAIResponse(prompt);
        confirmationMessage = retentionMessage;
        
        setState(() {
          _isLoading = false;
        });
      }
      
      // 二次确认对话框
      if (!mounted) return;
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('清除AI记忆'),
          content: Text(confirmationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认清除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
      
      // 如果用户确认，清除记忆
      if (confirmed) {
        await StorageService.clearAIMemory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI记忆已清除')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清除记忆失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OpenAI 配置',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

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

                    const SizedBox(height: 24),

                    // 上下文长度设置
                    const Text(
                      '上下文长度设置',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '上下文长度: $_contextLength 条',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Slider(
                      value: _contextLength.toDouble(),
                      min: 2,
                      max: 7,
                      divisions: 5,
                      onChanged: (value) {
                        setState(() {
                          _contextLength = value.toInt();
                        });
                      },
                    ),
                    const Text(
                      '设置AI可以记住的历史消息数量（2-7条）',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
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
                            : const Text('保存配置'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 清除记忆按钮
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _clearAIMemory,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('清除AI记忆'),
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