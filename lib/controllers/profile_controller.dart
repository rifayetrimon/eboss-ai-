// lib/controllers/profile_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eboss_ai/controllers/auth_controller.dart';

class ProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final RxBool isOpen = false.obs;
  late final AnimationController animationController;
  late final Animation<Offset> slideAnimation;

  // Get the auth controller
  final AuthController _authController = Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );
  }

  void toggleProfile() {
    if (isOpen.value) {
      animationController.reverse();
    } else {
      animationController.forward();
    }
    isOpen.value = !isOpen.value;
  }

  void logout() {
    // Close the profile slider
    if (isOpen.value) {
      toggleProfile();
    }
    // Use the auth controller to handle logout
    _authController.logout();
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
