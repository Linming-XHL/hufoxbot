import 'package:flutter/material.dart';
import 'package:foxhu_bot_offline/src/pages/home_page.dart';
import 'package:foxhu_bot_offline/src/pages/api_config_page.dart';
import 'package:foxhu_bot_offline/src/services/storage_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isFirstUse = true;

  @override
  void initState() {
    super.initState();
    _checkFirstUse();
  }

  // 检查是否是第一次使用
  Future<void> _checkFirstUse() async {
    try {
      _isFirstUse = await StorageService.isFirstUse();
    } catch (e) {
      debugPrint('检查第一次使用时出错: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // 显示加载界面
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: '狐狐伯特 - Offline节点',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // 根据是否是第一次使用导航到不同页面
      home: _isFirstUse ? const ApiConfigPage() : const HomePage(),
    );
  }
}
