import 'package:flutter/material.dart';
import '../../domain/entities/event_category.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF000000);
  static const Color primaryLight = Color(0xFF333333);
  static const Color primaryDark = Color(0xFF000000);

  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF84994F);

  // Border Colors
  static const Color border = Color(0xFFE5E5E5);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Category Colors
  static const Map<EventCategory, Color> categoryColors = {
    EventCategory.meetup: Color(0xFF6366F1),
    EventCategory.sports: Color(0xFF10B981),
    EventCategory.workshop: Color(0xFFF59E0B),
    EventCategory.networking: Color(0xFF8B5CF6),
    EventCategory.food: Color(0xFFEF4444),
    EventCategory.creative: Color(0xFFEC4899),
    EventCategory.outdoor: Color(0xFF06B6D4),
    EventCategory.fitness: Color(0xFF84CC16),
    EventCategory.learning: Color(0xFF3B82F6),
    EventCategory.social: Color(0xFFF97316),
  };

  static Color getCategoryColor(EventCategory category) {
    return categoryColors[category] ?? primary;
  }
}