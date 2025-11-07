import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    super.email,
    required super.name,
    super.bio,
    super.avatar,
    required super.createdAt,
    super.lastLoginAt,
    super.interests = const [],
    required super.settings,
    required super.stats,
    super.isVerified = false,
    super.isEmailVerified = false,
    required super.privacy,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and snake_case from backend
    final avatarUrl = json['avatar'] ?? json['avatar_url'];
    final createdAt = json['createdAt'] ?? json['created_at'];
    final lastLoginAt = json['lastLoginAt'] ?? json['last_login_at'];
    final isVerified = json['isVerified'] ?? json['is_verified'];
    final isEmailVerified = json['isEmailVerified'] ?? json['is_email_verified'];

    // Validate required fields
    if (json['id'] == null || (json['id'] as String).isEmpty) {
      throw Exception('Missing user id in response');
    }
    if (json['name'] == null || (json['name'] as String).isEmpty) {
      throw Exception('Missing user name in response');
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      avatar: avatarUrl as String?,
      createdAt: createdAt != null
          ? DateTime.parse(createdAt as String)
          : DateTime.now(),
      lastLoginAt: lastLoginAt != null
          ? DateTime.parse(lastLoginAt as String)
          : null,
      interests: List<String>.from(json['interests'] ?? []),
      settings: UserSettingsModel.fromJson(json['settings'] ?? {}),
      stats: UserStatsModel.fromJson(json['stats'] ?? {}),
      isVerified: isVerified as bool? ?? false,
      isEmailVerified: isEmailVerified as bool? ?? false,
      privacy: UserPrivacyModel.fromJson(json['privacy'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'bio': bio,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'interests': interests,
      'settings': (settings as UserSettingsModel).toJson(),
      'stats': (stats as UserStatsModel).toJson(),
      'isVerified': isVerified,
      'isEmailVerified': isEmailVerified,
      'privacy': (privacy as UserPrivacyModel).toJson(),
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      bio: user.bio,
      avatar: user.avatar,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      interests: user.interests,
      settings: user.settings,
      stats: user.stats,
      isVerified: user.isVerified,
      isEmailVerified: user.isEmailVerified,
      privacy: user.privacy,
    );
  }
}

class UserSettingsModel extends UserSettings {
  const UserSettingsModel({
    super.pushNotifications = true,
    super.emailNotifications = true,
    super.darkMode = false,
    super.language = 'en',
    super.locationEnabled = true,
    super.showOnlineStatus = true,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
      locationEnabled: json['locationEnabled'] as bool? ?? true,
      showOnlineStatus: json['showOnlineStatus'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'darkMode': darkMode,
      'language': language,
      'locationEnabled': locationEnabled,
      'showOnlineStatus': showOnlineStatus,
    };
  }
}

class UserStatsModel extends UserStats {
  const UserStatsModel({
    super.eventsAttended = 0,
    super.eventsCreated = 0,
    super.followersCount = 0,
    super.followingCount = 0,
    super.reviewsGiven = 0,
    super.averageRating = 0.0,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      eventsAttended: json['eventsAttended'] as int? ?? 0,
      eventsCreated: json['eventsCreated'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      reviewsGiven: json['reviewsGiven'] as int? ?? 0,
      averageRating: json['averageRating']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventsAttended': eventsAttended,
      'eventsCreated': eventsCreated,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'reviewsGiven': reviewsGiven,
      'averageRating': averageRating,
    };
  }
}

class UserPrivacyModel extends UserPrivacy {
  const UserPrivacyModel({
    super.profileVisible = true,
    super.eventsVisible = true,
    super.allowFollowers = true,
    super.showEmail = false,
    super.showLocation = true,
  });

  factory UserPrivacyModel.fromJson(Map<String, dynamic> json) {
    return UserPrivacyModel(
      profileVisible: json['profileVisible'] as bool? ?? true,
      eventsVisible: json['eventsVisible'] as bool? ?? true,
      allowFollowers: json['allowFollowers'] as bool? ?? true,
      showEmail: json['showEmail'] as bool? ?? false,
      showLocation: json['showLocation'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileVisible': profileVisible,
      'eventsVisible': eventsVisible,
      'allowFollowers': allowFollowers,
      'showEmail': showEmail,
      'showLocation': showLocation,
    };
  }
}
