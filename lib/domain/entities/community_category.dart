enum CommunityCategory {
  tech,
  sports,
  food,
  creative,
  professional,
  gaming,
  health,
  travel,
  music,
  education,
  lifestyle,
  other,
}

extension CommunityCategoryExtension on CommunityCategory {
  String get displayName {
    switch (this) {
      case CommunityCategory.tech:
        return 'Tech';
      case CommunityCategory.sports:
        return 'Olahraga';
      case CommunityCategory.food:
        return 'Kuliner';
      case CommunityCategory.creative:
        return 'Kreatif';
      case CommunityCategory.professional:
        return 'Profesional';
      case CommunityCategory.gaming:
        return 'Gaming';
      case CommunityCategory.health:
        return 'Kesehatan';
      case CommunityCategory.travel:
        return 'Travel';
      case CommunityCategory.music:
        return 'Musik';
      case CommunityCategory.education:
        return 'Edukasi';
      case CommunityCategory.lifestyle:
        return 'Lifestyle';
      case CommunityCategory.other:
        return 'Lainnya';
    }
  }

  String get emoji {
    switch (this) {
      case CommunityCategory.tech:
        return '💻';
      case CommunityCategory.sports:
        return '⚽';
      case CommunityCategory.food:
        return '🍔';
      case CommunityCategory.creative:
        return '🎨';
      case CommunityCategory.professional:
        return '💼';
      case CommunityCategory.gaming:
        return '🎮';
      case CommunityCategory.health:
        return '🏃';
      case CommunityCategory.travel:
        return '✈️';
      case CommunityCategory.music:
        return '🎵';
      case CommunityCategory.education:
        return '📚';
      case CommunityCategory.lifestyle:
        return '🌟';
      case CommunityCategory.other:
        return '📌';
    }
  }
}
