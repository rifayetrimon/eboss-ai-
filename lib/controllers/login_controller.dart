import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool rememberMe = false.obs;

  void toggleRememberMe(bool value) {
    rememberMe.value = value;
  }

  void handleLogin() {
    if (formKey.currentState?.validate() ?? false) {
      final userId = userIdController.text.trim();
      final password = passwordController.text.trim();
      final remember = rememberMe.value;

      final authController = Get.find<AuthController>();
      authController.login(userId, password, remember);

      Get.offAllNamed('/home');
    }
  }

  @override
  void onClose() {
    userIdController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
