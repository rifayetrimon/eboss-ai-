// import 'package:flutter/material.dart';

// class AiPage extends StatelessWidget {
//   const AiPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Text(
//         'AI Content',
//         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'dart:developer' as developer;

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  VlcPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  void _setupCamera() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      developer.log('Attempting to connect to camera...');

      // Dispose previous controller if any
      _controller?.dispose();

      // Create controller with autoPlay: true
      final controller = VlcPlayerController.network(
        'rtsp://admin:JZRGJS@192.168.0.104:554/h264/ch01/sub/av_stream',
        hwAcc: HwAcc.full,
        autoPlay: true, // <-- THIS IS THE KEY
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(2000),
            '--rtsp-tcp',
          ]),
        ),
      );

      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Exception setting up camera: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Setup error: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Camera Stream',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  _isLoading
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Connecting to camera...'),
                          ],
                        ),
                      )
                      : _hasError
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text('Failed to connect to camera'),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _setupCamera,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                      : _controller != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: VlcPlayer(
                          controller: _controller!,
                          aspectRatio: 16 / 9,
                          placeholder: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                      : const Center(child: Text('Controller not initialized')),
            ),
          ),
        ],
      ),
    );
  }
}
