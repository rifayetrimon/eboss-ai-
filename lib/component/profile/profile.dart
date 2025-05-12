import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:eboss_ai/controllers/profile_controller.dart';

class ProfileSlider extends StatelessWidget {
  final String userName;
  final String userId;

  const ProfileSlider({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    // Find the controller to make sure it exists
    final ProfileController controller = Get.find<ProfileController>();

    return Obx(
      () => IgnorePointer(
        ignoring: !controller.isOpen.value,
        child: Stack(
          children: [
            // Backdrop overlay
            if (controller.isOpen.value)
              AnimatedOpacity(
                opacity: controller.isOpen.value ? 0.3 : 0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: controller.toggleProfile,
                  child: Container(
                    color: Colors.black,
                    width: Get.width,
                    height: Get.height,
                  ),
                ),
              ),
            // Sliding profile panel
            AnimatedBuilder(
              animation: controller.animationController,
              builder: (context, child) {
                return SlideTransition(
                  position: controller.slideAnimation,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 300,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 125, 23, 23),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile header
                            Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    radius: 40,
                                    backgroundImage: AssetImage(
                                      'assets/images/profile.png',
                                    ),
                                  ),
                                  const SizedBox(height: 15),
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
                                ],
                              ),
                            ),
                            const Divider(),
                            // Profile menu items
                            ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: const Text("My Profile"),
                              onTap: () {
                                // Handle profile tap
                                controller.toggleProfile();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.settings_outlined),
                              title: const Text("Settings"),
                              onTap: () {
                                // Handle settings tap
                                controller.toggleProfile();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.help_outline),
                              title: const Text("Help & Support"),
                              onTap: () {
                                // Handle help tap
                                controller.toggleProfile();
                              },
                            ),
                            const Spacer(),
                            // Logout button at the bottom
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
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
