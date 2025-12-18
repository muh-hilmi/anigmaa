import 'package:flutter/material.dart';

class ModeSwitcher extends StatelessWidget {
  final String selectedMode;
  final Function(String) onModeChanged;

  const ModeSwitcher({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildModeChip(
            mode: 'trending',
            label: 'Trending',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF3B30),
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'for_you',
            label: 'For You',
            icon: Icons.auto_awesome_rounded,
            color: Colors.purple,
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'chill',
            label: 'Chill',
            icon: Icons.nightlight_round,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'nearby',
            label: 'Terdekat',
            icon: Icons.near_me_rounded,
            color: const Color(0xFFBBC863),
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'today',
            label: 'Hari Ini',
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFFFF9500),
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'free',
            label: 'Gratis',
            icon: Icons.money_off_rounded,
            color: const Color(0xFF34C759),
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'paid',
            label: 'Berbayar',
            icon: Icons.attach_money_rounded,
            color: const Color(0xFFBBC863),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String mode,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : const Color(0xFFFCFCFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.black,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.black,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
