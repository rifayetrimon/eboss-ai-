import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'dart:async';
import 'dart:developer' as developer;

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

class _CameraGridState extends State<CameraGrid> with WidgetsBindingObserver {
  int? fullscreenCamera;
  final List<VlcPlayerController?> _controllers = [];
  final List<bool> _isPlayingList = [];
  final List<bool> _needsInitialization = [];
  final List<UniqueKey> _playerKeys = [];
  bool _isTransitioning = false;
  bool _isFullscreenLoading = false;

  // Keep track of all timers to cancel them when needed
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // App is in background, pause all players
      _pauseAllPlayers();
    }
  }

  void _pauseAllPlayers() {
    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i] != null && _isPlayingList[i]) {
        try {
          _controllers[i]!.pause();
        } catch (e) {
          developer.log('Error pausing player: $e');
        }
      }
    }
  }

  void _cancelTimers() {
    for (var timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _initializeControllers() {
    _controllers.clear();
    _isPlayingList.clear();
    _needsInitialization.clear();
    _playerKeys.clear();

    for (int i = 0; i < CameraGrid.cameraUrls.length; i++) {
      _controllers.add(null);
      _isPlayingList.add(false);
      _needsInitialization.add(true);
      _playerKeys.add(UniqueKey());
    }

    // Initialize controllers lazily
    for (int i = 0; i < CameraGrid.cameraUrls.length; i++) {
      _createController(i, autoPlay: false);
    }
  }

  // Create a controller without auto-playing
  void _createController(int index, {bool autoPlay = false}) {
    // Create the controller first
    if (_controllers[index] != null) {
      try {
        _controllers[index]!.dispose();
      } catch (e) {
        developer.log('Error disposing controller: $e');
      }
    }

    final controller = VlcPlayerController.network(
      CameraGrid.cameraUrls[index],
      hwAcc: HwAcc.full,
      autoPlay: autoPlay,
      options: VlcPlayerOptions(advanced: VlcAdvancedOptions(['--rtsp-tcp'])),
    );

    setState(() {
      _controllers[index] = controller;
      _playerKeys[index] = UniqueKey();
      _needsInitialization[index] = false;
      _isPlayingList[index] = autoPlay;
    });

    // If we want to auto-play, wait for the controller to be created in the UI
    if (autoPlay) {
      final timer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && _controllers[index] != null) {
          try {
            _controllers[index]!.play();
            if (mounted) {
              setState(() {
                _isPlayingList[index] = true;
              });
            }
          } catch (e) {
            developer.log('Error playing: $e');
          }
        }
      });
      _timers.add(timer);
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    for (var controller in _controllers) {
      if (controller != null) {
        try {
          controller.dispose();
        } catch (e) {
          developer.log('Error disposing controller: $e');
        }
      }
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _streamAll() {
    if (_isTransitioning) return;

    for (int i = 0; i < CameraGrid.cameraUrls.length; i++) {
      if (_controllers[i] == null || _needsInitialization[i]) {
        _createController(i, autoPlay: true);
      } else if (!_isPlayingList[i]) {
        try {
          _controllers[i]!.play();
          setState(() {
            _isPlayingList[i] = true;
          });
        } catch (e) {
          developer.log('Error playing all: $e');
        }
      }
    }
  }

  Future<void> _enterFullscreen(int cameraIndex) async {
    if (_isTransitioning) return;

    setState(() {
      _isTransitioning = true;
      _isFullscreenLoading = true;
    });

    // Pause and dispose all other controllers safely
    for (int i = 0; i < _controllers.length; i++) {
      if (i != cameraIndex && _controllers[i] != null) {
        try {
          if (_isPlayingList[i]) {
            _controllers[i]!.pause();
          }
          _controllers[i]!.dispose();
          _controllers[i] = null;
          _needsInitialization[i] = true;
          _isPlayingList[i] = false;
        } catch (e) {
          developer.log('Error disposing controller during fullscreen: $e');
        }
      }
    }

    // Set fullscreen camera index
    setState(() {
      fullscreenCamera = cameraIndex;
    });

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Create a new controller specifically for fullscreen
    // We'll do this after UI changes so we don't get state conflicts
    final timer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      // Create fullscreen controller
      final fullscreenController = VlcPlayerController.network(
        CameraGrid.cameraUrls[cameraIndex],
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            '--rtsp-tcp',
            '--network-caching=1000',
          ]),
        ),
      );

      // Set fullscreen controller
      if (mounted) {
        setState(() {
          // Dispose old controller if it exists
          if (_controllers[cameraIndex] != null) {
            try {
              _controllers[cameraIndex]!.dispose();
            } catch (e) {
              developer.log('Error disposing old controller: $e');
            }
          }

          _controllers[cameraIndex] = fullscreenController;
          _playerKeys[cameraIndex] = UniqueKey();
          _isPlayingList[cameraIndex] = true;
          _needsInitialization[cameraIndex] = false;
          _isFullscreenLoading = false;
          _isTransitioning = false;
        });
      } else {
        // If widget is unmounted, dispose the controller
        fullscreenController.dispose();
      }
    });
    _timers.add(timer);
  }

  Future<void> _exitFullscreen() async {
    if (_isTransitioning) return;

    setState(() {
      _isTransitioning = true;
    });

    final int previousFullscreenCamera = fullscreenCamera!;

    // First set UI state to exit fullscreen
    setState(() {
      fullscreenCamera = null;
    });

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Now dispose all controllers safely
    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i] != null) {
        try {
          _controllers[i]!.dispose();
          _controllers[i] = null;
        } catch (e) {
          developer.log(
            'Error disposing controller during exit fullscreen: $e',
          );
        }
      }
      _needsInitialization[i] = true;
      _isPlayingList[i] = false;
    }

    // Wait for UI to update
    final timer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // Recreate all controllers
      for (int i = 0; i < CameraGrid.cameraUrls.length; i++) {
        _createController(i, autoPlay: i == previousFullscreenCamera);
      }

      if (mounted) {
        setState(() {
          _isTransitioning = false;
        });
      }
    });
    _timers.add(timer);
  }

  void _setPlaying(int cameraIndex, bool playing) {
    if (_isTransitioning) return;

    if (playing) {
      if (_controllers[cameraIndex] == null ||
          _needsInitialization[cameraIndex]) {
        _createController(cameraIndex, autoPlay: true);
      } else {
        try {
          _controllers[cameraIndex]!.play();
          setState(() {
            _isPlayingList[cameraIndex] = true;
          });
        } catch (e) {
          developer.log('Error playing: $e');
        }
      }
    } else if (_controllers[cameraIndex] != null &&
        _isPlayingList[cameraIndex]) {
      try {
        _controllers[cameraIndex]!.pause();
        setState(() {
          _isPlayingList[cameraIndex] = false;
        });
      } catch (e) {
        developer.log('Error pausing: $e');
      }
    }
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
                child:
                    _isFullscreenLoading
                        ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Loading camera feed...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        )
                        : _controllers[idx] == null
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Failed to load camera feed',
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed:
                                    () =>
                                        _createController(idx, autoPlay: true),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                        : FullscreenCameraView(
                          controller: _controllers[idx]!,
                          playerKey: _playerKeys[idx],
                        ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  idx == 0 ? "Main Camera" : "Camera $idx",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
              onPressed: _isTransitioning ? null : _exitFullscreen,
              child: const Icon(Icons.fullscreen_exit, color: Colors.black),
            ),
          ),
          if (_controllers[idx] != null && _isPlayingList[idx])
            Positioned(
              bottom: 24,
              left: 24,
              child: FloatingActionButton(
                heroTag: "pause_fullscreen",
                backgroundColor: Colors.white.withOpacity(0.7),
                onPressed: () => _setPlaying(idx, false),
                child: const Icon(Icons.pause, color: Colors.black),
              ),
            ),
          if (_controllers[idx] != null && !_isPlayingList[idx])
            Positioned(
              bottom: 24,
              left: 24,
              child: FloatingActionButton(
                heroTag: "play_fullscreen",
                backgroundColor: Colors.white.withOpacity(0.7),
                onPressed: () => _setPlaying(idx, true),
                child: const Icon(Icons.play_arrow, color: Colors.black),
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
                        playerKey: _playerKeys[0],
                        isPlaying: _isPlayingList[0],
                        onPlayPause: (playing) => _setPlaying(0, playing),
                        onFullscreen:
                            _isTransitioning ? null : () => _enterFullscreen(0),
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
                              playerKey: _playerKeys[1],
                              isPlaying: _isPlayingList[1],
                              onPlayPause: (playing) => _setPlaying(1, playing),
                              onFullscreen:
                                  _isTransitioning
                                      ? null
                                      : () => _enterFullscreen(1),
                              needsInit: _needsInitialization[1],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _CameraContainer(
                              cameraNumber: 2,
                              label: "Camera 2",
                              controller: _controllers[2],
                              playerKey: _playerKeys[2],
                              isPlaying: _isPlayingList[2],
                              onPlayPause: (playing) => _setPlaying(2, playing),
                              onFullscreen:
                                  _isTransitioning
                                      ? null
                                      : () => _enterFullscreen(2),
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
            onPressed: _isTransitioning ? null : _streamAll,
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

// A dedicated widget for fullscreen to simplify controller management
class FullscreenCameraView extends StatelessWidget {
  final VlcPlayerController controller;
  final Key playerKey;

  const FullscreenCameraView({
    required this.controller,
    required this.playerKey,
  });

  @override
  Widget build(BuildContext context) {
    return VlcPlayer(
      controller: controller,
      aspectRatio: 16 / 9,
      placeholder: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _CameraContainer extends StatelessWidget {
  final int cameraNumber;
  final String label;
  final VlcPlayerController? controller;
  final Key playerKey;
  final bool isPlaying;
  final ValueChanged<bool> onPlayPause;
  final VoidCallback? onFullscreen;
  final bool showFullscreen;
  final bool needsInit;

  const _CameraContainer({
    Key? key,
    required this.cameraNumber,
    required this.label,
    required this.controller,
    required this.playerKey,
    required this.isPlaying,
    required this.onPlayPause,
    this.onFullscreen,
    this.showFullscreen = true,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                controller == null
                    ? _buildPlaceholder()
                    : CameraStreamWidget(
                      controller: controller!,
                      playerKey: playerKey,
                      isPlaying: isPlaying,
                      onPlayPause: onPlayPause,
                      cameraNumber: cameraNumber,
                      needsInit: needsInit,
                    ),
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
                    controller == null || needsInit
                        ? Colors.orange
                        : (isPlaying ? Colors.green : Colors.red),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
          if (showFullscreen &&
              onFullscreen != null &&
              isPlaying &&
              controller != null)
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

  Widget _buildPlaceholder() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black.withOpacity(0.2),
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
              child: const Center(
                child: Icon(Icons.play_arrow, color: Colors.black, size: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CameraStreamWidget extends StatelessWidget {
  final VlcPlayerController controller;
  final Key playerKey;
  final bool isPlaying;
  final ValueChanged<bool> onPlayPause;
  final int cameraNumber;
  final bool needsInit;

  const CameraStreamWidget({
    required this.controller,
    required this.playerKey,
    required this.isPlaying,
    required this.onPlayPause,
    required this.cameraNumber,
    this.needsInit = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          VlcPlayer(
            key: playerKey,
            controller: controller,
            aspectRatio: 16 / 9,
            placeholder: const Center(child: CircularProgressIndicator()),
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
