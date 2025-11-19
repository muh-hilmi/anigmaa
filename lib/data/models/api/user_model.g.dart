// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      // username: json['username'] as String?,
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverImage: json['cover_image'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      location: json['location'] as String?,
      isVerified: json['is_verified'] as bool?,
      isEmailVerified: json['is_email_verified'] as bool?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      // 'username': instance.username,
      'name': instance.name,
      'bio': instance.bio,
      'avatar_url': instance.avatarUrl,
      'cover_image': instance.coverImage,
      'phone': instance.phone,
      'date_of_birth': instance.dateOfBirth,
      'gender': instance.gender,
      'location': instance.location,
      'is_verified': instance.isVerified,
      'is_email_verified': instance.isEmailVerified,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

UserStatsModel _$UserStatsModelFromJson(Map<String, dynamic> json) =>
    UserStatsModel(
      followersCount: (json['followers_count'] as num).toInt(),
      followingCount: (json['following_count'] as num).toInt(),
      postsCount: (json['posts_count'] as num).toInt(),
      eventsCreated: (json['events_created'] as num).toInt(),
      eventsAttended: (json['events_attended'] as num).toInt(),
    );

Map<String, dynamic> _$UserStatsModelToJson(UserStatsModel instance) =>
    <String, dynamic>{
      'followers_count': instance.followersCount,
      'following_count': instance.followingCount,
      'posts_count': instance.postsCount,
      'events_created': instance.eventsCreated,
      'events_attended': instance.eventsAttended,
    };

// UpdateProfileRequest _$UpdateProfileRequestFromJson(
//         Map<String, dynamic> json) =>
//     UpdateProfileRequest(
//       fullName: json['full_name'] as String?,
//       bio: json['bio'] as String?,
//       profileImage: json['profile_image'] as String?,
//       coverImage: json['cover_image'] as String?,
//       dateOfBirth: json['date_of_birth'] as String?,
//       gender: json['gender'] as String?,
//       location: json['location'] as String?,
//     );

Map<String, dynamic> _$UpdateProfileRequestToJson(
        UpdateProfileRequest instance) =>
    <String, dynamic>{
      'full_name': instance.fullName,
      'bio': instance.bio,
      'profile_image': instance.profileImage,
      'cover_image': instance.coverImage,
      'date_of_birth': instance.dateOfBirth,
      'gender': instance.gender,
      'location': instance.location,
    };

// UpdateSettingsRequest _$UpdateSettingsRequestFromJson(
//         Map<String, dynamic> json) =>
//     UpdateSettingsRequest(
//       notificationEnabled: json['notification_enabled'] as bool?,
//       emailNotification: json['email_notification'] as bool?,
//       pushNotification: json['push_notification'] as bool?,
//       language: json['language'] as String?,
//       theme: json['theme'] as String?,
//     );

Map<String, dynamic> _$UpdateSettingsRequestToJson(
        UpdateSettingsRequest instance) =>
    <String, dynamic>{
      'notification_enabled': instance.notificationEnabled,
      'email_notification': instance.emailNotification,
      'push_notification': instance.pushNotification,
      'language': instance.language,
      'theme': instance.theme,
    };
