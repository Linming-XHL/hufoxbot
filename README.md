# 狐狐伯特 - Offline节点

一个基于 Flutter 和 OpenAI API 的离线 AI 聊天应用。

## 功能特性

- 智能对话 - 支持 OpenAI API 格式的兼容模型
- 消息管理 - 支持消息复制、删除功能
- 灵活配置 - 可自定义 API 地址、模型名称
- 数据持久化 - 聊天记录自动保存
- 个性化人格 - 支持自定义 AI 人格设定
- 开发者模式 - 支持直接编辑所有配置数据
- 隐私保护 - 本地存储，无云端数据同步

## 系统要求

- Flutter 3.0.0 或更高版本
- Dart 3.0.0 或更高版本
- Android API 21+ / iOS 11+

## 安装说明

### Android

1. 确保已配置 Android 开发环境
2. 连接设备或启动模拟器
3. 执行以下命令：

```bash
cd client
flutter build apk --release
```

生成的 APK 文件位于 `build/app/outputs/apk/release/` 目录。

### iOS

```bash
cd client
flutter build ios --release
```

## 配置说明

首次使用需要配置 API 信息：

1. 打开应用，进入设置页面
2. 配置以下参数：
   - **API URL**: OpenAI 兼容的 API 地址（如 `https://api.openai.com/v1`）
   - **API Key**: 您的 API 密钥（支持任意非空格式）
   - **模型名称**: 使用的模型名称（如 `gpt-3.5-turbo`、`gpt-4`）
3. 可选：配置上下文大小（8KB ~ 128KB，默认 64KB）

## 项目结构

```
foxhu_bot_offline/
├── client/                    # Flutter 应用
│   ├── lib/
│   │   ├── src/
│   │   │   ├── pages/        # 页面组件
│   │   │   │   ├── home_page.dart
│   │   │   │   ├── settings_page.dart
│   │   │   │   ├── api_config_page.dart
│   │   │   │   ├── developer_page.dart
│   │   │   │   └── about_page.dart
│   │   │   ├── services/     # 服务层
│   │   │   │   ├── openai_service.dart
│   │   │   │   └── storage_service.dart
│   │   │   └── widgets/      # 公共组件
│   │   └── main.dart
│   ├── android/              # Android 配置
│   ├── assets/
│   │   ├── fonts/           # 字体资源
│   │   ├── images/          # 图片资源
│   │   └── personality/     # 人格设定
│   └── pubspec.yaml
└── README.md
```

## 技术栈

- **Flutter** - 跨平台 UI 框架
- **Dart** - 编程语言
- **SharedPreferences** - 本地数据存储
- **http** - HTTP 请求库

## 版本历史

### v1.1.0

- 新增消息复制/删除功能
- 优化上下文控制（基于数据大小而非消息数量）
- 新增开发者页面
- 优化用户界面

### v1.0.0

- 初始版本发布

## 致谢

- [Flutter](https://flutter.dev/) - 优秀的跨平台框架
- [OpenAI](https://openai.com/) - 强大的语言模型
- [狐狐伯特原开发者] - 项目基础

---

*狐狐伯特 - Offline节点 © 2025*
