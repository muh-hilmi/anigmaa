import 'package:json_annotation/json_annotation.dart';
import '../../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String? email;
  final String? username;
  // Backend uses 'name' field
  final String? name;
  final String? bio;
  // Backend uses 'avatar_url' field
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  final String? phone;
  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;
  final String? gender;
  final String? location;
  @JsonKey(name: 'is_verified')
  final bool? isVerified;
  @JsonKey(name: 'is_email_verified')
  final bool? isEmailVerified;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  UserModel({
    required this.id,
    this.email,
    this.username,
    this.name,
    this.bio,
    this.avatarUrl,
    this.coverImage,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.location,
    this.isVerified,
    this.isEmailVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  // Convert to domain entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name ?? username ?? 'User',
      bio: bio,
      avatar: avatarUrl,
      createdAt: createdAt != null
          ? DateTime.parse(createdAt!)
          : DateTime.now(),
      lastLoginAt: null,
      interests: [],
      settings: const UserSettings(),
      stats: const UserStats(),
      isVerified: isVerified ?? false,
      isEmailVerified: isEmailVerified ?? false,
      privacy: const UserPrivacy(),
    );
  }

  // Create from domain entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      username: user.name,
      bio: user.bio,
      avatarUrl: user.avatar,
      isVerified: user.isVerified,
      isEmailVerified: user.isEmailVerified,
      createdAt: user.createdAt.toIso8601String(),
    );
  }
}

@JsonSerializable()
class UserStatsModel {
  @JsonKey(name: 'followers_count')
  final int followersCount;
  @JsonKey(name: 'following_count')
  final int followingCount;
  @JsonKey(name: 'posts_count')
  final int postsCount;
  @JsonKey(name: 'events_created')
  final int eventsCreated;
  @JsonKey(name: 'events_attended')
  final int eventsAttended;

  UserStatsModel({
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.eventsCreated,
    required this.eventsAttended,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) =>
      _$UserStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserStatsModelToJson(this);

  UserStats toEntity() {
    return UserStats(
      followersCount: followersCount,
      followingCount: followingCount,
      eventsCreated: eventsCreated,
      eventsAttended: eventsAttended,
    );
  }
}

@JsonSerializable()
class UpdateProfileRequest {
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String? bio;
  @JsonKey(name: 'profile_image')
  final String? profileImage;
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth;
  final String? gender;
  final String? location;

  UpdateProfileRequest({
    this.fullName,
    this.bio,
    this.profileImage,
    this.coverImage,
    this.dateOfBirth,
    this.gender,
    this.location,
  });

  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);
}

@JsonSerializable()
class UpdateSettingsRequest {
  @JsonKey(name: 'notification_enabled')
  final bool? notificationEnabled;
  @JsonKey(name: 'email_notification')
  final bool? emailNotification;
  @JsonKey(name: 'push_notification')
  final bool? pushNotification;
  final String? language;
  final String? theme;

  UpdateSettingsRequest({
    this.notificationEnabled,
    this.emailNotification,
    this.pushNotification,
    this.language,
    this.theme,
  });

  Map<String, dynamic> toJson() => _$UpdateSettingsRequestToJson(this);
}
