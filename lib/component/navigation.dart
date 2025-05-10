import 'package:flutter/material.dart';

class CustomNavigationBar extends StatefulWidget {
  final Function(int) onTabSelected;
  final int initialIndex;

  const CustomNavigationBar({
    super.key,
    required this.onTabSelected,
    this.initialIndex = 0,
  });

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _handleTabSelection(int index) {
    setState(() => _selectedIndex = index);
    widget.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset('assets/logo/logo1.png', height: 30, width: 112),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavButton(
                    text: 'Basic',
                    isSelected: _selectedIndex == 0,
                    onTap: () => _handleTabSelection(0),
                  ),
                  const SizedBox(width: 32),
                  _NavButton(
                    text: 'AI',
                    isSelected: _selectedIndex == 1,
                    onTap: () => _handleTabSelection(1),
                  ),
                  const SizedBox(width: 32),
                  _NavButton(
                    text: 'Settings',
                    isSelected: _selectedIndex == 2,
                    onTap: () => _handleTabSelection(2),
                  ),
                ],
              ),
            ),
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
