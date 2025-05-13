import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class CameraGrid extends StatelessWidget {
  const CameraGrid({super.key});

  // Replace with your actual camera URLs
  static const List<String> cameraUrls = [
    'rtsp://admin:JZRGJS@192.168.0.104:554/h264/ch01/sub/av_stream',
    'rtsp://admin:Reolink%40usj1%2Fa@192.168.0.5:554/Preview_01_sub',
    'rtsp://admin:DKIONN@192.168.0.224:554/h264/ch01/sub/av_stream',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Main Camera Row
          Expanded(
            flex: 6,
            child: Row(
              children: [
                // Main Camera
                Expanded(
                  flex: 4,
                  child: _CameraContainer(
                    label: "Main Camera",
                    cameraNumber: 0,
                    url: cameraUrls[0],
                  ),
                ),
                const SizedBox(width: 0),
                // Secondary Cameras Column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: _CameraContainer(
                          cameraNumber: 1,
                          label: "Camera 1",
                          url: cameraUrls.length > 1 ? cameraUrls[1] : '',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _CameraContainer(
                          cameraNumber: 2,
                          label: "Camera 2",
                          url: cameraUrls.length > 2 ? cameraUrls[2] : '',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Additional Cameras Row (placeholders)
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
  final int cameraNumber;
  final String label;
  final String url;

  const _CameraContainer({
    required this.cameraNumber,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _EmptyCameraPlaceholder(cameraNumber: cameraNumber);
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          CameraStreamWidget(url: url),
          // Camera label
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ).withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Camera status indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CameraStreamWidget extends StatefulWidget {
  final String url;
  const CameraStreamWidget({required this.url});

  @override
  State<CameraStreamWidget> createState() => _CameraStreamWidgetState();
}

class _CameraStreamWidgetState extends State<CameraStreamWidget> {
  late VlcPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VlcPlayerController.network(
      widget.url,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
          '--rtsp-tcp',
        ]),
      ),
    );
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    if (_controller.value.hasError && !_hasError) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            const Text("Stream Error", style: TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _controller.dispose();
                  _controller = VlcPlayerController.network(
                    widget.url,
                    hwAcc: HwAcc.full,
                    autoPlay: true,
                    options: VlcPlayerOptions(
                      advanced: VlcAdvancedOptions([
                        VlcAdvancedOptions.networkCaching(2000),
                        '--rtsp-tcp',
                      ]),
                    ),
                  );
                  _controller.addListener(_onControllerUpdate);
                });
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: VlcPlayer(
        controller: _controller,
        aspectRatio: 16 / 9,
        placeholder: const Center(child: CircularProgressIndicator()),
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
