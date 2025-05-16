import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eboss_ai/pages/profile/controller/profile_controller.dart';

class ProfileRightSheet extends StatelessWidget {
  final String userName;
  final String userId;

  const ProfileRightSheet({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();
    final double sheetWidth = 320.0;
    final double navBarHeight = 90.0; // match your navigation bar height
    final double availableHeight =
        MediaQuery.of(context).size.height - navBarHeight;
    final double sheetHeight = availableHeight * 0.7; // 70% of available height

    return Obx(
      () => Stack(
        children: [
          // Dimmed background (fades in/out, no slide)
          Positioned(
            top: navBarHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !controller.isOpen.value,
              child: AnimatedOpacity(
                opacity: controller.isOpen.value ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: controller.toggleProfile,
                  child: Container(color: Colors.black),
                ),
              ),
            ),
          ),
          // Right sheet (slides in/out)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: navBarHeight,
            right: controller.isOpen.value ? 0 : -sheetWidth,
            width: sheetWidth,
            height: sheetHeight,
            child: IgnorePointer(
              ignoring: !controller.isOpen.value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle (top right)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 16,
                        right: 16,
                        left: 16,
                        bottom: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: controller.toggleProfile,
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),
                              const CircleAvatar(
                                radius: 40,
                                backgroundImage: AssetImage(
                                  'assets/images/profile.png',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "ID: $userId",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: const Text("My Profile"),
                                onTap: controller.toggleProfile,
                              ),
                              ListTile(
                                leading: const Icon(Icons.settings_outlined),
                                title: const Text("Settings"),
                                onTap: controller.toggleProfile,
                              ),
                              ListTile(
                                leading: const Icon(Icons.help_outline),
                                title: const Text("Help & Support"),
                                onTap: controller.toggleProfile,
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              ListTile(
                                leading: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  "Logout",
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: controller.logout,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
