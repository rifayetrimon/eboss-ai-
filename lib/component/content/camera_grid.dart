import 'package:flutter/material.dart';

class CameraGrid extends StatelessWidget {
  const CameraGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // First Row
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // First Column (Big Box)
                Expanded(flex: 2, child: _CameraContainer(cameraNumber: 1)),
                const SizedBox(width: 10),
                // Second Column (Vertical Boxes)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(child: _CameraContainer(cameraNumber: 2)),
                      const SizedBox(height: 10),
                      Expanded(child: _CameraContainer(cameraNumber: 3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Second Row (Horizontal Boxes)
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: _CameraContainer(cameraNumber: 4)),
                const SizedBox(width: 10),
                Expanded(child: _CameraContainer(cameraNumber: 5)),
                const SizedBox(width: 10),
                Expanded(child: _CameraContainer(cameraNumber: 6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraContainer extends StatelessWidget {
  final int cameraNumber;

  const _CameraContainer({required this.cameraNumber});

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
          const Center(
            child: Icon(Icons.videocam, size: 50, color: Colors.grey),
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
                'Camera $cameraNumber',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
