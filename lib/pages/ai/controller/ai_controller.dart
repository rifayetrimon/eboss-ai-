import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AIController extends GetxController {
  // AI page current index and page controller
  final RxInt currentIndex = 0.obs;
  late PageController pageController;

  // List of all camera URLs (can be shared or separate)
  final RxList<String> cameraUrls =
      <String>[
        'rtsp://admin:JZRGJS@192.168.0.104:554/h264/ch01/sub/av_stream',
        'rtsp://admin:Reolink%40usj1%2Fa@192.168.0.5:554/Preview_01_sub',
        'rtsp://admin:DKIONN@192.168.0.224:554/h264/ch01/sub/av_stream',
      ].obs;

  // AI cameras: store selected camera indexes (max 4)
  // Fixed: Only initialize with valid indexes
  var aiCameraIndexes = <int>[0, 1, 2].obs; // Only 3 cameras available

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: currentIndex.value);

    // Ensure aiCameraIndexes are always valid
    _validateAiCameraIndexes();
  }

  void _validateAiCameraIndexes() {
    // Remove any invalid indexes
    aiCameraIndexes.removeWhere(
      (index) => index < 0 || index >= cameraUrls.length,
    );

    // If we don't have enough cameras, fill with available ones
    if (aiCameraIndexes.isEmpty && cameraUrls.isNotEmpty) {
      final maxCameras = cameraUrls.length > 4 ? 4 : cameraUrls.length;
      aiCameraIndexes.value = List.generate(maxCameras, (i) => i);
    }
  }

  void handleTabSelected(int index) {
    if (currentIndex.value == index) return;
    currentIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // AI camera selection methods
  void setAiCameraIndexes(List<int> indexes) {
    if (indexes.length <= 4) {
      final validIndexes =
          indexes.where((i) => i >= 0 && i < cameraUrls.length).toList();
      aiCameraIndexes.value = validIndexes;
    }
  }

  // Add camera management methods
  void addCamera(String url) {
    cameraUrls.add(url);
    _validateAiCameraIndexes();
  }

  void removeCameraAt(int index) {
    if (index >= 0 && index < cameraUrls.length) {
      cameraUrls.removeAt(index);

      // Remove the deleted camera from AI indexes
      aiCameraIndexes.removeWhere((i) => i == index);

      // Adjust remaining indexes (shift down those that were higher)
      for (int i = 0; i < aiCameraIndexes.length; i++) {
        if (aiCameraIndexes[i] > index) {
          aiCameraIndexes[i] = aiCameraIndexes[i] - 1;
        }
      }

      _validateAiCameraIndexes();
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
