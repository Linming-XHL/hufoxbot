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
  int _contextMaxSize = 64;
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

      _contextMaxSize = await StorageService.getContextMaxSize();
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
        await StorageService.saveApiConfig(
          apiUrl: _apiUrlController.text.trim(),
          apiKey: _apiKeyController.text.trim(),
          modelName: _modelNameController.text.trim(),
        );

        await StorageService.saveContextMaxSize(_contextMaxSize);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('配置已保存')),
          );
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

                    const Text(
                      '上下文最大数据大小',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '最大数据大小: $_contextMaxSize KB',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Slider(
                      value: _contextMaxSize.toDouble(),
                      min: 8,
                      max: 128,
                      divisions: 15,
                      onChanged: (value) {
                        setState(() {
                          _contextMaxSize = value.toInt();
                        });
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
                            : const Text('保存配置'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _clearContext(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text(
                          '清空上下文',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '清除所有聊天记录，包括用户和AI的消息',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _clearContext(BuildContext context) async {
    String farewellMessage = '确定要清空所有聊天记录吗？此操作不可恢复。';

    try {
      final config = await StorageService.getApiConfig();
      if (config != null && mounted) {
        farewellMessage = await OpenAIService.getFarewellMessage();
      }
    } catch (e) {
      farewellMessage = '确定要清空所有聊天记录吗？此操作不可恢复。';
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: Text(farewellMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StorageService.clearAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('上下文已清空')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('清空失败: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }
}