import 'dart:ui' as ui;
import 'package:eboss_ai/pages/ai/controller/websocket_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AiPage extends StatelessWidget {
  // FIX: Initialize controller with Get.put()
  final WebSocketController controller = Get.put(
    WebSocketController(),
    permanent: true,
  );

  // this page is used to display the camera feeds

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Obx(
            () => GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 16 / 9,
              ),
              itemCount: controller.cameras.length,
              itemBuilder: (context, index) {
                return _buildCameraTile(index);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraTile(int index) {
    return Obx(() {
      final isPlaying = controller.isPlaying[index];
      final isLoading = controller.isLoading[index];
      final hasError = controller.hasError[index];
      final camera = controller.cameras[index];

      return Container(
        key: ValueKey('camera_tile_$index'),
        decoration: BoxDecoration(
          color: const ui.Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const ui.Color.fromARGB(255, 255, 255, 255),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const ui.Color.fromARGB(
                255,
                255,
                255,
                255,
              ).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera feed display
              if (isPlaying && camera != null)
                _buildCameraImage(camera)
              else if (isPlaying && isLoading)
                _buildLoadingState()
              else if (isPlaying && hasError)
                _buildErrorState()
              else
                _buildPausedState(index),

              // Camera label
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "Camera $index",
                    style: const TextStyle(
                      // color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Status indicator
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color:
                        !isPlaying
                            ? Colors.grey
                            : hasError
                            ? Colors.red
                            : isLoading
                            ? Colors.orange
                            : Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),

              // Control bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    // color: Colors.black.withOpacity(0.6),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => controller.saveScreenshot(index),
                      ),
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => controller.togglePlayPause(index),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCameraImage(ui.Image image) {
    return CustomPaint(painter: _CameraImagePainter(image));
  }

  Widget _buildPausedState(int index) {
    return Container(
      color: const ui.Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
      child: Center(
        child: IconButton(
          icon: const Icon(
            Icons.play_circle_filled,
            size: 48,
            color: ui.Color.fromARGB(255, 255, 255, 255),
          ),
          onPressed: () => controller.togglePlayPause(index),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const ColoredBox(
      color: Colors.black12,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    return const ColoredBox(
      color: Colors.black12,
      child: Center(
        child: Icon(Icons.error_outline, color: Colors.red, size: 48),
      ),
    );
  }
}

class _CameraImagePainter extends CustomPainter {
  final ui.Image image;

  _CameraImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
