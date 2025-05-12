// lib/controllers/camera_grid_controller.dart
import 'package:get/get.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class CameraGridController extends GetxController {
  final List<String> cameraUrls = [
    'rtsp://admin:JZRGJS@192.168.0.104:554/h264/ch01/sub/av_stream',
    'rtsp://admin:Reolink%40usj1%2Fa@192.168.0.5:554/Preview_01_sub',
    'rtsp://admin:DKIONN@192.168.0.224:554/h264/ch01/sub/av_stream',
  ];

  final RxMap<int, VlcPlayerController?> controllers =
      <int, VlcPlayerController?>{}.obs;
  final RxBool isLoading = true.obs;
  final RxList<int> failedCameras = <int>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    try {
      // Initialize with null values first so the map has all keys
      for (int i = 0; i < cameraUrls.length; i++) {
        controllers[i] = null;
      }

      // Now try to create controllers
      for (int i = 0; i < cameraUrls.length; i++) {
        try {
          final controller = VlcPlayerController.network(
            cameraUrls[i],
            options: VlcPlayerOptions(
              advanced: VlcAdvancedOptions([
                VlcAdvancedOptions.networkCaching(2000),
              ]),
            ),
          );

          // Update the controller in the map
          controllers[i] = controller;
        } catch (e) {
          failedCameras.add(i);
          print('Failed to initialize camera $i: $e');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize camera connections');
    } finally {
      isLoading.value = false;
    }
  }

  bool isCameraAvailable(int index) {
    return controllers.containsKey(index) &&
        controllers[index] != null &&
        !failedCameras.contains(index);
  }

  void retryConnection(int index) {
    if (index < cameraUrls.length) {
      if (failedCameras.contains(index)) {
        failedCameras.remove(index);
      }

      try {
        // Dispose old controller if exists
        if (controllers[index] != null) {
          controllers[index]!.dispose();
        }

        // Create new controller
        final controller = VlcPlayerController.network(
          cameraUrls[index],
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              VlcAdvancedOptions.networkCaching(2000),
            ]),
          ),
        );

        // Update the map
        controllers[index] = controller;
      } catch (e) {
        failedCameras.add(index);
        Get.snackbar('Error', 'Failed to reconnect to camera ${index + 1}');
      }
    }
  }

  @override
  void onClose() {
    for (var controller in controllers.values) {
      if (controller != null) {
        controller.dispose();
      }
    }
    super.onClose();
  }
}
