import 'package:get/get.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'dart:developer' as developer;

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
  final RxList<String> errorMessages = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    try {
      // Dispose old controllers safely
      for (var controller in controllers.values) {
        if (controller != null) {
          try {
            controller.dispose();
          } catch (e) {
            developer.log('Error disposing controller: $e');
          }
        }
      }
      controllers.clear();
      failedCameras.clear();
      errorMessages.clear();

      for (int i = 0; i < cameraUrls.length; i++) {
        controllers[i] = VlcPlayerController.network(
          cameraUrls[i],
          hwAcc: HwAcc.full,
          autoPlay: true, // <-- THIS IS THE KEY
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              VlcAdvancedOptions.networkCaching(2000),
              '--rtsp-tcp',
              '--no-drop-late-frames',
              '--no-skip-frames',
              '--live-caching=300',
            ]),
          ),
        );
      }
    } catch (e) {
      developer.log('General error creating camera controllers: $e', error: e);
      Get.snackbar('Error', 'Failed to create camera controllers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void retryConnection(int index) {
    if (index < cameraUrls.length) {
      developer.log('Retrying connection for camera $index');
      if (failedCameras.contains(index)) {
        failedCameras.remove(index);
      }
      errorMessages.removeWhere((msg) => msg.contains('Camera ${index + 1}:'));

      // Dispose old controller safely
      if (controllers[index] != null) {
        try {
          controllers[index]!.dispose();
        } catch (e) {
          developer.log('Error disposing controller: $e');
        }
      }

      // Recreate controller
      controllers[index] = VlcPlayerController.network(
        cameraUrls[index],
        hwAcc: HwAcc.full,
        autoPlay: true, // <-- THIS IS THE KEY
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(2000),
            '--rtsp-tcp',
            '--no-drop-late-frames',
            '--no-skip-frames',
            '--live-caching=300',
          ]),
        ),
      );
    }
  }

  @override
  void onClose() {
    for (var controller in controllers.values) {
      if (controller != null) {
        try {
          controller.dispose();
        } catch (e) {
          developer.log('Error disposing controller: $e');
        }
      }
    }
    super.onClose();
  }
}
