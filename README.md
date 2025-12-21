# 狐狐伯特 - Offline节点

一个基于Flutter开发的离线AI应用，支持Windows、Linux和Android平台。

## 项目介绍

这是一个纯客户端的AI应用。应用采用Flutter框架开发，支持跨平台运行在Windows、Linux和Android系统上。

## 主要特点

- **跨平台支持**：支持Windows、Linux和Android系统
- **简洁界面**：采用Material Design 3设计风格
- **易于扩展**：模块化架构，方便后续功能扩展

## 安装与运行

### 前置条件

- 安装Flutter SDK（推荐3.0+）
- 安装对应平台的开发环境：
  - Windows：Visual Studio
  - Linux：GCC/G++
  - Android：Android Studio

### 运行步骤

1. 克隆或下载项目

2. 进入client目录：
   ```bash
   cd client
   ```

3. 获取依赖：
   ```bash
   flutter pub get
   ```

4. 运行应用：
   
   - **Windows**：
     ```bash
     flutter run -d windows
     ```
   
   - **Linux**：
     ```bash
     flutter run -d linux
     ```
   
   - **Android**：
     ```bash
     flutter run -d android
     ```

## 构建发布版本

### Windows

```bash
flutter build windows
```

构建后的可执行文件位于：`client/build/windows/runner/Release/`

### Linux

```bash
flutter build linux
```

构建后的可执行文件位于：`client/build/linux/x64/release/bundle/`

### Android

```bash
flutter build apk
```

构建后的APK文件位于：`client/build/app/outputs/flutter-apk/`

## 开发说明

### 项目配置

主要配置文件位于`client/pubspec.yaml`，包含应用名称、版本、依赖等信息。

### 主要文件

- `client/lib/main.dart`：应用入口文件
- `client/lib/src/pages/home_page.dart`：首页组件

### 编码规范

项目使用Flutter官方推荐的编码规范，使用`flutter_lints`进行代码检查。

## 许可证

MIT License

## 联系方式

如有问题或建议，欢迎提交Issue或Pull Request。
