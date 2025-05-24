import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final List<String?> cameraUrls = [
    'rtsp://admin:JZRGJS@192.168.0.104:554/h264/ch01/sub/av_stream',
    null,
    'rtsp://admin:DKIONN@192.168.0.224:554/h264/ch01/sub/av_stream',
    '',
  ];

  final List<VlcPlayerController?> _controllers = [];
  final List<bool> _hasError = [];

  // Store prediction results per camera index
  final List<String> _predictedLabels = [];
  final List<double> _predictedProbabilities = [];

  // Timer for periodic API calls
  Timer? _timer;

  // Flag to prevent overlapping API calls
  bool _isFetching = false;

  // Replace with your actual backend IP and port
  final String apiUrl = 'http://localhost:8000/predict_from_camera';

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    // Initialize prediction lists with default values
    for (int i = 0; i < cameraUrls.length; i++) {
      _predictedLabels.add('');
      _predictedProbabilities.add(0.0);
    }

    // Start periodic prediction fetching every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchPredictionsForAllCameras();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller?.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _initializeControllers() {
    _controllers.clear();
    _hasError.clear();

    for (var url in cameraUrls) {
      if (url != null && url.isNotEmpty) {
        final controller = VlcPlayerController.network(
          url,
          hwAcc: HwAcc.full,
          autoPlay: true,
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              VlcAdvancedOptions.networkCaching(2000),
              '--rtsp-tcp',
            ]),
          ),
        );

        _controllers.add(controller);
        _hasError.add(false);
      } else {
        _controllers.add(null);
        _hasError.add(false);
      }
    }

    for (int i = 0; i < _controllers.length; i++) {
      final controller = _controllers[i];
      if (controller != null) {
        controller.addListener(() {
          if (!mounted) return;
          if (controller.value.hasError && !_hasError[i]) {
            setState(() {
              _hasError[i] = true;
            });
          }
        });
      }
    }

    setState(() {});
  }

  Future<void> _fetchPredictionsForAllCameras() async {
    if (_isFetching) return; // Prevent overlapping calls
    _isFetching = true;

    for (int i = 0; i < cameraUrls.length; i++) {
      if (cameraUrls[i] != null && cameraUrls[i]!.isNotEmpty) {
        try {
          final response = await http.post(Uri.parse(apiUrl));
          debugPrint('API response status for camera $i: ${response.statusCode}');
          debugPrint('API response body for camera $i: ${response.body}');
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (mounted) {
              setState(() {
                _predictedLabels[i] = data['predicted_label'] ?? '';
                _predictedProbabilities[i] =
                    (data['predicted_probability'] ?? 0.0).toDouble();
              });
            }
          } else {
            debugPrint('API error for camera $i: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Error fetching prediction for camera $i: $e');
        }
      }
    }

    _isFetching = false;
  }

  Widget _buildCameraView(int index) {
    final controller = _controllers[index];
    final hasError = _hasError[index];

    if (controller == null || hasError) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: const Center(
          child: Text(
            'Add AI Camera',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: VlcPlayer(
            key: ValueKey(controller.hashCode),
            controller: controller,
            aspectRatio: 16 / 9,
            placeholder: const Center(child: CircularProgressIndicator()),
            virtualDisplay: true,
          ),
        ),
        // Prediction overlay at bottom left with 20px left padding
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.only(left: 20, right: 6, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${_predictedLabels[index]}${_predictedLabels[index].isNotEmpty ? ' (${(_predictedProbabilities[index] * 100).toStringAsFixed(1)}%)' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        itemCount: cameraUrls.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 16 / 9,
        ),
        itemBuilder: (context, index) {
          return _buildCameraView(index);
        },
      ),
    );
  }
}