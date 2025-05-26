import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> with WidgetsBindingObserver {
  final List<String?> cameraUrls = [
    'rtsp://admin:JZRGJS@192.168.0.104:554/h264/ch01/sub/av_stream',
    'rtsp://admin:DKIONN@192.168.0.224:554/h264/ch01/sub/av_stream',
    '',
    '',
  ];

  late final List<VlcPlayerController?> _controllers;
  late final List<bool> _isPlayingList;
  late final List<bool> _hasError;
  late final List<String> _predictedLabels;
  late final List<double> _predictedProbabilities;

  Timer? _timer;
  bool _isFetching = false;

  final String apiUrl = 'http://localhost:8000/predict_from_camera';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeState();
    _initializeControllers();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _fetchPredictionsForAllCameras();
    });
  }

  void _initializeState() {
    final length = cameraUrls.length;
    _controllers = List<VlcPlayerController?>.filled(length, null);
    _isPlayingList = List<bool>.filled(length, false);
    _hasError = List<bool>.filled(length, false);
    _predictedLabels = List<String>.filled(length, '');
    _predictedProbabilities = List<double>.filled(length, 0.0);
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
      final controller = _controllers[i];
      if (controller != null && _isPlayingList[i]) {
        try {
          controller.pause();
        } catch (e) {
          developer.log('Error pausing player: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller?.dispose();
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

  Future<void> _fetchPredictionsForAllCameras() async {
    if (_isFetching || !mounted) return;
    _isFetching = true;

    try {
      for (int i = 0; i < cameraUrls.length; i++) {
        if (cameraUrls[i]?.isNotEmpty ?? false) {
          final response = await http.post(Uri.parse(apiUrl));
          if (response.statusCode == 200 && mounted) {
            final data = json.decode(response.body);
            setState(() {
              _predictedLabels[i] = data['predicted_label']?.toString() ?? '';
              _predictedProbabilities[i] =
                  (data['predicted_probability'] as num?)?.toDouble() ?? 0.0;
            });
          }
        }
      }
    } catch (e) {
      developer.log('Error fetching predictions: $e');
    } finally {
      _isFetching = false;
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
      } else {
        controller.play();
        _isPlayingList[index] = true;
      }
    });
  }

  Widget _buildCameraTile(int index) {
    if (index >= cameraUrls.length) return const SizedBox.shrink();

    final controller = _controllers[index];
    final hasError = _hasError[index];
    final isPlaying = _isPlayingList[index];
    final label = _predictedLabels[index];
    final probability = _predictedProbabilities[index];

    final bool hasValidStream = controller != null && !hasError;

    return KeyedSubtree(
      key: ValueKey('camera_tile_$index'),
      child: Container(
        decoration: BoxDecoration(
          color:
              hasValidStream
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (hasValidStream)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VlcPlayer(
                  key: ValueKey('camera_player_$index'),
                  controller: controller!,
                  aspectRatio: 16 / 9,
                  placeholder: const Center(child: CircularProgressIndicator()),
                  virtualDisplay: false,
                ),
              )
            else
              const Center(
                child: Text(
                  'Add AI Camera',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

            if (hasValidStream)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label.isNotEmpty
                        ? '${label} (${(probability * 100).toStringAsFixed(1)}%)'
                        : 'Analyzing...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            if (hasValidStream && !isPlaying)
              Positioned.fill(
                child: GestureDetector(
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

            if (hasValidStream && isPlaying)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.pause_circle_filled,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () => _togglePlayPause(index),
                ),
              ),
          ],
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
