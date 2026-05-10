import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap_frame/providers/settings_state.dart';
import 'package:snap_frame/providers/video_state.dart';
import 'package:snap_frame/screens/home_screen.dart';
import 'package:snap_frame/theme/app_theme.dart';

void main() {
  testWidgets('App khởi động hiển thị tab Chính', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final settings = SettingsState();
    await settings.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsState>.value(value: settings),
          ChangeNotifierProvider<VideoState>(create: (_) => VideoState()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HomeScreen(),
        ),
      ),
    );

    expect(find.text('Snap Frame'), findsWidgets);
    expect(find.text('Chọn video'), findsOneWidget);
    expect(find.text('Bắt đầu cắt frame'), findsOneWidget);
  });
}
