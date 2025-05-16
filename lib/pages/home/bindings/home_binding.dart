// lib/bindings/home_binding.dart
import 'package:get/get.dart';
import '../controller/home_controller.dart';
import '../../profile/controller/profile_controller.dart';
import '../controller/camera_grid_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<HomeController>(HomeController(), permanent: true);
    Get.put<ProfileController>(ProfileController(), permanent: true);
    Get.put<CameraGridController>(CameraGridController(), permanent: true);
  }
}
