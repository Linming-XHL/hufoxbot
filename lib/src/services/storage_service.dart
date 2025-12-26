import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFirstUse = 'first_use';
  static const String _keyApiUrl = 'api_url';
  static const String _keyApiKey = 'api_key';
  static const String _keyModelName = 'model_name';
  static const String _keyContextLength = 'context_max_size';
  static const String _keyChatHistory = 'chat_history';


  // 获取SharedPreferences实例
  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // 检查是否是第一次使用
  static Future<bool> isFirstUse() async {
    final prefs = await _getPrefs();
    // 默认是第一次使用
    return prefs.getBool(_keyFirstUse) ?? true;
  }

  // 设置是否是第一次使用
  static Future<bool> setFirstUse(bool value) async {
    final prefs = await _getPrefs();
    return prefs.setBool(_keyFirstUse, value);
  }

  // 保存API配置信息
  static Future<void> saveApiConfig({
    required String apiUrl,
    required String apiKey,
    required String modelName,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyApiUrl, apiUrl);
    await prefs.setString(_keyApiKey, apiKey);
    await prefs.setString(_keyModelName, modelName);
  }

  // 读取API配置信息
  static Future<Map<String, String>?> getApiConfig() async {
    final prefs = await _getPrefs();
    final apiUrl = prefs.getString(_keyApiUrl);
    final apiKey = prefs.getString(_keyApiKey);
    final modelName = prefs.getString(_keyModelName);

    // 如果任何一个配置项缺失，返回null
    if (apiUrl == null || apiKey == null || modelName == null) {
      return null;
    }

    return {
      'apiUrl': apiUrl,
      'apiKey': apiKey,
      'modelName': modelName,
    };
  }

  // 清除API配置信息
  static Future<void> clearApiConfig() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyApiUrl);
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyModelName);
    // 重置为第一次使用
    await setFirstUse(true);
  }

  // 保存上下文最大数据大小（8-128 KB）
  static Future<void> saveContextMaxSize(int sizeKB) async {
    final validSize = sizeKB.clamp(8, 128);
    final prefs = await _getPrefs();
    await prefs.setInt(_keyContextLength, validSize);
  }

  // 获取上下文最大数据大小
  static Future<int> getContextMaxSize() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_keyContextLength) ?? 64;
  }

  // 保存聊天记录
  static Future<void> saveChatHistory(String chatHistory) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyChatHistory, chatHistory);
  }

  // 获取聊天记录
  static Future<String?> getChatHistory() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyChatHistory);
  }

  // 清除聊天记录
  static Future<void> clearChatHistory() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyChatHistory);
  }

  // 清除所有数据（保留API配置）
  static Future<void> clearAllData() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyChatHistory);
  }
}
