import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:eboss_ai/component/navigation.dart';
import 'package:eboss_ai/component/content/camera_grid.dart';
import 'package:eboss_ai/component/content/ai.dart';
import 'package:eboss_ai/component/content/settings.dart';
import 'package:eboss_ai/component/profile/profile_right_sheet.dart';
import 'package:eboss_ai/controllers/home_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final String userName = "User";
    final String userId = "ID12345";

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: CustomNavigationBar(userName: userName, userId: userId),
      ),
      body: Stack(
        children: [
          // Main content with gradient and SafeArea
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEAD0DB), Color(0xFFB6CEEB)],
              ),
            ),
            child: SafeArea(
              child: PageView(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => controller.currentIndex.value = index,
                children: const [CameraGrid(), AiPage(), SettingsPage()],
              ),
            ),
          ),
          // Profile right sheet overlay
          ProfileRightSheet(userName: userName, userId: userId),
        ],
      ),
    );
  }
}
