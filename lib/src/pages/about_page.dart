import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int _versionTapCount = 0;
  DateTime? _lastTapTime;

  void _handleVersionTap() {
    setState(() {
      final now = DateTime.now();
      if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds < 3) {
        _versionTapCount++;
      } else {
        _versionTapCount = 1;
      }
      _lastTapTime = now;

      // 连续点击5次打开开发者页面
      if (_versionTapCount >= 5) {
        Navigator.pushNamed(context, '/developer');
        _versionTapCount = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Text(
                    '狐狐伯特 - Offline节点',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _handleVersionTap,
                    child: Text(
                      '版本 1.0.0',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '应用介绍',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '这是一个基于OpenAI API的AI客户端应用，支持Windows、Linux和Android平台。您可以通过配置自己的OpenAI API信息来使用各种AI功能。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              '功能特点',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• 支持自定义OpenAI API地址\n• 支持多种OpenAI模型\n• 简洁易用的聊天界面\n• 跨平台支持（Windows/Linux/Android）',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              '开发者信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'By 临明小狐狸',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}