import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class CameraGrid extends StatefulWidget {
  const CameraGrid({super.key});

  static const List<String> cameraUrls = [
    'rtsp://admin:JZRGJS@192.168.0.104:554/h264/ch01/sub/av_stream',
    'rtsp://admin:Reolink%40usj1%2Fa@192.168.0.5:554/Preview_01_sub',
    'rtsp://admin:DKIONN@192.168.0.224:554/h264/ch01/sub/av_stream',
  ];

  @override
  State<CameraGrid> createState() => _CameraGridState();
}

class _CameraGridState extends State<CameraGrid> {
  final ValueNotifier<int> streamAllNotifier = ValueNotifier<int>(0);

  void _streamAll() {
    streamAllNotifier.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
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
                        url: CameraGrid.cameraUrls[0],
                        streamAllNotifier: streamAllNotifier,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Secondary Cameras Column
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Expanded(
                            child: _CameraContainer(
                              cameraNumber: 1,
                              label: "Camera 1",
                              url:
                                  CameraGrid.cameraUrls.length > 1
                                      ? CameraGrid.cameraUrls[1]
                                      : '',
                              streamAllNotifier: streamAllNotifier,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _CameraContainer(
                              cameraNumber: 2,
                              label: "Camera 2",
                              url:
                                  CameraGrid.cameraUrls.length > 2
                                      ? CameraGrid.cameraUrls[2]
                                      : '',
                              streamAllNotifier: streamAllNotifier,
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
        ),
        // Stream All Button
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: _streamAll,
            backgroundColor: Colors.white.withOpacity(0.5),
            elevation: 2,
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.play_arrow, color: Colors.white, size: 28),
              ),
            ),
            label: const Text(
              "Stream All",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CameraContainer extends StatelessWidget {
  final int cameraNumber;
  final String label;
  final String url;
  final ValueNotifier<int> streamAllNotifier;

  const _CameraContainer({
    required this.cameraNumber,
    required this.label,
    required this.url,
    required this.streamAllNotifier,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _EmptyCameraPlaceholder(cameraNumber: cameraNumber);
    }
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
          CameraStreamWidget(url: url, streamAllNotifier: streamAllNotifier),
          // Camera label
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
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
  final ValueNotifier<int> streamAllNotifier;
  const CameraStreamWidget({
    required this.url,
    required this.streamAllNotifier,
  });

  @override
  State<CameraStreamWidget> createState() => _CameraStreamWidgetState();
}

class _CameraStreamWidgetState extends State<CameraStreamWidget> {
  late VlcPlayerController _controller;
  bool _hasError = false;
  bool _isPlaying = false; // Start paused

  @override
  void initState() {
    super.initState();
    _controller = VlcPlayerController.network(
      widget.url,
      hwAcc: HwAcc.full,
      autoPlay: false,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
          '--rtsp-tcp',
        ]),
      ),
    );
    _controller.addListener(_onControllerUpdate);
    widget.streamAllNotifier.addListener(_onStreamAll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    widget.streamAllNotifier.removeListener(_onStreamAll);
    _controller.dispose();
    super.dispose();
  }

  void _onStreamAll() {
    if (!_isPlaying) {
      _resumeStream();
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    if (_controller.value.hasError && !_hasError) {
      setState(() {
        _hasError = true;
      });
    }
  }

  void _resumeStream() async {
    setState(() {
      _isPlaying = true;
      _hasError = false;
    });
    await _controller.play();
  }

  void _pauseStream() async {
    setState(() {
      _isPlaying = false;
    });
    await _controller.pause();
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
                  _isPlaying = false;
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
      child: Stack(
        children: [
          // Always build the player, just pause/play as needed
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 1280,
                height: 720,
                child: VlcPlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                  placeholder: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),
          // Play overlay (when not playing)
          if (!_isPlaying)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.5),
                child: Center(
                  child: GestureDetector(
                    onTap: _resumeStream,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.black,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Pause button (top-right, only when playing)
          if (_isPlaying)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _pauseStream,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.pause, color: Colors.white, size: 28),
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
