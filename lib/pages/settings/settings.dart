import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eboss_ai/pages/home/controller/home_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final HomeController controller = Get.find<HomeController>();

  final List<String> settingsItems = [
    'Make main Camera',
    'Select AI Cameras', // AI camera selection moved here (2nd item)
    'Notification Settings',
    'Privacy & Security',
    'System Updates',
  ];

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left column with margin on all sides
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
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
        ),

        // Right column with margin on all sides
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0), // margin on all sides
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(24),
              child: _buildSettingDetails(selectedIndex),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingDetails(int index) {
    switch (index) {
      case 0:
        return Obx(() {
          final mainIndex = controller.mainCameraIndex.value;
          final cameraCount = controller.cameraUrls.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Make main Camera',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Configure which camera should be set as the main camera for your system.',
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: cameraCount,
                  itemBuilder: (context, i) {
                    return RadioListTile<int>(
                      title: Text('Camera ${i + 1}'),
                      value: i,
                      groupValue: mainIndex,
                      onChanged: (value) {
                        if (value != null) {
                          controller.mainCameraIndex.value = value;
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        });

      case 1: // AI camera selection tab
        return Obx(() {
          final selectedAiIndexes = controller.aiCameraIndexes;
          final cameraCount = controller.cameraUrls.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select AI Cameras (max 4)',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Choose up to 4 cameras to be used in AI page.'),
              const SizedBox(height: 24),
              SizedBox(
                height: 300, // fixed height to allow ListView to render
                child: ListView.builder(
                  itemCount: cameraCount,
                  itemBuilder: (context, i) {
                    final isSelected = selectedAiIndexes.contains(i);
                    return CheckboxListTile(
                      title: Text('Camera ${i + 1}'),
                      value: isSelected,
                      onChanged: (bool? checked) {
                        if (checked == null) return;
                        final newSelection = List<int>.from(selectedAiIndexes);
                        if (checked) {
                          if (newSelection.length < 4) {
                            newSelection.add(i);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You can select up to 4 cameras only.',
                                ),
                              ),
                            );
                            return;
                          }
                        } else {
                          newSelection.remove(i);
                        }
                        controller.setAiCameraIndexes(newSelection);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        });

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

      case 5:
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

      default:
        return const SizedBox.shrink();
    }
  }
}
