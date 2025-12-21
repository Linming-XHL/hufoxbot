// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:foxhu_bot_offline/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // For a new app, it should show the API config page first
    // Verify that the API config page elements are present
    expect(find.text('API配置'), findsOneWidget);
    expect(find.text('OpenAI API地址'), findsOneWidget);
    expect(find.text('OpenAI API Key'), findsOneWidget);
    expect(find.text('模型名称'), findsOneWidget);
    expect(find.text('保存并继续'), findsOneWidget);
  });
}
