import 'dart:io';

import 'package:flutter/material.dart';

/// Màn xem ảnh fullscreen, hoàn toàn điều khiển bằng cử chỉ tay:
///
/// - Pinch out (xoè ngón) → phóng to, focal point bám theo điểm chụm
///   (xử lý sẵn bởi `InteractiveViewer`).
/// - Pinch in (chụm ngón) → thu nhỏ, clamp ở minScale = 1.
/// - Double-tap khi zoom = 1 → phóng to focus tại điểm tap.
/// - Double-tap khi zoom > 1 → reset về zoom = 1, ảnh canh giữa.
/// - Khi pinch in chạm scale 1 → tự animate về identity (ảnh canh giữa).
/// - Vuốt ngang để chuyển ảnh khác (`PageView`); khi đang zoom thì khoá vuốt
///   để pan không xung đột với chuyển trang.
class FrameViewerScreen extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const FrameViewerScreen({
    super.key,
    required this.paths,
    required this.initialIndex,
  });

  @override
  State<FrameViewerScreen> createState() => _FrameViewerScreenState();
}

class _FrameViewerScreenState extends State<FrameViewerScreen>
    with SingleTickerProviderStateMixin {
  static const double _minScale = 1.0;
  static const double _maxScale = 6.0;

  /// Khi scale rơi xuống dưới ngưỡng này (cộng dung sai nhỏ) → coi như user
  /// muốn "đặt lại" → animate về identity.
  static const double _resetThreshold = 1.001;

  /// Mức zoom khi double-tap để phóng to. Giữ thấp (1.2x) để focal-point
  /// translate không quá mạnh — tap lệch khỏi tâm ảnh chỉ làm ảnh dịch nhẹ
  /// thay vì văng ra ngoài viewport.
  static const double _doubleTapZoomScale = 1.2;

  late final PageController _pageController;
  late int _currentIndex;

  /// Mỗi page giữ controller riêng để zoom level không lan sang ảnh khác.
  final Map<int, TransformationController> _controllers = {};

  /// Theo dõi state zoom của page hiện tại để khoá vuốt PageView khi đang zoom.
  bool _isZoomed = false;

  /// Animation đưa Matrix về một target (reset hoặc zoom-in tại điểm tap).
  late final AnimationController _matrixAnimController;
  Animation<Matrix4>? _matrixAnim;
  TransformationController? _animatingController;

  /// Vị trí double-tap gần nhất (lưu từ `onDoubleTapDown`) để dùng khi
  /// `onDoubleTap` trigger — vì callback double-tap không kèm position.
  Offset? _lastDoubleTapPosition;

  TransformationController _controllerFor(int index) {
    return _controllers.putIfAbsent(index, () => TransformationController());
  }

  TransformationController get _currentController =>
      _controllerFor(_currentIndex);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _currentController.addListener(_onTransformChanged);

    _matrixAnimController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    )..addListener(_onMatrixAnimTick);
  }

  @override
  void dispose() {
    _matrixAnimController
      ..removeListener(_onMatrixAnimTick)
      ..dispose();
    _currentController.removeListener(_onTransformChanged);
    for (final c in _controllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _currentController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed != _isZoomed && mounted) {
      setState(() => _isZoomed = zoomed);
    }
  }

  void _onMatrixAnimTick() {
    final anim = _matrixAnim;
    final ctrl = _animatingController;
    if (anim != null && ctrl != null) {
      ctrl.value = anim.value;
    }
  }

  /// Animate matrix của controller hiện tại tới [target]. Nếu animation đang
  /// chạy thì khởi tạo lại tween từ giá trị hiện tại để trông liền mạch.
  void _animateMatrixTo(Matrix4 target) {
    _animatingController = _currentController;
    _matrixAnim = Matrix4Tween(
      begin: _currentController.value,
      end: target,
    ).animate(
      CurvedAnimation(parent: _matrixAnimController, curve: Curves.easeOut),
    );
    _matrixAnimController.forward(from: 0);
  }

  void _animateReset() => _animateMatrixTo(Matrix4.identity());

  /// Tạo matrix scale ảnh quanh điểm [focalPoint] (toạ độ trong viewport)
  /// sao cho điểm đó vẫn ở nguyên vị trí sau khi scale.
  ///
  /// Công thức cho ánh xạ 2D: viewport_pos = scale·child_pos + (1-scale)·P
  /// → matrix dạng:
  ///   | s  0  0  (1-s)·px |
  ///   | 0  s  0  (1-s)·py |
  ///   | 0  0  1     0     |
  ///   | 0  0  0     1     |
  ///
  /// Cố tình giữ z-scale = 1 (không scale theo trục z) để Matrix4Tween khi
  /// decompose-recompose không sinh component lạ làm ảnh nhảy ra ngoài.
  Matrix4 _zoomAroundMatrix(Offset focalPoint, double scale) {
    final px = focalPoint.dx;
    final py = focalPoint.dy;
    return Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, (1 - scale) * px)
      ..setEntry(1, 3, (1 - scale) * py);
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _lastDoubleTapPosition = details.localPosition;
  }

  void _onDoubleTap() {
    final scale = _currentController.value.getMaxScaleOnAxis();
    if (scale > _resetThreshold) {
      // Đang zoom → reset về zoom = 1.
      _animateReset();
    } else {
      // Đang ở 1x → zoom in tại điểm vừa tap.
      final pos = _lastDoubleTapPosition;
      if (pos == null) return;
      _animateMatrixTo(_zoomAroundMatrix(pos, _doubleTapZoomScale));
    }
  }

  void _onInteractionEnd(ScaleEndDetails _) {
    final scale = _currentController.value.getMaxScaleOnAxis();
    if (scale <= _resetThreshold) {
      _animateReset();
    }
  }

  void _onPageChanged(int index) {
    // Đổi listener sang page mới + reset zoom của page cũ ngay (không animate)
    // để khi user vuốt ngược lại, ảnh hiển thị ở 1x từ đầu.
    _matrixAnimController.stop();
    _currentController.removeListener(_onTransformChanged);
    _currentController.value = Matrix4.identity();

    setState(() {
      _currentIndex = index;
      _isZoomed = false;
    });

    _currentController.addListener(_onTransformChanged);
    _onTransformChanged();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.paths.isEmpty
        ? ''
        : widget.paths[_currentIndex].split(RegExp(r'[/\\]')).last;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_currentIndex + 1} / ${widget.paths.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (fileName.isNotEmpty)
              Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: _isZoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        onPageChanged: _onPageChanged,
        itemCount: widget.paths.length,
        itemBuilder: (context, index) {
          final isCurrent = index == _currentIndex;
          // GestureDetector ở ngoài để bắt double-tap (Flutter cần
          // onDoubleTapDown để biết position, onDoubleTap để xác nhận).
          // Pinch + drag vẫn được InteractiveViewer xử lý song song qua
          // gesture arena (scale recognizer khác double-tap recognizer).
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTapDown: isCurrent ? _onDoubleTapDown : null,
            onDoubleTap: isCurrent ? _onDoubleTap : null,
            child: InteractiveViewer(
              transformationController: _controllerFor(index),
              minScale: _minScale,
              maxScale: _maxScale,
              // onInteractionEnd chỉ gắn cho page hiện tại để tránh các page
              // khác trong cache cũng phản hồi.
              onInteractionEnd: isCurrent ? _onInteractionEnd : null,
              child: Center(
                child: Image.file(
                  File(widget.paths[index]),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
