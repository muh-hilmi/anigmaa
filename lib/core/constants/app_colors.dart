import 'package:flutter/material.dart';
import '../../domain/entities/event_category.dart';

class AppColors {
  // Primary Colors - Orange Theme
  static const Color primary = Color(0xFFF97316);
  static const Color primaryLight = Color(0xFFFB923C);
  static const Color primaryDark = Color(0xFFEA580C);

  // Secondary Colors - Deep Blue
  static const Color secondary = Color(0xFF1E40AF);
  static const Color secondaryLight = Color(0xFF3B82F6);
  static const Color secondaryDark = Color(0xFF1E3A8A);

  // Background Colors - Warm Tones
  static const Color background = Color(0xFFFAFAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFFF7ED);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFFF97316);

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