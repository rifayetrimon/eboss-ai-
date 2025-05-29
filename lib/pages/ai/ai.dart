// ai_page.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eboss_ai/pages/ai/controller/websocket_controller.dart';

class AiPage extends StatelessWidget {
  final WebSocketController controller = Get.put(WebSocketController());

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
      final isLoading = controller.isLoading[index];
      final hasError = controller.hasError[index];
      final camera = controller.cameras[index];

      return Container(
        key: ValueKey('camera_tile_$index'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color.fromARGB(255, 154, 154, 154),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera feed display
              if (camera != null)
                _buildCameraImage(camera)
              else if (isLoading)
                _buildLoadingState()
              else
                _buildErrorState(),

              // Status overlay
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: _buildStatusIndicator(index),
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

  Widget _buildStatusIndicator(int index) {
    return Obx(() {
      final isLoading = controller.isLoading[index];
      final hasError = controller.hasError[index];

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLoading
                  ? Icons.refresh
                  : hasError
                  ? Icons.error
                  : Icons.check_circle,
              color:
                  isLoading
                      ? Colors.blue
                      : hasError
                      ? Colors.red
                      : Colors.green,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              isLoading
                  ? 'Connecting...'
                  : hasError
                  ? 'Connection lost'
                  : 'Live',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      );
    });
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
