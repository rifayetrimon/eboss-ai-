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

  // Add user information (you might want to get this from a user service or provider)
  final String _userName = "User"; // Replace with actual user name
  final String _userId = "ID12345"; // Replace with actual user ID

  void _handleTabSelected(int index) {
    if (_currentIndex == index) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentIndex = index);
  }

  // Add logout handler
  void _handleLogout() {
    // Implement your logout logic here
    // For example:
    // AuthService.logout();
    // Navigator.of(context).pushReplacementNamed('/login');

    // For demonstration, we'll just show a snackbar
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logging out...')));
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
          userName: _userName, // Add user name
          userId: _userId, // Add user ID
          onLogout: _handleLogout, // Add logout handler
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
