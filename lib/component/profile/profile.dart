import 'package:flutter/material.dart';

class ProfileSliderController {
  VoidCallback? _toggleCallback;

  void toggle() {
    _toggleCallback?.call();
  }

  void registerToggleCallback(VoidCallback callback) {
    _toggleCallback = callback;
  }

  bool get isAttached => _toggleCallback != null;
}

class ProfileSlider extends StatefulWidget {
  final String userName;
  final String userId;
  final VoidCallback onLogout;
  final ProfileSliderController controller;

  const ProfileSlider({
    Key? key,
    required this.userName,
    required this.userId,
    required this.onLogout,
    required this.controller,
  }) : super(key: key);

  @override
  State<ProfileSlider> createState() => ProfileSliderState();
}

class ProfileSliderState extends State<ProfileSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    widget.controller.registerToggleCallback(toggleSlider);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggleSlider() {
    setState(() {
      isOpen = !isOpen;
      isOpen ? _animationController.forward() : _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isOpen,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Semi-transparent background overlay
              if (isOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: toggleSlider,
                    child: Container(
                      color: Colors.black.withOpacity(
                        0.3 * _animationController.value,
                      ),
                    ),
                  ),
                ),

              // Slider content
              Positioned(
                top: kToolbarHeight,
                right: -250 * (1 - _animationController.value),
                bottom: 0,
                child: Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 10,
                        offset: const Offset(-3, 0),
                      ),
                    ],
                  ),
                  child: _buildSliderContent(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliderContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/images/profile.png'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID: ${widget.userId}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white54, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text(
              "Logout",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: widget.onLogout,
          ),
          const Divider(color: Colors.white54, height: 1),
        ],
      ),
    );
  }
}
