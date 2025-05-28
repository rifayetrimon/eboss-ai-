import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  // Existing page controller state
  final RxInt currentIndex = 0.obs;
  late PageController pageController;

  // Main camera index
  var mainCameraIndex = 0.obs;

  // List of all camera URLs
  final RxList<String> cameraUrls =
      <String>[
        'rtsp://admin:JZRGJS@192.168.0.104:554/h264/ch01/sub/av_stream',
        'rtsp://admin:Reolink%40usj1%2Fa@192.168.0.5:554/Preview_01_sub',
        'rtsp://admin:DKIONN@192.168.0.224:554/h264/ch01/sub/av_stream',
      ].obs;

  // AI cameras: store selected camera indexes (max 4)
  var aiCameraIndexes = <int>[0, 1, 2, 3].obs;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: currentIndex.value);
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

  // Camera management methods

  void addCamera(String url) {
    cameraUrls.add(url);
  }

  void removeCameraAt(int index) {
    if (index >= 0 && index < cameraUrls.length) {
      cameraUrls.removeAt(index);
      // Adjust mainCameraIndex if needed
      if (mainCameraIndex.value >= cameraUrls.length) {
        mainCameraIndex.value = cameraUrls.isEmpty ? 0 : cameraUrls.length - 1;
      }
      // Also adjust AI camera indexes to remove invalid indexes
      aiCameraIndexes.removeWhere((i) => i == index);
      // Optionally, reset AI camera indexes if empty or invalid
      if (aiCameraIndexes.isEmpty && cameraUrls.isNotEmpty) {
        aiCameraIndexes.value =
            cameraUrls.length > 4
                ? List.generate(4, (i) => i)
                : List.generate(cameraUrls.length, (i) => i);
      }
    }
  }

  void setMainCameraIndex(int index) {
    if (index >= 0 && index < cameraUrls.length) {
      mainCameraIndex.value = index;
    }
  }

  // AI camera selection methods

  void setAiCameraIndexes(List<int> indexes) {
    if (indexes.length <= 4) {
      // Validate indexes are within range
      final validIndexes =
          indexes.where((i) => i >= 0 && i < cameraUrls.length).toList();
      aiCameraIndexes.value = validIndexes;
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
