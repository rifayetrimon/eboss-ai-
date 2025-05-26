import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> settingsItems = [
    'Make main Camera',
    'Add AI camera',
    'Notification Settings',
    'Privacy & Security',
    'System Updates',
  ];

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 220,
          color: Colors.white.withOpacity(0.3), // White with 0.3 opacity
          child: ListView.builder(
            itemCount: settingsItems.length,
            itemBuilder: (context, index) {
              final isSelected = index == selectedIndex;
              return ListTile(
                title: Text(settingsItems[index]),
                selected: isSelected,
                selectedTileColor: Colors.blue[100],
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              );
            },
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: _buildSettingDetails(selectedIndex),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingDetails(int index) {
    switch (index) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Make main Camera',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Configure which camera should be set as the main camera for your system.',
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Add AI camera',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Add and configure AI-powered cameras to enhance surveillance capabilities.',
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Notification Settings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Manage your notification preferences and alert settings.'),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Privacy & Security',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Adjust privacy controls and security options for your account.',
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'System Updates',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Check for system updates and manage update settings.'),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
