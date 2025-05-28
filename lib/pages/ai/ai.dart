import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:eboss_ai/pages/home/controller/home_controller.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final HomeController controller = Get.find<HomeController>();

  late List<String?> cameraUrls;
  late List<VlcPlayerController?> _controllers;
  late List<bool> _isPlayingList;
  late List<bool> _hasError;

  bool _isPaused = false;

  final List<Map<String, String>> _users = [
    {"name": "Alex", "avatar": "assets/images/profile/user1.png"},
    {"name": "Jordan", "avatar": "assets/images/profile/user2.png"},
    {"name": "Malik", "avatar": "assets/images/profile/user3.png"},
    {"name": "Sam", "avatar": "assets/images/profile/user4.png"},
    {"name": "Leah", "avatar": "assets/images/profile/user5.png"},
  ];

  late List<List<_LiveComment>> _activeCommentsPerCamera;
  late List<int> _commentIndicesPerCamera;
  late List<Timer?> _commentTimersPerCamera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _updateCameraUrls();

    _initializeState();
    _initializeControllers();

    _activeCommentsPerCamera = List.generate(cameraUrls.length, (_) => []);
    _commentIndicesPerCamera = List.generate(cameraUrls.length, (_) => 0);
    _commentTimersPerCamera = List.generate(cameraUrls.length, (_) => null);

    // Listen for changes in AI camera selection
    ever(controller.aiCameraIndexes, (_) {
      if (mounted) {
        _updateCameraUrls();
        _initializeState();
        _initializeControllers();
        setState(() {});
      }
    });
  }

  void _updateCameraUrls() {
    cameraUrls =
        controller.aiCameraIndexes
            .map(
              (index) =>
                  index < controller.cameraUrls.length
                      ? controller.cameraUrls[index]
                      : null,
            )
            .toList();
  }

  void _initializeState() {
    final length = cameraUrls.length;
    _controllers = List<VlcPlayerController?>.filled(length, null);
    _isPlayingList = List<bool>.filled(length, false);
    _hasError = List<bool>.filled(length, false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _pauseAllPlayers();
      _pauseComments();
    } else if (state == AppLifecycleState.resumed) {
      _resumeComments();
    }
  }

  void _pauseAllPlayers() {
    for (int i = 0; i < _controllers.length; i++) {
      final controller = _controllers[i];
      if (controller != null && _isPlayingList[i]) {
        try {
          controller.pause();
          _isPlayingList[i] = false;
        } catch (e) {
          developer.log('Error pausing player: $e');
        }
      }
    }
  }

  void _pauseComments() {
    _isPaused = true;
    for (int i = 0; i < _commentTimersPerCamera.length; i++) {
      _commentTimersPerCamera[i]?.cancel();
      _commentTimersPerCamera[i] = null;
      _activeCommentsPerCamera[i].clear();
    }
    setState(() {}); // Refresh UI to clear comments
  }

  void _resumeComments() {
    if (!_isPaused) return;
    _isPaused = false;
    for (int i = 0; i < cameraUrls.length; i++) {
      if ((cameraUrls[i]?.isNotEmpty ?? false) && _isPlayingList[i]) {
        if (_commentTimersPerCamera[i] == null) {
          _startCommentStream(i);
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller?.dispose();
    }
    for (var commentList in _activeCommentsPerCamera) {
      for (var comment in commentList) {
        comment.controller.dispose();
      }
    }
    for (var timer in _commentTimersPerCamera) {
      timer?.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initializeControllers() {
    for (int i = 0; i < cameraUrls.length; i++) {
      _createController(i, autoPlay: false);
    }
  }

  void _createController(int index, {bool autoPlay = false}) {
    if (index >= cameraUrls.length) return;

    final oldController = _controllers[index];
    oldController?.dispose();

    final url = cameraUrls[index];
    if (url == null || url.isEmpty) {
      if (mounted) {
        setState(() {
          _controllers[index] = null;
          _hasError[index] = true;
        });
      }
      return;
    }

    try {
      final controller = VlcPlayerController.network(
        url,
        hwAcc: HwAcc.full,
        autoPlay: autoPlay,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            '--rtsp-tcp',
            VlcAdvancedOptions.networkCaching(2000),
          ]),
        ),
      );

      controller.addListener(() {
        if (!mounted) return;
        if (controller.value.hasError && !_hasError[index]) {
          setState(() => _hasError[index] = true);
        }
      });

      if (mounted) {
        setState(() {
          _controllers[index] = controller;
          _isPlayingList[index] = autoPlay;
          _hasError[index] = false;
        });
      }
    } catch (e) {
      developer.log('Error creating controller: $e');
      if (mounted) {
        setState(() {
          _controllers[index] = null;
          _hasError[index] = true;
        });
      }
    }
  }

  void _togglePlayPause(int index) {
    if (index >= _controllers.length || !mounted) return;

    final controller = _controllers[index];
    if (controller == null) return;

    setState(() {
      if (_isPlayingList[index]) {
        controller.pause();
        _isPlayingList[index] = false;
        _commentTimersPerCamera[index]?.cancel();
        _commentTimersPerCamera[index] = null;
        _activeCommentsPerCamera[index].clear();
      } else {
        controller.play();
        _isPlayingList[index] = true;
        // Comments stream disabled for demo
      }
    });
  }

  Future<List<String>> _fetchCommentsFromApi(int cameraIndex) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      "❤️ Awesome stream!",
      "🔥 Nice content!",
      "😍 Loving this!",
      "💪 Keep it up!",
      "😊 So cool!",
    ];
  }

  void _startCommentStream(int cameraIndex) {
    _commentTimersPerCamera[cameraIndex]?.cancel();

    _commentTimersPerCamera[cameraIndex] = Timer.periodic(
      const Duration(seconds: 3),
      (_) async {
        if (!mounted || _isPaused || !_isPlayingList[cameraIndex]) return;

        List<String> comments;
        try {
          comments = await _fetchCommentsFromApi(cameraIndex);
        } catch (e) {
          developer.log('Error fetching comments: $e');
          return;
        }

        if (comments.isEmpty) return;

        final commentText =
            comments[_commentIndicesPerCamera[cameraIndex] % comments.length];
        final user = _users[Random().nextInt(_users.length)];
        _commentIndicesPerCamera[cameraIndex]++;

        final controller = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 6),
        );

        final animation = Tween<Offset>(
          begin: const Offset(0, 1.0),
          end: const Offset(0, 0),
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

        final fadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

        final comment = _LiveComment(
          text: commentText,
          username: user['name']!,
          avatarPath: user['avatar']!,
          key: UniqueKey(),
          controller: controller,
          animation: animation,
          fadeAnimation: fadeAnimation,
        );

        controller.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            controller.dispose();
            if (!mounted) return;
            setState(() {
              _activeCommentsPerCamera[cameraIndex].removeWhere(
                (c) => c.key == comment.key,
              );
            });
          }
        });

        setState(() {
          _activeCommentsPerCamera[cameraIndex].add(comment);
        });

        controller.forward();
      },
    );
  }

  Widget _buildCameraTile(int index) {
    if (index >= cameraUrls.length) return const SizedBox.shrink();

    final controller = _controllers[index];
    final hasError = _hasError[index];
    final isPlaying = _isPlayingList[index];

    final bool hasValidStream = controller != null && !hasError;

    return KeyedSubtree(
      key: ValueKey('camera_tile_$index'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color.fromARGB(255, 154, 154, 154),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color:
                hasValidStream
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : Colors.white.withOpacity(0.3),
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                if (hasValidStream)
                  Positioned.fill(
                    child: VlcPlayer(
                      key: ValueKey('camera_player_$index'),
                      controller: controller,
                      aspectRatio: 16 / 9,
                      placeholder: const Center(
                        child: CircularProgressIndicator(),
                      ),
                      virtualDisplay: true,
                    ),
                  )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Add AI Camera',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                if (hasValidStream)
                  Positioned(
                    left: 8,
                    bottom: 40,
                    child: SizedBox(
                      width: 220,
                      height: 100,
                      child: Stack(
                        children:
                            _activeCommentsPerCamera[index].asMap().entries.map(
                              (entry) {
                                int commentIndex = entry.key;
                                var comment = entry.value;

                                return SlideTransition(
                                  position: comment.animation,
                                  child: FadeTransition(
                                    opacity: comment.fadeAnimation,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        bottom: commentIndex * 30.0,
                                      ),
                                      child: Row(
                                        key: comment.key,
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundImage: AssetImage(
                                              comment.avatarPath,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.65,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  comment.username,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  comment.text,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                      ),
                    ),
                  ),

                if (hasValidStream)
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child:
                          isPlaying
                              ? GestureDetector(
                                onTap: () => _togglePlayPause(index),
                                child: Container(
                                  color: Colors.transparent,
                                  child: const Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.pause_circle_filled,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              : GestureDetector(
                                onTap: () => _togglePlayPause(index),
                                child: Container(
                                  color: Colors.black45,
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_fill,
                                      size: 48,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 16 / 9,
            ),
            itemCount: cameraUrls.length,
            itemBuilder: (context, index) => _buildCameraTile(index),
          ),
        ),
      ),
    );
  }
}

class _LiveComment {
  final String text;
  final String username;
  final String avatarPath;
  final Key key;
  final AnimationController controller;
  final Animation<Offset> animation;
  final Animation<double> fadeAnimation;

  _LiveComment({
    required this.text,
    required this.username,
    required this.avatarPath,
    required this.key,
    required this.controller,
    required this.animation,
    required this.fadeAnimation,
  });
}
