import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:foxhu_bot_offline/src/services/storage_service.dart';

class OpenAIService {
  // 读取AI人格配置
  static Future<String> _getPersonality() async {
    try {
      final content = await rootBundle.loadString('assets/personality/default.txt');
      return content;
    } catch (e) {
      // 如果读取失败，返回默认人格
      return '你是狐狐伯特，一只可爱的小狐狸AI助手。你总是用友好、活泼的语气与用户交流。';
    }
  }
  
  // 获取AI响应（非流式）
  static Future<String> getAIResponse(String message) async {
    // 获取API配置信息
    final config = await StorageService.getApiConfig();
    if (config == null) {
      throw Exception('API配置信息缺失，请重新配置');
    }

    final apiUrl = config['apiUrl']!;
    final apiKey = config['apiKey']!;
    final modelName = config['modelName']!;

    // 构建请求URL
    final url = Uri.parse('$apiUrl/chat/completions');

    // 获取AI人格配置
    final personality = await _getPersonality();
    
    // 获取AI记忆
    final memory = await StorageService.getAIMemory();
    
    // 构建请求体
    final requestBody = json.encode({
      'model': modelName,
      'messages': [
        {
          'role': 'system',
          'content': '$personality${memory != null ? '\n\n记忆信息：$memory' : ''}',
        },
        {
          'role': 'user',
          'content': message,
        },
      ],
      'temperature': 0.7,
      'max_tokens': 1000,
    });

    try {
      // 发送POST请求
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: requestBody,
      );

      // 检查响应状态
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception('API请求失败: ${errorData['error']['message']}');
      }

      // 解析响应数据
      final responseData = json.decode(response.body);
      return responseData['choices'][0]['message']['content'];
    } catch (e) {
      throw Exception('获取AI响应失败: $e');
    }
  }

  // 获取AI响应（流式）
  static Stream<String> getAIStreamResponse(String message, {List<Map<String, dynamic>>? context}) async* {
    // 获取API配置信息
    final config = await StorageService.getApiConfig();
    if (config == null) {
      throw Exception('API配置信息缺失，请重新配置');
    }

    final apiUrl = config['apiUrl']!;
    final apiKey = config['apiKey']!;
    final modelName = config['modelName']!;

    // 构建请求URL
    final url = Uri.parse('$apiUrl/chat/completions');

    // 获取AI人格配置
    final personality = await _getPersonality();
    
    // 获取AI记忆
    final memory = await StorageService.getAIMemory();
    
    // 构建消息列表
    final messages = [
      {
        'role': 'system',
        'content': '$personality${memory != null ? '\n\n记忆信息：$memory' : ''}',
      },
    ];

    // 添加上下文（如果有）
    if (context != null && context.isNotEmpty) {
      // 转换上下文类型
      final stringContext = context.map((msg) => {
        'role': msg['role'] as String,
        'content': msg['content'] as String,
      }).toList();
      messages.addAll(stringContext);
    }

    // 添加当前用户消息
    messages.add({
      'role': 'user',
      'content': message,
    });

    // 构建请求体
    final requestBody = json.encode({
      'model': modelName,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 1000,
      'stream': true, // 启用流式响应
    });

    try {
      // 发送POST请求并获取响应流
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      });
      request.body = requestBody;

      final response = await http.Client().send(request);

      // 检查响应状态
      if (response.statusCode != 200) {
        final errorData = await response.stream.bytesToString();
        throw Exception('API请求失败: $errorData');
      }

      // 解析SSE格式的响应流
      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        
        // 分割消息
        while (buffer.contains('\n\n')) {
          final messageEndIndex = buffer.indexOf('\n\n');
          final message = buffer.substring(0, messageEndIndex).trim();
          buffer = buffer.substring(messageEndIndex + 2);

          if (message.isEmpty) continue;
          if (message == 'data: [DONE]') break;

          // 提取data字段
          if (message.startsWith('data: ')) {
            final data = message.substring(6);
            try {
              final jsonData = json.decode(data);
              final content = jsonData['choices'][0]['delta']['content'];
              if (content != null) {
                yield content;
              }
            } catch (e) {
              // 忽略无效的JSON
            }
          }
        }
      }
    } catch (e) {
      throw Exception('获取AI响应失败: $e');
    }
  }
}
