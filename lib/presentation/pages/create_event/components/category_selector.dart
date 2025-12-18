import 'package:anigmaa/core/utils/event_category_utils.dart';
import 'package:anigmaa/domain/entities/event_category.dart';
import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final Function(EventCategory) onCategorySelected;

  const CategorySelector({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: EventCategory.values.map((category) {
        return GestureDetector(
          onTap: () => onCategorySelected(category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFBBC863),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              EventCategoryUtils.getCategoryDisplayName(category),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
