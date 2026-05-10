import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/video_state.dart';
import '../theme/app_theme.dart';
import 'frame_viewer_screen.dart';

class ResultScreen extends StatefulWidget {
  /// Cho phép quay lại tab Chính khi chưa có frame.
  final void Function(int index) onSwitchTab;

  const ResultScreen({super.key, required this.onSwitchTab});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final Set<int> _selected = {};
  bool _busy = false;

  /// Khi true: tap = toggle chọn. Khi false: tap = mở xem ảnh.
  /// Long-press luôn vào selection mode + chọn ảnh đó.
  bool _selectionMode = false;

  /// Theo dõi extractionId của lần cắt frame trước đó. Khi user cắt video
  /// mới, extractionId tăng → reset selection để không "nhớ" lựa chọn cũ.
  int? _lastExtractionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<VideoState>().extractionId;
    if (_lastExtractionId == null) {
      _lastExtractionId = id;
    } else if (_lastExtractionId != id) {
      _lastExtractionId = id;
      _selected.clear();
      _selectionMode = false;
    }
  }

  void _onTileTap(int index, List<String> paths) {
    if (_selectionMode) {
      _toggle(index);
    } else {
      _openViewer(index, paths);
    }
  }

  void _onTileLongPress(int index) {
    setState(() {
      _selectionMode = true;
      _selected.add(index);
    });
  }

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
        if (_selected.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selected.add(index);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selected.clear();
      _selectionMode = false;
    });
  }

  void _openViewer(int index, List<String> paths) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FrameViewerScreen(
          paths: paths,
          initialIndex: index,
        ),
      ),
    );
  }

  void _selectAll(List<String> paths) {
    setState(() {
      if (_selected.length == paths.length) {
        _selected.clear();
        _selectionMode = false;
      } else {
        _selected
          ..clear()
          ..addAll(List.generate(paths.length, (i) => i));
        _selectionMode = true;
      }
    });
  }

  List<String> _selectedPaths(List<String> paths) {
    return _selected.map((i) => paths[i]).toList();
  }

  Future<void> _share(List<String> paths) async {
    final files = _selectedPaths(paths);
    if (files.isEmpty) return;
    setState(() => _busy = true);
    try {
      await Share.shareXFiles(files.map((p) => XFile(p)).toList());
    } catch (e) {
      _snack('Chia sẻ thất bại: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(List<String> paths) async {
    final files = _selectedPaths(paths);
    if (files.isEmpty) return;
    setState(() => _busy = true);
    try {
      // Flutter chưa hỗ trợ ảnh trực tiếp trong system clipboard trên hầu hết
      // nền tảng — fallback sao chép đường dẫn file dạng text (đúng theo prompt).
      await Clipboard.setData(ClipboardData(text: files.join('\n')));
      _snack(
        files.length == 1
            ? 'Đã sao chép đường dẫn ảnh vào clipboard'
            : 'Đã sao chép ${files.length} đường dẫn ảnh vào clipboard',
      );
    } catch (e) {
      _snack('Sao chép thất bại: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(List<String> paths) async {
    final files = _selectedPaths(paths);
    if (files.isEmpty) return;
    setState(() => _busy = true);
    try {
      // gal tự xử lý xin quyền platform-specific. Phòng trường hợp iOS chưa
      // có quyền add-only thì xin trước cho UX rõ ràng hơn.
      if (Platform.isIOS) {
        final res = await Permission.photosAddOnly.request();
        if (res.isPermanentlyDenied) {
          openAppSettings();
          return;
        }
      } else if (Platform.isAndroid) {
        final hasAccess = await Gal.hasAccess(toAlbum: true);
        if (!hasAccess) {
          final granted = await Gal.requestAccess(toAlbum: true);
          if (!granted) {
            _snack('Cần cấp quyền truy cập thư viện ảnh');
            return;
          }
        }
      }

      int saved = 0;
      for (final path in files) {
        try {
          await Gal.putImage(path, album: 'Snap Frame');
          saved++;
        } catch (_) {
          // Bỏ qua file lỗi, tiếp tục với file tiếp theo
        }
      }
      _snack(saved == files.length
          ? 'Đã lưu $saved ảnh vào thư viện'
          : 'Đã lưu $saved/${files.length} ảnh');
    } on GalException catch (e) {
      _snack('Lưu thất bại: ${e.type.message}');
    } catch (e) {
      _snack('Lưu thất bại: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paths = context.watch<VideoState>().framePaths;

    // Đảm bảo selection luôn nằm trong khoảng path hợp lệ.
    _selected.removeWhere((i) => i >= paths.length);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _selectionMode
          ? AppBar(
              backgroundColor: AppColors.surface,
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Thoát chế độ chọn',
                onPressed: _exitSelectionMode,
              ),
              title: Text('${_selected.length} đã chọn'),
              actions: [
                if (paths.isNotEmpty)
                  TextButton(
                    onPressed: () => _selectAll(paths),
                    child: Text(
                      _selected.length == paths.length
                          ? 'Bỏ chọn'
                          : 'Chọn tất cả',
                    ),
                  ),
              ],
            )
          : AppBar(
              title: const Text('Snap Frame'),
              leading: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.movie_filter_outlined,
                  color: AppColors.primary,
                ),
              ),
            ),
      body: SafeArea(
        child: paths.isEmpty
            ? _EmptyResult(onGoToMain: () => widget.onSwitchTab(0))
            : Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kết quả',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectionMode
                              ? 'Đã chọn ${_selected.length}/${paths.length} ảnh'
                              : 'Nhấn để xem ảnh, nhấn giữ để chọn nhiều.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            itemCount: paths.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                            ),
                            itemBuilder: (context, index) {
                              final selected = _selected.contains(index);
                              return _FrameTile(
                                path: paths[index],
                                selected: selected,
                                onTap: () => _onTileTap(index, paths),
                                onLongPress: () => _onTileLongPress(index),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectionMode)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 16,
                      child: Center(
                        child: _ActionBar(
                          enabled: _selected.isNotEmpty && !_busy,
                          onShare: () => _share(paths),
                          onCopy: () => _copy(paths),
                          onSave: () => _save(paths),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _FrameTile extends StatelessWidget {
  final String path;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FrameTile({
    required this.path,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.surfaceContainer,
                child: const Icon(
                  Icons.broken_image,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onSave;

  const _ActionBar({
    required this.enabled,
    required this.onShare,
    required this.onCopy,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BarButton(
            icon: Icons.share,
            label: 'Chia sẻ',
            enabled: enabled,
            onTap: onShare,
          ),
          _Divider(),
          _BarButton(
            icon: Icons.content_copy,
            label: 'Sao chép',
            enabled: enabled,
            onTap: onCopy,
          ),
          _Divider(),
          _BarButton(
            icon: Icons.download,
            label: 'Lưu',
            enabled: enabled,
            onTap: onSave,
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _BarButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppColors.onInverseSurface
        : AppColors.onInverseSurface.withValues(alpha: 0.4);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.onInverseSurface.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  final VoidCallback onGoToMain;
  const _EmptyResult({required this.onGoToMain});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có frame nào được cắt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy quay lại tab Chính để bắt đầu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: onGoToMain,
              icon: const Icon(Icons.home_outlined),
              label: const Text('Về tab Chính'),
            ),
          ],
        ),
      ),
    );
  }
}
