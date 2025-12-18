import 'package:flutter/material.dart';

class PriceSelector extends StatelessWidget {
  final Function(bool isFree) onOptionSelected;

  const PriceSelector({super.key, required this.onOptionSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPriceOption('Gratis 🎁', true),
        const SizedBox(height: 8),
        _buildPriceOption('Berbayar 💰', false),
      ],
    );
  }

  Widget _buildPriceOption(String label, bool isFree) {
    return GestureDetector(
      onTap: () => onOptionSelected(isFree),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFBBC863),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
