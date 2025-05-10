import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class CameraGrid extends StatefulWidget {
  const CameraGrid({super.key});

  @override
  State<CameraGrid> createState() => _CameraGridState();
}

class _CameraGridState extends State<CameraGrid> {
  final List<String> cameraUrls = [
    'rtsp://admin:JZRGJS@192.168.0.104:554/h264/ch01/sub/av_stream',
    'rtsp://admin:Reolink%40usj1%2Fa@192.168.0.5:554/Preview_01_sub',
    'rtsp://admin:DKIONN@192.168.0.224:554/h264/ch01/sub/av_stream',
  ];

  final Map<int, VlcPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (int i = 0; i < cameraUrls.length; i++) {
      _controllers[i] = VlcPlayerController.network(
        cameraUrls[i],
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(2000),
          ]),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

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
                // Main Camera
                Expanded(
                  flex: 2,
                  child: _CameraContainer(
                    label: "Main Camera",
                    controller: _controllers[0],
                  ),
                ),
                const SizedBox(width: 10),
                // Cameras 2 & 3
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: _CameraContainer(
                          cameraNumber: 1,
                          controller: _controllers[1],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _CameraContainer(
                          cameraNumber: 2,
                          controller: _controllers[2],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Second Row (Cameras 4-6 as placeholders)
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: _CameraContainer(cameraNumber: 3)),
                const SizedBox(width: 10),
                Expanded(child: _CameraContainer(cameraNumber: 4)),
                const SizedBox(width: 10),
                Expanded(child: _CameraContainer(cameraNumber: 5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraContainer extends StatefulWidget {
  final int? cameraNumber;
  final String? label;
  final VlcPlayerController? controller;

  const _CameraContainer({this.cameraNumber, this.label, this.controller});

  @override
  State<_CameraContainer> createState() => _CameraContainerState();
}

class _CameraContainerState extends State<_CameraContainer> {
  late VlcPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? VlcPlayerController.network('');
  }

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
          if (widget.controller != null)
            VlcPlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
              placeholder: const Center(child: CircularProgressIndicator()),
            )
          else
            const Center(
              child: Icon(Icons.videocam_off, size: 50, color: Colors.grey),
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
                widget.label ?? 'Camera ${widget.cameraNumber}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
