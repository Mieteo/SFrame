import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/settings_state.dart';
import 'providers/video_state.dart';
import 'screens/home_screen.dart';
import 'services/video_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Khởi tạo settings từ SharedPreferences trước khi runApp.
  // Bọc try/catch: nếu plugin shared_preferences fail (vd: channel-error trên
  // release mode khi R8 strip class pigeon), app vẫn khởi động được với giá trị
  // mặc định thay vì treo trắng màn hình do exception không bắt được.
  final settings = SettingsState();
  try {
    await settings.load();
  } catch (e, st) {
    debugPrint('SettingsState.load() failed, dùng giá trị mặc định: $e\n$st');
  }

  runApp(SnapFrameApp(settings: settings));
}

class SnapFrameApp extends StatefulWidget {
  final SettingsState settings;
  const SnapFrameApp({super.key, required this.settings});

  @override
  State<SnapFrameApp> createState() => _SnapFrameAppState();
}

class _SnapFrameAppState extends State<SnapFrameApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Đảm bảo hủy session FFmpeg khi app thoát.
    VideoService.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      VideoService.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsState>.value(value: widget.settings),
        ChangeNotifierProvider<VideoState>(create: (_) => VideoState()),
      ],
      child: MaterialApp(
        title: 'Snap Frame',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const HomeScreen(),
      ),
    );
  }
}
