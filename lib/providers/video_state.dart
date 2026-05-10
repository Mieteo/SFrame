import 'dart:io';

import 'package:flutter/foundation.dart';

/// Trạng thái xử lý chính của ứng dụng:
/// - File video đang chọn
/// - Khoảng thời gian cắt (begin / end, đơn vị giây)
/// - Loading / progress / lỗi khi cắt frame
/// - Danh sách path frame đã cắt (chia sẻ giữa các tab)
class VideoState extends ChangeNotifier {
  File? _videoFile;
  Duration _duration = Duration.zero;
  double _videoFps = 30; // fps gốc của video, ước lượng

  double _begin = 0; // giây
  double _end = 0; // giây

  bool _loadingVideo = false;
  bool _processing = false;
  String? _errorMessage;

  final List<String> _framePaths = [];

  /// Tăng mỗi lần `setFramePaths` được gọi. Các màn hình tiêu thụ frame
  /// (ResultScreen) so sánh id để biết "đây có phải kết quả mới không"
  /// và reset trạng thái cục bộ (vd: selection) khi cần.
  int _extractionId = 0;

  // Getters
  File? get videoFile => _videoFile;
  Duration get duration => _duration;
  double get videoFps => _videoFps;
  double get begin => _begin;
  double get end => _end;
  bool get loadingVideo => _loadingVideo;
  bool get processing => _processing;
  String? get errorMessage => _errorMessage;
  List<String> get framePaths => List.unmodifiable(_framePaths);
  int get extractionId => _extractionId;
  bool get hasVideo => _videoFile != null;

  double get durationSeconds => _duration.inMilliseconds / 1000.0;
  double get clipSeconds => (_end - _begin).clamp(0, durationSeconds);

  /// Số frame ước lượng dựa trên fps được cài đặt.
  int estimateFrameCount({required String fpsValue}) {
    final clip = clipSeconds;
    if (clip <= 0) return 0;
    final fps = fpsValue == 'all' ? _videoFps : double.tryParse(fpsValue) ?? 30;
    return (clip * fps).round();
  }

  void setLoadingVideo(bool value) {
    if (_loadingVideo == value) return;
    _loadingVideo = value;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Cập nhật khi video mới được mở thành công.
  void setVideo({
    required File file,
    required Duration duration,
    double fps = 30,
  }) {
    _videoFile = file;
    _duration = duration;
    _videoFps = fps;
    _begin = 0;
    // Mặc định chọn 5s đầu (hoặc cả video nếu ngắn hơn)
    _end = duration.inMilliseconds / 1000.0;
    if (_end > 5) _end = 5;
    _errorMessage = null;
    notifyListeners();
  }

  void clearVideo() {
    _videoFile = null;
    _duration = Duration.zero;
    _begin = 0;
    _end = 0;
    _errorMessage = null;
    notifyListeners();
  }

  void setRange(double begin, double end) {
    final maxSec = durationSeconds;
    _begin = begin.clamp(0, maxSec).toDouble();
    _end = end.clamp(_begin, maxSec).toDouble();
    notifyListeners();
  }

  void setProcessing(bool value) {
    if (_processing == value) return;
    _processing = value;
    notifyListeners();
  }

  void setFramePaths(List<String> paths) {
    _framePaths
      ..clear()
      ..addAll(paths);
    _extractionId++;
    notifyListeners();
  }

  void clearFrames() {
    _framePaths.clear();
    _extractionId++;
    notifyListeners();
  }
}
