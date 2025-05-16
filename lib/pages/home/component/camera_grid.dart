import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int? fullscreenCamera; // null = grid, otherwise index of camera
  late List<VlcPlayerController> _controllers;
  late List<bool> _isPlayingList;

  // Track if a controller needs initialization
  late List<bool> _needsInitialization;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = List.generate(
      CameraGrid.cameraUrls.length,
      (i) => VlcPlayerController.network(
        CameraGrid.cameraUrls[i],
        hwAcc: HwAcc.full,
        autoPlay: false,
        options: VlcPlayerOptions(advanced: VlcAdvancedOptions(['--rtsp-tcp'])),
      ),
    );
    _isPlayingList = List.generate(CameraGrid.cameraUrls.length, (_) => false);
    _needsInitialization = List.generate(
      CameraGrid.cameraUrls.length,
      (_) => false,
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // Create a new controller for a specific camera
  VlcPlayerController _createController(int index, {bool autoPlay = false}) {
    return VlcPlayerController.network(
      CameraGrid.cameraUrls[index],
      hwAcc: HwAcc.full,
      autoPlay: autoPlay,
      options: VlcPlayerOptions(advanced: VlcAdvancedOptions(['--rtsp-tcp'])),
    );
  }

  void _streamAll() {
    setState(() {
      for (int i = 0; i < _isPlayingList.length; i++) {
        // If controller needs initialization, recreate it
        if (_needsInitialization[i]) {
          _controllers[i].dispose();
          _controllers[i] = _createController(i, autoPlay: true);
          _needsInitialization[i] = false;
        } else {
          _controllers[i].play();
        }
        _isPlayingList[i] = true;
      }
    });
  }

  void _enterFullscreen(int cameraIndex) {
    // Pause all other streams to save bandwidth
    for (int i = 0; i < _controllers.length; i++) {
      if (i != cameraIndex && _isPlayingList[i]) {
        _controllers[i].pause();
        // Mark that this controller will need reinitialization
        _needsInitialization[i] = true;
      }
    }

    // Recreate the controller for fullscreen
    _controllers[cameraIndex].dispose();
    _controllers[cameraIndex] = _createController(cameraIndex, autoPlay: true);
    _needsInitialization[cameraIndex] = false;

    // Hide system UI for true fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    setState(() {
      fullscreenCamera = cameraIndex;
      _isPlayingList[cameraIndex] = true;
    });
  }

  void _exitFullscreen() {
    final idx = fullscreenCamera!;

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Recreate controller to ensure it works in grid view
    _controllers[idx].dispose();
    _controllers[idx] = _createController(idx, autoPlay: true);
    _needsInitialization[idx] = false;

    setState(() {
      fullscreenCamera = null;
      _isPlayingList[idx] = true; // Keep it playing
    });
  }

  void _setPlaying(int cameraIndex, bool playing) {
    setState(() {
      if (playing && _needsInitialization[cameraIndex]) {
        // Recreate controller if needed
        _controllers[cameraIndex].dispose();
        _controllers[cameraIndex] = _createController(
          cameraIndex,
          autoPlay: true,
        );
        _needsInitialization[cameraIndex] = false;
        _isPlayingList[cameraIndex] = true;
      } else {
        _isPlayingList[cameraIndex] = playing;
        if (playing) {
          _controllers[cameraIndex].play();
        } else {
          _controllers[cameraIndex].pause();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (fullscreenCamera != null) {
      final idx = fullscreenCamera!;
      return Stack(
        children: [
          Container(
            color: Colors.black,
            child: SafeArea(
              child: Center(
                child: AspectRatio(
                  aspectRatio:
                      MediaQuery.of(context).size.width /
                      MediaQuery.of(context).size.height,
                  child: _CameraContainer(
                    key: ValueKey('fullscreen_$idx'),
                    cameraNumber: idx,
                    label: idx == 0 ? "Main Camera" : "Camera $idx",
                    controller: _controllers[idx],
                    isPlaying: _isPlayingList[idx],
                    onPlayPause: (playing) => _setPlaying(idx, playing),
                    showFullscreen: false,
                    isFullscreen: true,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              heroTag: "exit_fullscreen",
              backgroundColor: Colors.white.withOpacity(0.7),
              onPressed: _exitFullscreen,
              child: const Icon(Icons.fullscreen_exit, color: Colors.black),
            ),
          ),
        ],
      );
    }

    // Normal grid view
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    // Main Camera
                    Expanded(
                      flex: 4,
                      child: _CameraContainer(
                        cameraNumber: 0,
                        label: "Main Camera",
                        controller: _controllers[0],
                        isPlaying: _isPlayingList[0],
                        onPlayPause: (playing) => _setPlaying(0, playing),
                        onFullscreen: () => _enterFullscreen(0),
                        needsInit: _needsInitialization[0],
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
                              controller: _controllers[1],
                              isPlaying: _isPlayingList[1],
                              onPlayPause: (playing) => _setPlaying(1, playing),
                              onFullscreen: () => _enterFullscreen(1),
                              needsInit: _needsInitialization[1],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _CameraContainer(
                              cameraNumber: 2,
                              label: "Camera 2",
                              controller: _controllers[2],
                              isPlaying: _isPlayingList[2],
                              onPlayPause: (playing) => _setPlaying(2, playing),
                              onFullscreen: () => _enterFullscreen(2),
                              needsInit: _needsInitialization[2],
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
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            heroTag: "stream_all",
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
  final VlcPlayerController controller;
  final bool isPlaying;
  final ValueChanged<bool> onPlayPause;
  final VoidCallback? onFullscreen;
  final bool showFullscreen;
  final bool isFullscreen;
  final bool needsInit;

  const _CameraContainer({
    Key? key,
    required this.cameraNumber,
    required this.label,
    required this.controller,
    required this.isPlaying,
    required this.onPlayPause,
    this.onFullscreen,
    this.showFullscreen = true,
    this.isFullscreen = false,
    this.needsInit = false,
  }) : super(key: key);

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
          CameraStreamWidget(
            controller: controller,
            isPlaying: isPlaying,
            onPlayPause: onPlayPause,
            isFullscreen: isFullscreen,
            cameraNumber: cameraNumber,
            needsInit: needsInit,
          ),
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
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color:
                    needsInit
                        ? Colors.orange
                        : (isPlaying ? Colors.green : Colors.red),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
          // Only show fullscreen button if stream is playing
          if (showFullscreen && onFullscreen != null && isPlaying)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: onFullscreen,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CameraStreamWidget extends StatelessWidget {
  final VlcPlayerController controller;
  final bool isPlaying;
  final ValueChanged<bool> onPlayPause;
  final bool isFullscreen;
  final int cameraNumber;
  final bool needsInit;

  const CameraStreamWidget({
    required this.controller,
    required this.isPlaying,
    required this.onPlayPause,
    this.isFullscreen = false,
    required this.cameraNumber,
    this.needsInit = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: VlcPlayer(
              key: ValueKey(
                'vlc_player_${isFullscreen ? 'fullscreen_' : ''}$cameraNumber',
              ),
              controller: controller,
              aspectRatio: 16 / 9,
              placeholder: const Center(child: CircularProgressIndicator()),
            ),
          ),
          if (!isPlaying || needsInit)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.5),
                child: Center(
                  child: GestureDetector(
                    onTap: () => onPlayPause(true),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          needsInit ? Icons.refresh : Icons.play_arrow,
                          color: Colors.black,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (isPlaying && !needsInit)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => onPlayPause(false),
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
