import 'package:flutter/material.dart';
import 'package:eboss_ai/component/navigation.dart';
import 'package:eboss_ai/component/content/camera_grid.dart';
import 'package:eboss_ai/component/content/ai.dart';
import 'package:eboss_ai/component/content/settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _handleTabSelected(int index) {
    if (_currentIndex == index) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: CustomNavigationBar(
          initialIndex: _currentIndex,
          onTabSelected: _handleTabSelected,
        ),
      ),
      body: SafeArea(
        top: true,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: const [CameraGrid(), AiPage(), SettingsPage()],
        ),
      ),
    );
  }
}
