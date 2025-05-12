// lib/component/content/camera_grid.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:eboss_ai/controllers/camera_grid_controller.dart';

class CameraGrid extends StatelessWidget {
  const CameraGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Don't initialize the controller in build - it should be initialized in bindings
    final CameraGridController controller = Get.find<CameraGridController>();

    // Loading indicator
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Main Camera Row
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Main Camera
                Expanded(
                  flex: 2,
                  child: Obx(
                    () => _CameraContainer(
                      label: "Main Camera",
                      cameraNumber: 0,
                      controller:
                          controller.isLoading.value
                              ? null
                              : (controller.controllers[0]),
                      onRetry: () => controller.retryConnection(0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Secondary Cameras Column
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: Obx(
                          () => _CameraContainer(
                            cameraNumber: 1,
                            controller:
                                controller.isLoading.value
                                    ? null
                                    : (controller.controllers[1]),
                            onRetry: () => controller.retryConnection(1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Obx(
                          () => _CameraContainer(
                            cameraNumber: 2,
                            controller:
                                controller.isLoading.value
                                    ? null
                                    : (controller.controllers[2]),
                            onRetry: () => controller.retryConnection(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Additional Cameras Row
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: _EmptyCameraPlaceholder(cameraNumber: 3)),
                const SizedBox(width: 10),
                Expanded(child: _EmptyCameraPlaceholder(cameraNumber: 4)),
                const SizedBox(width: 10),
                Expanded(child: _EmptyCameraPlaceholder(cameraNumber: 5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraContainer extends StatelessWidget {
  final int? cameraNumber;
  final String? label;
  final VlcPlayerController? controller;
  final VoidCallback? onRetry;

  const _CameraContainer({
    this.cameraNumber,
    this.label,
    this.controller,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          if (controller != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: VlcPlayer(
                controller: controller!,
                aspectRatio: 16 / 9,
                placeholder: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off, size: 50, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    "Camera Offline",
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (onRetry != null)
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                    ),
                ],
              ),
            ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label ??
                    'Camera ${cameraNumber != null ? cameraNumber! + 1 : ""}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCameraPlaceholder extends StatelessWidget {
  final int cameraNumber;

  const _EmptyCameraPlaceholder({required this.cameraNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              "Add Camera ${cameraNumber + 1}",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
