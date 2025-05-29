import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketController extends GetxController {
  final List<WebSocketChannel> _channels = [];
  final cameras = List<ui.Image?>.filled(4, null).obs;
  final isLoading = List<bool>.filled(4, true).obs;
  final hasError = List<bool>.filled(4, false).obs;
  final isPlaying = List<bool>.filled(4, false).obs;
  final lastImageBytes = List<Uint8List?>.filled(4, null).obs;

  final urls = [
    'ws://192.168.0.137:8000/ws/0',
    'ws://192.168.0.137:8000/ws/1',
    'ws://192.168.0.137:8000/ws/2',
    'ws://192.168.0.137:8000/ws/3',
  ];

  @override
  void onInit() {
    super.onInit();
    _initWebSockets();
  }

  void _initWebSockets() {
    for (int i = 0; i < urls.length; i++) {
      try {
        final channel = IOWebSocketChannel.connect(urls[i]);
        _channels.add(channel);

        channel.stream.listen(
          (message) => _handleMessage(message, i),
          onError: (error) => _handleError(i),
          onDone: () => _handleDisconnect(i),
        );
      } catch (e) {
        _handleError(i);
      }
    }
  }

  void _handleMessage(String message, int index) async {
    try {
      final data = jsonDecode(message);
      if (data['image'] != null) {
        final bytes = base64Decode(data['image']);
        lastImageBytes[index] = bytes;

        final image = await decodeImageFromList(bytes);
        cameras[index] = image;
        isLoading[index] = false;
        hasError[index] = false;
      }
    } catch (e) {
      _handleError(index);
    }
  }

  void _handleError(int index) {
    hasError[index] = true;
    isLoading[index] = false;
  }

  void _handleDisconnect(int index) {
    isLoading[index] = true;
  }

  Future<ui.Image> decodeImageFromList(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void togglePlayPause(int index) {
    isPlaying[index] = !isPlaying[index];

    if (isPlaying[index]) {
      isLoading[index] = true;
      hasError[index] = false;
    }
  }

  Future<void> saveScreenshot(int index) async {
    if (lastImageBytes[index] == null) return;

    if (await Permission.storage.request().isGranted ||
        await Permission.photos.request().isGranted) {
      try {
        final result = await ImageGallerySaverPlus.saveImage(
          lastImageBytes[index]!,
          quality: 100,
          name: "ai_camera_${index}_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (result['isSuccess'] == true || result['isSuccess'] == 1) {
          Get.snackbar('Success', 'Screenshot saved to gallery!');
        } else {
          Get.snackbar('Error', 'Failed to save screenshot');
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to save screenshot: $e');
      }
    } else {
      Get.snackbar('Permission Denied', 'Storage permission required');
    }
  }

  @override
  void onClose() {
    for (var channel in _channels) {
      channel.sink.close();
    }
    super.onClose();
  }
}
