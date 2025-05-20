import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
// import 'dart:typed_data';
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
  int? settingsCamera;
  final List<VlcPlayerController?> _controllers = [];
  final List<bool> _isPlayingList = [];
  final List<bool> _needsInitialization = [];
  final List<UniqueKey> _playerKeys = [];
  final List<ScreenshotController> _screenshotControllers = [];
  bool _isTransitioning = false;
  bool _isFullscreenLoading = false;

  final List<Timer> _timers = [];

  // Controller message overlay
  String? _controllerMessage;
  Timer? _controllerMessageTimer;

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
    _screenshotControllers.clear();

    for (int i = 0; i < CameraGrid.cameraUrls.length; i++) {
      _controllers.add(null);
      _isPlayingList.add(false);
      _needsInitialization.add(true);
      _playerKeys.add(UniqueKey());
      _screenshotControllers.add(ScreenshotController());
    }

    for (int i = 0; i < CameraGrid.cameraUrls.length; i++) {
      _createController(i, autoPlay: false);
    }
  }

  void _createController(int index, {bool autoPlay = false}) {
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
    _controllerMessageTimer?.cancel();
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

    setState(() {
      fullscreenCamera = cameraIndex;
      settingsCamera = null;
    });

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final timer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;

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

      if (mounted) {
        setState(() {
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
        fullscreenController.dispose();
      }
    });
    _timers.add(timer);
  }

  Future<void> _enterSettings(int cameraIndex) async {
    if (_isTransitioning) return;

    setState(() {
      _isTransitioning = true;
      _isFullscreenLoading = true;
    });

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
          developer.log('Error disposing controller during settings: $e');
        }
      }
    }

    setState(() {
      fullscreenCamera = null;
      settingsCamera = cameraIndex;
    });

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final timer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      final settingsController = VlcPlayerController.network(
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

      if (mounted) {
        setState(() {
          if (_controllers[cameraIndex] != null) {
            try {
              _controllers[cameraIndex]!.dispose();
            } catch (e) {
              developer.log('Error disposing old controller: $e');
            }
          }

          _controllers[cameraIndex] = settingsController;
          _playerKeys[cameraIndex] = UniqueKey();
          _isPlayingList[cameraIndex] = true;
          _needsInitialization[cameraIndex] = false;
          _isFullscreenLoading = false;
          _isTransitioning = false;
        });
      } else {
        settingsController.dispose();
      }
    });
    _timers.add(timer);
  }

  Future<void> _exitFullscreenOrSettings() async {
    if (_isTransitioning) return;

    setState(() {
      _isTransitioning = true;
    });

    final int? previousCamera = fullscreenCamera ?? settingsCamera;

    setState(() {
      fullscreenCamera = null;
      settingsCamera = null;
    });

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i] != null) {
        try {
          _controllers[i]!.dispose();
          _controllers[i] = null;
        } catch (e) {
          developer.log(
            'Error disposing controller during exit fullscreen/settings: $e',
          );
        }
      }
      _needsInitialization[i] = true;
      _isPlayingList[i] = false;
    }

    final timer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      for (int i = 0; i < CameraGrid.cameraUrls.length; i++) {
        _createController(i, autoPlay: i == previousCamera);
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

  void _onRecord(int cameraIndex) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Record pressed for Camera ${cameraIndex + 1}')),
    );
  }

  Future<void> _onScreenshot(int cameraIndex) async {
    // Request permissions if needed
    if (await Permission.storage.request().isGranted ||
        await Permission.photos.request().isGranted) {
      try {
        final image = await _screenshotControllers[cameraIndex].capture();
        if (image != null) {
          final result = await ImageGallerySaverPlus.saveImage(
            Uint8List.fromList(image),
            quality: 100,
            name:
                "camera_${cameraIndex + 1}_${DateTime.now().millisecondsSinceEpoch}",
          );
          if (result['isSuccess'] == true || result['isSuccess'] == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Screenshot saved to gallery!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save screenshot.')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permission denied!')));
    }
  }

  void _onCameraControl(String action, int cameraIndex) {
    setState(() {
      _controllerMessage = 'Camera ${cameraIndex + 1}: $action';
    });
    _controllerMessageTimer?.cancel();
    _controllerMessageTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _controllerMessage = null;
        });
      }
    });
    // TODO: Add your actual PTZ/camera control logic here
  }

  @override
  Widget build(BuildContext context) {
    // Settings mode: show camera fullscreen with control panel
    if (settingsCamera != null) {
      final idx = settingsCamera!;
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
          // Camera control panel overlay
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: CameraControlPanel(
                onControl: (action) => _onCameraControl(action, idx),
              ),
            ),
          ),
          // Overlay controller message (top center)
          if (_controllerMessage != null)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _controllerMessage != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _controllerMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                  idx == 0 ? "Main Camera Settings" : "Camera $idx Settings",
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
            top: 24,
            right: 24,
            child: FloatingActionButton(
              heroTag: "exit_settings",
              backgroundColor: Colors.white.withOpacity(0.7),
              onPressed: _isTransitioning ? null : _exitFullscreenOrSettings,
              child: const Icon(Icons.close, color: Colors.black),
            ),
          ),
        ],
      );
    }

    // Fullscreen mode
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
              onPressed: _isTransitioning ? null : _exitFullscreenOrSettings,
              child: const Icon(Icons.fullscreen_exit, color: Colors.black),
            ),
          ),
        ],
      );
    }

    // Normal grid view with side cameras matching main camera height
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Padding
            const double horizontalPadding = 16.0;
            const double betweenCamerasPadding = 10.0;
            const double betweenColumnsPadding = 10.0;

            // Calculate available width for the row
            final double totalWidth =
                constraints.maxWidth -
                (2 * horizontalPadding) -
                betweenColumnsPadding;
            final double mainCameraFlex = 4;
            final double sideCameraFlex = 2;
            final double totalFlex = mainCameraFlex + sideCameraFlex;
            final double mainCameraWidth =
                totalWidth * mainCameraFlex / totalFlex;
            final double sideColumnWidth =
                totalWidth * sideCameraFlex / totalFlex;

            // Main camera height (16:9)
            final double mainCameraHeight = mainCameraWidth / (16 / 9);

            // Each side camera height (split the column, minus padding)
            final double eachSideCameraHeight =
                (mainCameraHeight - betweenCamerasPadding) / 2;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Camera
                      SizedBox(
                        width: mainCameraWidth,
                        height: mainCameraHeight,
                        child: _CameraContainer(
                          cameraNumber: 0,
                          label: "Main Camera",
                          controller: _controllers[0],
                          playerKey: _playerKeys[0],
                          isPlaying: _isPlayingList[0],
                          onPlayPause: (playing) => _setPlaying(0, playing),
                          onFullscreen:
                              _isTransitioning
                                  ? null
                                  : () => _enterFullscreen(0),
                          needsInit: _needsInitialization[0],
                          onRecord: () => _onRecord(0),
                          onScreenshot: () => _onScreenshot(0),
                          onSettings: () => _enterSettings(0),
                          screenshotController: _screenshotControllers[0],
                        ),
                      ),
                      SizedBox(width: betweenColumnsPadding),
                      // Side cameras stacked vertically
                      SizedBox(
                        width: sideColumnWidth,
                        height: mainCameraHeight,
                        child: Column(
                          children: [
                            SizedBox(
                              height: eachSideCameraHeight,
                              child: _CameraContainer(
                                cameraNumber: 1,
                                label: "Camera 1",
                                controller: _controllers[1],
                                playerKey: _playerKeys[1],
                                isPlaying: _isPlayingList[1],
                                onPlayPause:
                                    (playing) => _setPlaying(1, playing),
                                onFullscreen:
                                    _isTransitioning
                                        ? null
                                        : () => _enterFullscreen(1),
                                needsInit: _needsInitialization[1],
                                onRecord: () => _onRecord(1),
                                onScreenshot: () => _onScreenshot(1),
                                onSettings: () => _enterSettings(1),
                                screenshotController: _screenshotControllers[1],
                              ),
                            ),
                            SizedBox(height: betweenCamerasPadding),
                            SizedBox(
                              height: eachSideCameraHeight,
                              child: _CameraContainer(
                                cameraNumber: 2,
                                label: "Camera 2",
                                controller: _controllers[2],
                                playerKey: _playerKeys[2],
                                isPlaying: _isPlayingList[2],
                                onPlayPause:
                                    (playing) => _setPlaying(2, playing),
                                onFullscreen:
                                    _isTransitioning
                                        ? null
                                        : () => _enterFullscreen(2),
                                needsInit: _needsInitialization[2],
                                onRecord: () => _onRecord(2),
                                onScreenshot: () => _onScreenshot(2),
                                onSettings: () => _enterSettings(2),
                                screenshotController: _screenshotControllers[2],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Second row: Placeholders
                  Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _EmptyCameraPlaceholder(cameraNumber: 3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _EmptyCameraPlaceholder(cameraNumber: 4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _EmptyCameraPlaceholder(cameraNumber: 5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32), // Add bottom padding for FAB
                ],
              ),
            );
          },
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

// Camera control panel widget (simple PTZ example)
class CameraControlPanel extends StatelessWidget {
  final ValueChanged<String> onControl;
  const CameraControlPanel({required this.onControl});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Directional controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => onControl('up'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => onControl('left'),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white, size: 32),
                    onPressed: () => onControl('home'),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => onControl('right'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_downward,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => onControl('down'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Zoom controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.zoom_out,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => onControl('zoom_out'),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => onControl('zoom_in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
  final VoidCallback? onRecord;
  final Future<void> Function()? onScreenshot;
  final VoidCallback? onSettings;
  final ScreenshotController? screenshotController;

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
    this.onRecord,
    this.onScreenshot,
    this.onSettings,
    this.screenshotController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget cameraWidget =
        controller == null
            ? _buildPlaceholder()
            : CameraStreamWidget(
              controller: controller!,
              playerKey: playerKey,
              isPlaying: isPlaying,
              onPlayPause: onPlayPause,
              cameraNumber: cameraNumber,
              needsInit: needsInit,
            );

    // Wrap with Screenshot for screenshot functionality
    if (screenshotController != null) {
      cameraWidget = Screenshot(
        controller: screenshotController!,
        child: cameraWidget,
      );
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: cameraWidget,
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
          // Camera action buttons row
          if (controller != null)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Record
                  IconButton(
                    icon: const Icon(
                      Icons.fiber_manual_record,
                      color: Colors.red,
                    ),
                    tooltip: 'Record',
                    onPressed: onRecord,
                  ),
                  // Screenshot
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    tooltip: 'Screenshot',
                    onPressed: onScreenshot,
                  ),
                  // Settings
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'Settings',
                    onPressed: onSettings,
                  ),
                  // Fullscreen
                  if (showFullscreen && onFullscreen != null && isPlaying)
                    IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      tooltip: 'Fullscreen',
                      onPressed: onFullscreen,
                    ),
                  // Play/Pause
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    tooltip: isPlaying ? 'Pause' : 'Play',
                    onPressed: () => onPlayPause(!isPlaying),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
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
    return Stack(
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
      ],
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
