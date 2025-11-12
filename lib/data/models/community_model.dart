import '../../domain/entities/community.dart';
import '../../domain/entities/community_category.dart';

class CommunityModel extends Community {
  const CommunityModel({
    required super.id,
    required super.name,
    required super.description,
    super.coverImage,
    super.icon,
    required super.category,
    required super.location,
    required super.memberCount,
    super.memberIds,
    super.adminIds,
    required super.createdAt,
    super.isPublic,
    super.isVerified,
    super.settings,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    // Parse category from API response
    final categoryStr = json['category']?.toString().toLowerCase() ?? 'general';
    final category = _parseCategoryFromString(categoryStr);

    // Parse privacy to isPublic boolean
    final privacy = json['privacy']?.toString().toLowerCase() ?? 'public';
    final isPublic = privacy == 'public';

    return CommunityModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      coverImage: json['cover_url'] ?? json['cover_image'],
      icon: json['avatar_url'] ?? json['icon'],
      category: category,
      location: json['location'] ?? 'Unknown',
      memberCount: json['members_count'] ?? json['member_count'] ?? 0,
      memberIds: (json['member_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      adminIds: (json['admin_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      isPublic: isPublic,
      isVerified: json['is_verified'] ?? false,
      settings: json['settings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cover_url': coverImage,
      'avatar_url': icon,
      'category': _categoryToString(category),
      'location': location,
      'members_count': memberCount,
      'member_ids': memberIds,
      'admin_ids': adminIds,
      'created_at': createdAt.toIso8601String(),
      'privacy': isPublic ? 'public' : 'private',
      'is_verified': isVerified,
      'settings': settings,
    };
  }

  static CommunityCategory _parseCategoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'coffee':
        return CommunityCategory.coffee;
      case 'food':
        return CommunityCategory.food;
      case 'sports':
        return CommunityCategory.sports;
      case 'music':
        return CommunityCategory.music;
      case 'gaming':
        return CommunityCategory.gaming;
      case 'technology':
      case 'tech':
        return CommunityCategory.technology;
      case 'art':
        return CommunityCategory.art;
      case 'books':
        return CommunityCategory.books;
      case 'fitness':
        return CommunityCategory.fitness;
      case 'travel':
        return CommunityCategory.travel;
      case 'general':
      default:
        return CommunityCategory.general;
    }
  }

  static String _categoryToString(CommunityCategory category) {
    switch (category) {
      case CommunityCategory.coffee:
        return 'coffee';
      case CommunityCategory.food:
        return 'food';
      case CommunityCategory.sports:
        return 'sports';
      case CommunityCategory.music:
        return 'music';
      case CommunityCategory.gaming:
        return 'gaming';
      case CommunityCategory.technology:
        return 'technology';
      case CommunityCategory.art:
        return 'art';
      case CommunityCategory.books:
        return 'books';
      case CommunityCategory.fitness:
        return 'fitness';
      case CommunityCategory.travel:
        return 'travel';
      case CommunityCategory.general:
      default:
        return 'general';
    }
  }

  Community toEntity() {
    return Community(
      id: id,
      name: name,
      description: description,
      coverImage: coverImage,
      icon: icon,
      category: category,
      location: location,
      memberCount: memberCount,
      memberIds: memberIds,
      adminIds: adminIds,
      createdAt: createdAt,
      isPublic: isPublic,
      isVerified: isVerified,
      settings: settings,
    );
  }
}
