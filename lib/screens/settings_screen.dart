import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.movie_filter_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Snap Frame',
              style: TextStyle(color: AppColors.primary),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _PageTitle(),
              SizedBox(height: 32),
              _SectionHeader(
                icon: Icons.settings_suggest_outlined,
                title: 'Cấu hình xuất',
              ),
              SizedBox(height: 16),
              _FpsSetting(),
              SizedBox(height: 16),
              _FormatSetting(),
              SizedBox(height: 32),
              _ProBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Cài đặt',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.64,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _FpsSetting extends StatelessWidget {
  const _FpsSetting();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frames per second (fps)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Số lượng ảnh được trích xuất mỗi giây',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: settings.fps.value,
            isExpanded: true,
            icon: const Icon(Icons.expand_more),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: FpsOption.values
                .map(
                  (o) => DropdownMenuItem<String>(
                    value: o.value,
                    child: Text(o.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              context
                  .read<SettingsState>()
                  .setFps(FpsOption.fromValue(value));
            },
          ),
        ],
      ),
    );
  }
}

class _FormatSetting extends StatelessWidget {
  const _FormatSetting();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Định dạng ảnh đầu ra',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'PNG cho chất lượng cao nhất, JPG cho file nhẹ hơn',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FormatOption(
                  label: 'PNG',
                  selected: settings.format == OutputFormat.png,
                  onTap: () => context
                      .read<SettingsState>()
                      .setFormat(OutputFormat.png),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FormatOption(
                  label: 'JPG',
                  selected: settings.format == OutputFormat.jpg,
                  onTap: () => context
                      .read<SettingsState>()
                      .setFormat(OutputFormat.jpg),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.onPrimaryContainer
                : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ProBanner extends StatelessWidget {
  const _ProBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Chế độ chuyên nghiệp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tối ưu hóa quy trình trích xuất khung hình từ video '
                'chất lượng cao với độ trễ thấp nhất.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
          Positioned(
            right: -12,
            bottom: -12,
            child: Icon(
              Icons.speed,
              size: 120,
              color: AppColors.onPrimaryContainer.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
