import '../../domain/entities/event_category.dart';

class EventCategoryUtils {
  static String getCategoryName(EventCategory category) {
    switch (category) {
      case EventCategory.meetup:
        return '#meetup';
      case EventCategory.sports:
        return '#sports';
      case EventCategory.workshop:
        return '#workshop';
      case EventCategory.networking:
        return '#networking';
      case EventCategory.food:
        return '#foodie';
      case EventCategory.creative:
        return '#creative';
      case EventCategory.outdoor:
        return '#outdoor';
      case EventCategory.fitness:
        return '#fitness';
      case EventCategory.learning:
        return '#learning';
      case EventCategory.social:
        return '#social';
    }
  }

  static String getCategoryDisplayName(EventCategory category) {
    switch (category) {
      case EventCategory.meetup:
        return 'Kumpul';
      case EventCategory.sports:
        return 'Olahraga';
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.networking:
        return 'Networking';
      case EventCategory.food:
        return 'Kuliner';
      case EventCategory.creative:
        return 'Kreatif';
      case EventCategory.outdoor:
        return 'Outdoor';
      case EventCategory.fitness:
        return 'Fitness';
      case EventCategory.learning:
        return 'Belajar';
      case EventCategory.social:
        return 'Sosial';
    }
  }

  static EventCategory? getCategoryFromString(String categoryString) {
    return EventCategory.values.firstWhere(
      (category) => getCategoryName(category).toLowerCase() == categoryString.toLowerCase(),
    );
  }
}