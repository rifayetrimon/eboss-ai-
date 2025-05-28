import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:eboss_ai/pages/home/controller/home_controller.dart';
import 'package:eboss_ai/pages/home/controller/url_field.dart';

class CameraGrid extends StatefulWidget {
  const CameraGrid({super.key});

  @override
  State<CameraGrid> createState() => _CameraGridState();
}

class _CameraGridState extends State<CameraGrid> with WidgetsBindingObserver {
  final HomeController controller = Get.find<HomeController>();

  final List<VlcPlayerController?> _controllers = [];
  final List<bool> _isPlayingList = [];
  final List<bool> _needsInitialization = [];
  final List<UniqueKey> _playerKeys = [];
  final List<ScreenshotController> _screenshotControllers = [];
  bool _isTransitioning = false;
  bool _isFullscreenLoading = false;

  final List<Timer> _timers = [];

  String? _controllerMessage;
  Timer? _controllerMessageTimer;

  int? fullscreenCamera;
  int? settingsCamera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();

    // React to mainCameraIndex changes to rebuild UI
    ever(controller.mainCameraIndex, (_) {
      if (mounted) setState(() {});
    });

    // React to cameraUrls changes to reinitialize controllers
    ever(controller.cameraUrls, (_) {
      if (mounted) _initializeControllers();
    });
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
      final c = _controllers[i];
      if (c != null && _isPlayingList[i]) {
        try {
          c.pause();
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

  Future<void> _showAddCameraDialog() async {
    final newUrl = await showDialog<String>(
      context: context,
      builder: (context) => const UrlFieldDialog(),
    );
    if (newUrl != null && newUrl.isNotEmpty) {
      controller.cameraUrls.add(newUrl);
    }
  }

  void _initializeControllers() {
    _cancelTimers();

    _controllers.clear();
    _isPlayingList.clear();
    _needsInitialization.clear();
    _playerKeys.clear();
    _screenshotControllers.clear();

    for (int i = 0; i < controller.cameraUrls.length; i++) {
      _controllers.add(null);
      _isPlayingList.add(false);
      _needsInitialization.add(true);
      _playerKeys.add(UniqueKey());
      _screenshotControllers.add(ScreenshotController());
    }

    for (int i = 0; i < controller.cameraUrls.length; i++) {
      _createController(i, autoPlay: false);
    }
  }

  void _createController(int index, {bool autoPlay = false}) {
    final oldController = _controllers[index];
    if (oldController != null) {
      try {
        oldController.dispose();
      } catch (e) {
        developer.log('Error disposing controller: $e');
      }
    }

    final controllerInstance = VlcPlayerController.network(
      controller.cameraUrls[index],
      hwAcc: HwAcc.full,
      autoPlay: autoPlay,
      options: VlcPlayerOptions(advanced: VlcAdvancedOptions(['--rtsp-tcp'])),
    );

    setState(() {
      _controllers[index] = controllerInstance;
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
    for (var c in _controllers) {
      if (c != null) {
        try {
          c.dispose();
        } catch (e) {
          developer.log('Error disposing controller: $e');
        }
      }
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setPlaying(int cameraIndex, bool playing) {
    if (_isTransitioning) return;

    final controllerInstance = _controllers[cameraIndex];

    if (playing) {
      if (controllerInstance == null || _needsInitialization[cameraIndex]) {
        _createController(cameraIndex, autoPlay: true);
      } else {
        try {
          controllerInstance.play();
          setState(() {
            _isPlayingList[cameraIndex] = true;
          });
        } catch (e) {
          developer.log('Error playing: $e');
        }
      }
    } else if (controllerInstance != null && _isPlayingList[cameraIndex]) {
      try {
        controllerInstance.pause();
        setState(() {
          _isPlayingList[cameraIndex] = false;
        });
      } catch (e) {
        developer.log('Error pausing: $e');
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
      if (i != cameraIndex) {
        final c = _controllers[i];
        if (c != null) {
          try {
            if (_isPlayingList[i]) {
              c.pause();
            }
            c.dispose();
            _controllers[i] = null;
            _needsInitialization[i] = true;
            _isPlayingList[i] = false;
          } catch (e) {
            developer.log('Error disposing controller during fullscreen: $e');
          }
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
        controller.cameraUrls[cameraIndex],
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
          final oldController = _controllers[cameraIndex];
          if (oldController != null) {
            try {
              oldController.dispose();
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
      if (i != cameraIndex) {
        final c = _controllers[i];
        if (c != null) {
          try {
            if (_isPlayingList[i]) {
              c.pause();
            }
            c.dispose();
            _controllers[i] = null;
            _needsInitialization[i] = true;
            _isPlayingList[i] = false;
          } catch (e) {
            developer.log('Error disposing controller during settings: $e');
          }
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
        controller.cameraUrls[cameraIndex],
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
          final oldController = _controllers[cameraIndex];
          if (oldController != null) {
            try {
              oldController.dispose();
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
      final c = _controllers[i];
      if (c != null) {
        try {
          c.dispose();
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

      for (int i = 0; i < controller.cameraUrls.length; i++) {
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

  void _onRecord(int cameraIndex) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Record pressed for Camera ${cameraIndex + 1}')),
    );
  }

  Future<void> _onScreenshot(int cameraIndex) async {
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
              const SnackBar(content: Text('Screenshot saved to gallery!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save screenshot.')),
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
  }

  @override
  Widget build(BuildContext context) {
    final mainIndex = controller.mainCameraIndex.value;
    final cameraCount = controller.cameraUrls.length;

    // Side cameras excluding main
    final sideCameraIndexes =
        List<int>.generate(
          cameraCount,
          (i) => i,
        ).where((i) => i != mainIndex).toList();

    // Settings mode
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
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: CameraControlPanel(
                onControl: (action) => _onCameraControl(action, idx),
              ),
            ),
          ),
          if (_controllerMessage != null)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: 1.0,
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
                  idx == mainIndex
                      ? "Main Camera Settings"
                      : "Camera $idx Settings",
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
                  idx == mainIndex ? "Main Camera" : "Camera $idx",
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
            const double horizontalPadding = 16.0;
            const double betweenCamerasPadding = 10.0;
            const double betweenColumnsPadding = 10.0;

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

            final double mainCameraHeight = mainCameraWidth / (16 / 9);
            final double eachSideCameraHeight =
                (mainCameraHeight - betweenCamerasPadding) / 2;

            Widget _buildAddCameraPlaceholder(int cameraNumber) {
              return GestureDetector(
                onTap: _showAddCameraDialog,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          size: 40,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add Camera ${cameraNumber + 1}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

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
                      SizedBox(
                        width: mainCameraWidth,
                        height: mainCameraHeight,
                        child:
                            mainIndex < _controllers.length
                                ? _CameraContainer(
                                  cameraNumber: mainIndex,
                                  label: "Main Camera",
                                  controller: _controllers[mainIndex],
                                  playerKey: _playerKeys[mainIndex],
                                  isPlaying: _isPlayingList[mainIndex],
                                  onPlayPause:
                                      (playing) =>
                                          _setPlaying(mainIndex, playing),
                                  onFullscreen:
                                      _isTransitioning
                                          ? null
                                          : () => _enterFullscreen(mainIndex),
                                  needsInit: _needsInitialization[mainIndex],
                                  onRecord: () => _onRecord(mainIndex),
                                  onScreenshot: () => _onScreenshot(mainIndex),
                                  onSettings: () => _enterSettings(mainIndex),
                                  screenshotController:
                                      _screenshotControllers[mainIndex],
                                )
                                : _buildAddCameraPlaceholder(mainIndex),
                      ),
                      SizedBox(width: betweenColumnsPadding),
                      SizedBox(
                        width: sideColumnWidth,
                        height: mainCameraHeight,
                        child: Column(
                          children: [
                            SizedBox(
                              height: eachSideCameraHeight,
                              child:
                                  sideCameraIndexes.length > 0 &&
                                          sideCameraIndexes[0] <
                                              _controllers.length
                                      ? _CameraContainer(
                                        cameraNumber: sideCameraIndexes[0],
                                        label: "Camera ${sideCameraIndexes[0]}",
                                        controller:
                                            _controllers[sideCameraIndexes[0]],
                                        playerKey:
                                            _playerKeys[sideCameraIndexes[0]],
                                        isPlaying:
                                            _isPlayingList[sideCameraIndexes[0]],
                                        onPlayPause:
                                            (playing) => _setPlaying(
                                              sideCameraIndexes[0],
                                              playing,
                                            ),
                                        onFullscreen:
                                            _isTransitioning
                                                ? null
                                                : () => _enterFullscreen(
                                                  sideCameraIndexes[0],
                                                ),
                                        needsInit:
                                            _needsInitialization[sideCameraIndexes[0]],
                                        onRecord:
                                            () =>
                                                _onRecord(sideCameraIndexes[0]),
                                        onScreenshot:
                                            () => _onScreenshot(
                                              sideCameraIndexes[0],
                                            ),
                                        onSettings:
                                            () => _enterSettings(
                                              sideCameraIndexes[0],
                                            ),
                                        screenshotController:
                                            _screenshotControllers[sideCameraIndexes[0]],
                                      )
                                      : _buildAddCameraPlaceholder(
                                        sideCameraIndexes.isNotEmpty
                                            ? sideCameraIndexes[0]
                                            : 1,
                                      ),
                            ),
                            SizedBox(height: betweenCamerasPadding),
                            SizedBox(
                              height: eachSideCameraHeight,
                              child:
                                  sideCameraIndexes.length > 1 &&
                                          sideCameraIndexes[1] <
                                              _controllers.length
                                      ? _CameraContainer(
                                        cameraNumber: sideCameraIndexes[1],
                                        label: "Camera ${sideCameraIndexes[1]}",
                                        controller:
                                            _controllers[sideCameraIndexes[1]],
                                        playerKey:
                                            _playerKeys[sideCameraIndexes[1]],
                                        isPlaying:
                                            _isPlayingList[sideCameraIndexes[1]],
                                        onPlayPause:
                                            (playing) => _setPlaying(
                                              sideCameraIndexes[1],
                                              playing,
                                            ),
                                        onFullscreen:
                                            _isTransitioning
                                                ? null
                                                : () => _enterFullscreen(
                                                  sideCameraIndexes[1],
                                                ),
                                        needsInit:
                                            _needsInitialization[sideCameraIndexes[1]],
                                        onRecord:
                                            () =>
                                                _onRecord(sideCameraIndexes[1]),
                                        onScreenshot:
                                            () => _onScreenshot(
                                              sideCameraIndexes[1],
                                            ),
                                        onSettings:
                                            () => _enterSettings(
                                              sideCameraIndexes[1],
                                            ),
                                        screenshotController:
                                            _screenshotControllers[sideCameraIndexes[1]],
                                      )
                                      : _buildAddCameraPlaceholder(
                                        sideCameraIndexes.length > 1
                                            ? sideCameraIndexes[1]
                                            : 2,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        3,
                        (i) => Padding(
                          padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                          child: SizedBox(
                            width: (totalWidth - 20) / 3,
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: _buildAddCameraPlaceholder(i + 3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
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
            onPressed:
                _isTransitioning
                    ? null
                    : () {
                      for (int i = 0; i < controller.cameraUrls.length; i++) {
                        _setPlaying(i, true);
                      }
                    },
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

// The rest of your CameraControlPanel, FullscreenCameraView, _CameraContainer, CameraStreamWidget remain unchanged.

class CameraControlPanel extends StatelessWidget {
  final ValueChanged<String> onControl;
  const CameraControlPanel({required this.onControl, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
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

class FullscreenCameraView extends StatelessWidget {
  final VlcPlayerController controller;
  final Key playerKey;

  const FullscreenCameraView({
    required this.controller,
    required this.playerKey,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VlcPlayer(
      key: playerKey,
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
          if (controller != null)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.red,
                      ),
                      tooltip: 'Record',
                      onPressed: onRecord,
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      tooltip: 'Screenshot',
                      onPressed: onScreenshot,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      tooltip: 'Settings',
                      onPressed: onSettings,
                    ),
                    if (showFullscreen && onFullscreen != null && isPlaying)
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                        tooltip: 'Fullscreen',
                        onPressed: onFullscreen,
                      ),
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
    Key? key,
  }) : super(key: key);

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
