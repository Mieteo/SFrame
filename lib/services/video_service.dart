import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Kết quả phân tích video bằng ffprobe.
class VideoInfo {
  final Duration duration;
  final double fps;

  const VideoInfo({required this.duration, required this.fps});
}

/// Kết quả của quá trình cắt frame.
class ExtractResult {
  final bool success;
  final List<String> framePaths;
  final String? error;

  const ExtractResult({
    required this.success,
    required this.framePaths,
    this.error,
  });
}

/// Service bao quanh ffmpeg_kit_flutter để cắt frame từ video.
class VideoService {
  /// Lưu giữ session đang chạy để có thể hủy khi rời màn hình.
  static int? _currentSessionId;

  /// Phân tích video lấy duration + fps gốc bằng ffprobe.
  static Future<VideoInfo> probeVideo(String inputPath) async {
    final session = await FFprobeKit.getMediaInformation(inputPath);
    final info = session.getMediaInformation();
    if (info == null) {
      throw Exception('Không đọc được thông tin video');
    }

    Duration duration = Duration.zero;
    final durationStr = info.getDuration();
    if (durationStr != null) {
      final seconds = double.tryParse(durationStr) ?? 0.0;
      duration = Duration(milliseconds: (seconds * 1000).round());
    }

    double fps = 30.0;
    final streams = info.getStreams();
    for (final s in streams) {
      if (s.getType() == 'video') {
        final raw = s.getAverageFrameRate() ?? s.getRealFrameRate();
        if (raw != null && raw.contains('/')) {
          final parts = raw.split('/');
          final num = double.tryParse(parts[0]);
          final den = double.tryParse(parts[1]);
          if (num != null && den != null && den != 0) {
            fps = num / den;
          }
        } else if (raw != null) {
          fps = double.tryParse(raw) ?? fps;
        }
        break;
      }
    }

    return VideoInfo(duration: duration, fps: fps);
  }

  /// Cắt frame từ video. Trả về danh sách path ảnh đã sinh ra.
  ///
  /// [fpsValue]: "all" để trích toàn bộ frame, hoặc số fps mong muốn ("30", "24"...)
  /// [format]: "png" hoặc "jpg".
  static Future<ExtractResult> extractFrames({
    required String inputPath,
    required double beginSeconds,
    required double endSeconds,
    required String fpsValue,
    required String format,
  }) async {
    try {
      final duration = endSeconds - beginSeconds;
      if (duration <= 0) {
        return const ExtractResult(
          success: false,
          framePaths: [],
          error: 'Khoảng thời gian không hợp lệ',
        );
      }

      // Mỗi lần cắt tạo 1 thư mục riêng để tránh ghi đè kết quả cũ.
      final tmpRoot = await getTemporaryDirectory();
      final outDir = Directory(
        p.join(
          tmpRoot.path,
          'snap_frame',
          'frames_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await outDir.create(recursive: true);

      final ext = format.toLowerCase();
      final pattern = p.join(outDir.path, 'frame_%04d.$ext');

      // Build danh sách argument — dùng executeWithArguments để tránh
      // vấn đề escape khi path có khoảng trắng / ký tự đặc biệt.
      final args = <String>[
        '-y',
        '-ss', beginSeconds.toStringAsFixed(3),
        '-i', inputPath,
        '-t', duration.toStringAsFixed(3),
      ];

      if (fpsValue == 'all') {
        // -vsync 0 (passthrough) trích xuất mọi frame trong khoảng đã chọn.
        args.addAll(['-vsync', '0']);
      } else {
        args.addAll(['-vf', 'fps=$fpsValue']);
      }

      if (ext == 'jpg' || ext == 'jpeg') {
        args.addAll(['-q:v', '2']);
      }

      args.add(pattern);

      final session = await FFmpegKit.executeWithArguments(args);
      _currentSessionId = session.getSessionId();
      final returnCode = await session.getReturnCode();
      _currentSessionId = null;

      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        return ExtractResult(
          success: false,
          framePaths: const [],
          error: 'FFmpeg lỗi: ${logs ?? 'unknown'}',
        );
      }

      // Liệt kê output theo thứ tự.
      final files = outDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.$ext'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      return ExtractResult(
        success: true,
        framePaths: files.map((f) => f.path).toList(),
      );
    } catch (e) {
      return ExtractResult(
        success: false,
        framePaths: const [],
        error: e.toString(),
      );
    }
  }

  /// Hủy tiến trình FFmpeg đang chạy (nếu có).
  static Future<void> cancel() async {
    final id = _currentSessionId;
    if (id != null) {
      await FFmpegKit.cancel(id);
      _currentSessionId = null;
    }
  }
}
