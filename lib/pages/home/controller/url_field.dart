import 'package:flutter/material.dart';

class UrlFieldDialog extends StatefulWidget {
  const UrlFieldDialog({Key? key}) : super(key: key);

  @override
  State<UrlFieldDialog> createState() => _UrlFieldDialogState();
}

class _UrlFieldDialogState extends State<UrlFieldDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  void _onSave() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorText = 'Please enter a URL';
      });
      return;
    }
    final uri = Uri.tryParse(text);
    if (uri == null || (!uri.isAbsolute)) {
      setState(() {
        _errorText = 'Please enter a valid URL';
      });
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add Camera URL',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black, // Black text
        ),
      ),
      content: SizedBox(
        width: 300, // Set fixed width for the dialog content
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Camera URL',
            errorText: _errorText,
            hintText: 'Enter RTSP or HTTP URL',
            border: OutlineInputBorder(), // Makes input field a box
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black, // Black background
            foregroundColor: Colors.white, // White text
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
