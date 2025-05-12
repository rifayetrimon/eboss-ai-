// lib/component/navigation.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:eboss_ai/component/profile/profile.dart';
import 'package:eboss_ai/controllers/home_controller.dart';
import 'package:eboss_ai/controllers/profile_controller.dart';

class CustomNavigationBar extends StatelessWidget {
  final String userName;
  final String userId;

  const CustomNavigationBar({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();
    final ProfileController profileController = Get.find<ProfileController>();

    return Stack(
      children: [
        SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(60, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset('assets/logo/logo1.png', height: 30, width: 112),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(
                        () => _NavButton(
                          text: 'Basic',
                          isSelected: homeController.currentIndex.value == 0,
                          onTap: () => homeController.handleTabSelected(0),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Obx(
                        () => _NavButton(
                          text: 'AI',
                          isSelected: homeController.currentIndex.value == 1,
                          onTap: () => homeController.handleTabSelected(1),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Obx(
                        () => _NavButton(
                          text: 'Settings',
                          isSelected: homeController.currentIndex.value == 2,
                          onTap: () => homeController.handleTabSelected(2),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: profileController.toggleProfile,
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/images/profile.png'),
                  ),
                ),
              ],
            ),
          ),
        ),
        ProfileSlider(userName: userName, userId: userId),
      ],
    );
  }
}

// Rest of the code remains the same

class _NavButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
