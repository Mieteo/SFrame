import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

/// Wrapper màn hình chính chứa BottomNavigationBar 3 tab.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _switchTab(int newIndex) {
    if (newIndex == _index) return;
    setState(() => _index = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack giữ state của các tab khi chuyển qua lại
    // (vd: video preview vẫn còn khi quay lại tab Chính).
    final pages = [
      MainScreen(onSwitchTab: _switchTab),
      ResultScreen(onSwitchTab: _switchTab),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _switchTab,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.secondaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Chính',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Kết quả',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
