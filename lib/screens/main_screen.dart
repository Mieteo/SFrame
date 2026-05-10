import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../providers/settings_state.dart';
import '../providers/video_state.dart';
import '../services/video_service.dart';
import '../theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  /// Gọi khi cần chuyển sang tab khác (vd: sang tab Kết quả sau khi cắt xong).
  final void Function(int index) onSwitchTab;

  const MainScreen({super.key, required this.onSwitchTab});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  VideoPlayerController? _controller;
  String? _controllerForPath; // tránh khởi tạo lại controller cho cùng 1 file

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initController(File file) async {
    if (_controllerForPath == file.path && _controller != null) return;
    await _controller?.dispose();
    final controller = VideoPlayerController.file(file);
    _controller = controller;
    _controllerForPath = file.path;
    try {
      await controller.initialize();
      if (mounted) setState(() {});
      controller.addListener(_onVideoTick);
    } catch (_) {
      // VideoPlayer khởi tạo lỗi sẽ không chặn flow chính (FFmpeg vẫn xử lý được).
    }
  }

  void _onVideoTick() {
    if (mounted) setState(() {});
  }

  Future<void> _pickVideo() async {
    final state = context.read<VideoState>();
    state.setError(null);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);

      state.setLoadingVideo(true);

      // Phân tích video song song với khởi tạo player.
      final info = await VideoService.probeVideo(file.path);
      state.setVideo(file: file, duration: info.duration, fps: info.fps);
      await _initController(file);
    } catch (e) {
      state.setError('Không thể tải video: $e');
    } finally {
      state.setLoadingVideo(false);
    }
  }

  Future<void> _togglePlay() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (ctrl.value.isPlaying) {
      await ctrl.pause();
    } else {
      await ctrl.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _startExtract() async {
    final video = context.read<VideoState>();
    final settings = context.read<SettingsState>();

    if (video.videoFile == null) return;
    if (video.clipSeconds <= 0) {
      _showSnack('Khoảng thời gian không hợp lệ');
      return;
    }

    await _controller?.pause();
    video.setProcessing(true);
    video.setError(null);

    final result = await VideoService.extractFrames(
      inputPath: video.videoFile!.path,
      beginSeconds: video.begin,
      endSeconds: video.end,
      fpsValue: settings.fps.value,
      format: settings.format.value,
    );

    video.setProcessing(false);

    if (!mounted) return;

    if (result.success) {
      video.setFramePaths(result.framePaths);
      _showSnack('Đã cắt ${result.framePaths.length} frame');
      widget.onSwitchTab(1); // chuyển sang tab Kết quả
    } else {
      video.setError(result.error);
      _showSnack(result.error ?? 'Cắt frame thất bại');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatTime(double seconds) {
    final total = seconds.round();
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final video = context.watch<VideoState>();
    final settings = context.watch<SettingsState>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Snap Frame'),
        actions: [
          IconButton(
            tooltip: 'Thông tin',
            onPressed: () => _showInfo(context),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SelectVideoButton(onTap: _pickVideo),
              const SizedBox(height: 24),
              _VideoPreview(
                controller: _controller,
                hasVideo: video.hasVideo,
                loading: video.loadingVideo,
                onTogglePlay: _togglePlay,
              ),
              const SizedBox(height: 24),
              _RangeSection(
                begin: video.begin,
                end: video.end,
                duration: video.durationSeconds,
                enabled: video.hasVideo && !video.processing,
                onChanged: (begin, end) =>
                    context.read<VideoState>().setRange(begin, end),
                formatTime: _formatTime,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      label: 'Thời lượng cắt',
                      value:
                          '${video.clipSeconds.toStringAsFixed(0).padLeft(2, '0')} giây',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _InfoCard(
                      label: 'Số lượng frame',
                      value:
                          '${video.estimateFrameCount(fpsValue: settings.fps.value)} ảnh',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: (video.hasVideo &&
                        !video.processing &&
                        video.clipSeconds > 0)
                    ? _startExtract
                    : null,
                icon: video.processing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.content_cut_rounded),
                label: Text(video.processing
                    ? 'Đang cắt...'
                    : 'Bắt đầu cắt frame'),
              ),
              if (video.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  video.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Snap Frame'),
        content: const Text(
          'Chọn video, kéo thanh trượt để chọn khoảng cần cắt frame, '
          'sau đó nhấn "Bắt đầu cắt frame". Cài đặt fps & định dạng ảnh '
          'tại tab Cài đặt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ────────────────────────────────────────────────────────────────────────────

class _SelectVideoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SelectVideoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.folder_open_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Text(
              'Chọn video',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool hasVideo;
  final bool loading;
  final VoidCallback onTogglePlay;

  const _VideoPreview({
    required this.controller,
    required this.hasVideo,
    required this.loading,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    final initialized = controller?.value.isInitialized ?? false;
    final isPlaying = controller?.value.isPlaying ?? false;
    final aspectRatio = (initialized && controller!.value.aspectRatio > 0)
        ? controller!.value.aspectRatio
        : 16 / 9;
    final position = controller?.value.position ?? Duration.zero;
    final total = controller?.value.duration ?? Duration.zero;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),
            if (initialized) VideoPlayer(controller!),
            if (loading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Đang tải...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              )
            else if (!hasVideo)
              const Center(
                child: Icon(
                  Icons.movie_outlined,
                  color: Colors.white54,
                  size: 56,
                ),
              )
            else
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTogglePlay,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isPlaying ? 0 : 1,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            if (initialized)
              Positioned(
                left: 12,
                right: 12,
                bottom: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      controller!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: AppColors.primary,
                        backgroundColor: Colors.white24,
                        bufferedColor: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _format(position),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _format(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class _RangeSection extends StatelessWidget {
  final double begin;
  final double end;
  final double duration;
  final bool enabled;
  final void Function(double, double) onChanged;
  final String Function(double) formatTime;

  const _RangeSection({
    required this.begin,
    required this.end,
    required this.duration,
    required this.enabled,
    required this.onChanged,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = duration > 0 ? duration : 1.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KHOẢNG THỜI GIAN CẮT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '${formatTime(begin)} - ${formatTime(end)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          IgnorePointer(
            ignoring: !enabled,
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: RangeSlider(
                values: RangeValues(begin, end),
                min: 0,
                max: maxValue,
                labels: RangeLabels(formatTime(begin), formatTime(end)),
                onChanged: (v) => onChanged(v.start, v.end),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatTime(begin),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  formatTime(end),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
