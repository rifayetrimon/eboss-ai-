// lib/controllers/auth_controller.dart
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthController extends GetxController {
  final RxBool isLoggedIn = false.obs;
  final RxString userName = "User".obs;
  final RxString userId = "ID12345".obs;

  // For secure storage
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> login(String userId, String password, bool rememberMe) async {
    try {
      // Here you would typically make an API call to authenticate the user
      // For demo purposes, we'll just set as successful
      isLoggedIn.value = true;
      userName.value = "Demo User";
      this.userId.value = userId;

      // Store credentials if remember me is checked
      if (rememberMe) {
        await _storage.write(key: 'userId', value: userId);
        await _storage.write(key: 'isLoggedIn', value: 'true');
        // Note: Storing passwords is not recommended without proper encryption
      }

      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar('Login Failed', 'Invalid credentials or connection error');
      print('Login error: $e');
    }
  }

  Future<void> logout() async {
    try {
      isLoggedIn.value = false;
      // Clear stored credentials
      await _storage.delete(key: 'userId');
      await _storage.delete(key: 'isLoggedIn');

      Get.offAllNamed('/login');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<void> checkLoginStatus() async {
    try {
      final storedLoginStatus = await _storage.read(key: 'isLoggedIn');
      if (storedLoginStatus == 'true') {
        final storedUserId = await _storage.read(key: 'userId');
        if (storedUserId != null) {
          userId.value = storedUserId;
          userName.value = "Demo User"; // Could fetch from API in real app
          isLoggedIn.value = true;
        }
      }
    } catch (e) {
      print('Error checking login status: $e');
    }
  }
}
