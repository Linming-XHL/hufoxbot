import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:foxhu_bot_offline/src/services/storage_service.dart';

class OpenAIService {
  static Future<String> _getPersonality() async {
    try {
      final content = await rootBundle.loadString('assets/personality/default.txt');
      return content;
    } catch (e) {
      return '你是狐狐伯特，一只可爱的小狐狸AI助手。你总是用友好、活泼的语气与用户交流。';
    }
  }
  
  static Future<String> getAIResponse(String message) async {
    final config = await StorageService.getApiConfig();
    if (config == null) {
      throw Exception('API配置信息缺失，请重新配置');
    }

    final apiUrl = config['apiUrl']!;
    final apiKey = config['apiKey']!;
    final modelName = config['modelName']!;

    final url = Uri.parse('$apiUrl/chat/completions');

    final personality = await _getPersonality();
    
    final systemContent = personality;
    final messagesYaml = _buildYamlMessages(systemContent, message, null);
    final totalSize = utf8.encode(messagesYaml).length;
    
    print('发送数据总大小: ${totalSize}B / ${(totalSize / 1024).toStringAsFixed(2)} KB');
    
    final requestBody = json.encode({
      'model': modelName,
      'messages': [
        {
          'role': 'system',
          'content': systemContent,
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
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: requestBody,
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception('API请求失败: ${errorData['error']['message']}');
      }

      final responseData = json.decode(response.body);
      return responseData['choices'][0]['message']['content'];
    } catch (e) {
      throw Exception('获取AI响应失败: $e');
    }
  }

  static Stream<String> getAIStreamResponse(String message, {List<Map<String, dynamic>>? context}) async* {
    final config = await StorageService.getApiConfig();
    if (config == null) {
      throw Exception('API配置信息缺失，请重新配置');
    }

    final apiUrl = config['apiUrl']!;
    final apiKey = config['apiKey']!;
    final modelName = config['modelName']!;

    final url = Uri.parse('$apiUrl/chat/completions');

    final personality = await _getPersonality();
    
    final systemContent = personality;
    final messagesYaml = _buildYamlMessages(systemContent, message, context);
    final totalSize = utf8.encode(messagesYaml).length;
    
    print('发送数据总大小: ${totalSize}B / ${(totalSize / 1024).toStringAsFixed(2)} KB');
    
    final messages = [
      {
        'role': 'system',
        'content': systemContent,
      },
    ];

    if (context != null && context.isNotEmpty) {
      final stringContext = context.map((msg) => {
        'role': msg['role'] as String,
        'content': msg['content'] as String,
      }).toList();
      messages.addAll(stringContext);
    }

    messages.add({
      'role': 'user',
      'content': message,
    });

    final requestBody = json.encode({
      'model': modelName,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 1000,
      'stream': true,
    });

    try {
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      });
      request.body = requestBody;

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        final errorData = await response.stream.bytesToString();
        throw Exception('API请求失败: $errorData');
      }

      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        
        while (buffer.contains('\n\n')) {
          final messageEndIndex = buffer.indexOf('\n\n');
          final messageData = buffer.substring(0, messageEndIndex).trim();
          buffer = buffer.substring(messageEndIndex + 2);

          if (messageData.isEmpty) continue;
          if (messageData == 'data: [DONE]') return;

          if (messageData.startsWith('data: ')) {
            final data = messageData.substring(6);
            try {
              final jsonData = json.decode(data);
              final content = jsonData['choices'][0]['delta']['content'];
              if (content != null) {
                yield content;
              }
            } catch (e) {
            }
          }
        }
      }
    } catch (e) {
      throw Exception('获取AI响应失败: $e');
    }
  }

  static String _buildYamlMessages(String systemContent, String userMessage, List<Map<String, dynamic>>? context) {
    final buffer = StringBuffer();
    
    buffer.writeln('---');
    buffer.writeln('system: |');
    systemContent.split('\n').forEach((line) {
      buffer.writeln('  $line');
    });
    
    if (context != null) {
      for (final msg in context) {
        buffer.writeln('- role: ${msg['role']}');
        buffer.writeln('  content: |');
        (msg['content'] as String).split('\n').forEach((line) {
          buffer.writeln('    $line');
        });
      }
    }
    
    buffer.writeln('- role: user');
    buffer.writeln('  content: |');
    userMessage.split('\n').forEach((line) {
      buffer.writeln('    $line');
    });
    
    return buffer.toString();
  }

  static Future<String> getFarewellMessage() async {
    final config = await StorageService.getApiConfig();
    if (config == null) {
      throw Exception('API配置信息缺失，请重新配置');
    }

    final apiUrl = config['apiUrl']!;
    final apiKey = config['apiKey']!;
    final modelName = config['modelName']!;

    final url = Uri.parse('$apiUrl/chat/completions');

    final personality = await _getPersonality();
    final systemContent = '$personality\n\n用户即将清空所有聊天记录，请用撒娇的语气挽留用户，阻止他们清空聊天记录。保持简短，大概50字左右。';

    final requestBody = json.encode({
      'model': modelName,
      'messages': [
        {
          'role': 'system',
          'content': systemContent,
        },
      ],
      'temperature': 0.9,
      'max_tokens': 200,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: requestBody,
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception('API请求失败: ${errorData['error']['message']}');
      }

      final responseData = json.decode(response.body);
      return responseData['choices'][0]['message']['content'];
    } catch (e) {
      throw Exception('获取挽留信息失败: $e');
    }
  }
}
