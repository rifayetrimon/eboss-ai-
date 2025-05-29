import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketController extends GetxController {
  final List<WebSocketChannel> _channels = [];
  final cameras = List<ui.Image?>.filled(4, null).obs;
  final isLoading = List<bool>.filled(4, true).obs;
  final hasError = List<bool>.filled(4, false).obs;

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
        print('WebSocket connection error: $e');
      }
    }
  }

  void _handleMessage(String message, int index) async {
    try {
      final data = jsonDecode(message);
      if (data['image'] != null) {
        final bytes = base64Decode(data['image']);
        final image = await decodeImageFromList(bytes);

        cameras[index] = image;
        isLoading[index] = false;
        hasError[index] = false;
        cameras.refresh();
      }
    } catch (e) {
      _handleError(index);
      print('Message handling error: $e');
    }
  }

  void _handleError(int index) {
    hasError[index] = true;
    isLoading[index] = false;
    cameras.refresh();
  }

  void _handleDisconnect(int index) {
    isLoading[index] = true;
    cameras.refresh();
  }

  Future<ui.Image> decodeImageFromList(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void onClose() {
    for (var channel in _channels) {
      channel.sink.close();
    }
    super.onClose();
  }
}
