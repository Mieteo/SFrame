import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lựa chọn fps được hỗ trợ. `all` nghĩa là trích xuất toàn bộ frame gốc.
class FpsOption {
  final String value; // "all", "30", "25", "24", "15", "10"
  final String label;

  const FpsOption(this.value, this.label);

  static const FpsOption all = FpsOption('all', 'Tất cả frame');
  static const FpsOption fps30 = FpsOption('30', '30 fps');
  static const FpsOption fps25 = FpsOption('25', '25 fps');
  static const FpsOption fps24 = FpsOption('24', '24 fps');
  static const FpsOption fps15 = FpsOption('15', '15 fps');
  static const FpsOption fps10 = FpsOption('10', '10 fps');
  static const FpsOption fps5 = FpsOption('5', '5 fps');
  static const FpsOption fps2 = FpsOption('2', '2 fps');
  static const FpsOption fps1 = FpsOption('1', '1 fps');

  static const List<FpsOption> values = [
    all,
    fps30,
    fps25,
    fps24,
    fps15,
    fps10,
    fps5,
    fps2,
    fps1,
  ];

  static FpsOption fromValue(String value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => fps30,
    );
  }
}

/// Định dạng ảnh đầu ra.
enum OutputFormat {
  png('png', 'PNG'),
  jpg('jpg', 'JPG');

  final String value;
  final String label;
  const OutputFormat(this.value, this.label);

  static OutputFormat fromValue(String value) {
    return OutputFormat.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OutputFormat.png,
    );
  }
}

/// SettingsState — đọc/ghi cài đặt fps và định dạng ảnh từ SharedPreferences.
class SettingsState extends ChangeNotifier {
  static const String _kFpsKey = 'snap_frame_fps';
  static const String _kFormatKey = 'snap_frame_format';

  FpsOption _fps = FpsOption.fps30;
  OutputFormat _format = OutputFormat.png;
  bool _initialized = false;

  FpsOption get fps => _fps;
  OutputFormat get format => _format;
  bool get isInitialized => _initialized;

  /// Load từ disk; nên gọi 1 lần khi app khởi động.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _fps = FpsOption.fromValue(prefs.getString(_kFpsKey) ?? '30');
    _format = OutputFormat.fromValue(prefs.getString(_kFormatKey) ?? 'png');
    _initialized = true;
    notifyListeners();
  }

  Future<void> setFps(FpsOption value) async {
    if (_fps == value) return;
    _fps = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFpsKey, value.value);
  }

  Future<void> setFormat(OutputFormat value) async {
    if (_format == value) return;
    _format = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFormatKey, value.value);
  }
}
