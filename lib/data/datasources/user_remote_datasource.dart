import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getCurrentUser();
  Future<UserModel> getUserById(String userId);
  Future<UserModel> updateCurrentUser(Map<String, dynamic> userData);
  Future<void> updateUserSettings(Map<String, dynamic> settings);
  Future<List<UserModel>> searchUsers(String query, {int limit = 20, int offset = 0});
  Future<void> followUser(String userId);
  Future<void> unfollowUser(String userId);
  Future<List<UserModel>> getUserFollowers(String userId, {int limit = 20, int offset = 0});
  Future<List<UserModel>> getUserFollowing(String userId, {int limit = 20, int offset = 0});
  Future<Map<String, dynamic>> getUserStats(String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final DioClient dioClient;

  UserRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      print('[UserRemoteDataSource] Getting current user...');
      final response = await dioClient.get('/users/me');

      if (response.statusCode == 200) {
        // Backend returns: { data: { user: {...} } }
        final data = response.data['data']?['user'] ?? response.data['data'] ?? response.data;
        print('[UserRemoteDataSource] Current user retrieved successfully');
        print('[UserRemoteDataSource] Parsing user data: ${data.toString().substring(0, 100)}...');
        return UserModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to get current user');
      }
    } on DioException catch (e) {
      print('[UserRemoteDataSource] Error getting current user: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      print('[UserRemoteDataSource] Getting user by ID: $userId');
      final response = await dioClient.get('/users/$userId');

      if (response.statusCode == 200) {
        // Backend returns: { data: { user: {...} } }
        final data = response.data['data']?['user'] ?? response.data['data'] ?? response.data;
        print('[UserRemoteDataSource] User retrieved successfully');
        return UserModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to get user');
      }
    } on DioException catch (e) {
      print('[UserRemoteDataSource] Error getting user: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<UserModel> updateCurrentUser(Map<String, dynamic> userData) async {
    try {
      print('[UserRemoteDataSource] Updating current user with PATCH...');
      final response = await dioClient.patch(
        '/users/me',
        data: userData,
      );

      if (response.statusCode == 200) {
        // Backend returns: { data: { user: {...} } }
        final data = response.data['data']?['user'] ?? response.data['data'] ?? response.data;
        print('[UserRemoteDataSource] User updated successfully');
        return UserModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to update user');
      }
    } on DioException catch (e) {
      print('[UserRemoteDataSource] Error updating user: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      print('[UserRemoteDataSource] Updating user settings...');
      final response = await dioClient.put(
        '/users/me/settings',
        data: settings,
      );

      if (response.statusCode != 200) {
        throw ServerFailure('Failed to update user settings');
      }

      print('[UserRemoteDataSource] Settings updated successfully');
    } on DioException catch (e) {
      print('[UserRemoteDataSource] Error updating settings: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query, {int limit = 20, int offset = 0}) async {
    try {
      print('[UserRemoteDataSource] Searching users: $query');
      final response = await dioClient.get(
        '/users/search',
        queryParameters: {
          'q': query,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        print('[UserRemoteDataSource] Found ${data.length} users');
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to search users');
      }
    } on DioException catch (e) {
      print('[UserRemoteDataSource] Error searching users: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> followUser(String userId) async {
    try {
      print('[UserRemoteDataSource] Following user: $userId');
      final response = await dioClient.post('/users/$userId/follow');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure('Failed to follow user');
      }

      print('[UserRemoteDataSource] User followed successfully');
    } on DioException catch (e) {
      print('[UserRemoteDataSource] Error following user: ${e.response?.statusCode}');

      // If already following (409 Conflict), treat as success
      if (e.response?.statusCode == 409) {
        print('[UserRemoteDataSource] Already following - treating as success');
        return;
      }

      throw _handleDioException(e);
    }
  }

  @override
  Future<void> unfollowUser(String userId) async {
    try {
      print('[UserRemoteDataSource] Unfollowing user: $userId');
      final response = await dioClient.delete('/users/$userId/follow');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to unfollow user');
      }

      print('[UserRemoteDataSource] User unfollowed successfully');
    } on DioException catch (e) {
      print('[UserRemoteDataSource] Error unfollowing user: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<UserModel>> getUserFollowers(String userId, {int limit = 20, int offset = 0}) async {
    try {
      print('[UserRemoteDataSource] Getting followers for user: $userId');
      final response = await dioClient.get(
        '/users/$userId/followers',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        print('[UserRemoteDataSource] Found ${data.length} followers');
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to get followers');
      }
    } on DioException catch (e) {
      print('[UserRemoteDataSource] Error getting followers: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<UserModel>> getUserFollowing(String userId, {int limit = 20, int offset = 0}) async {
    try {
      print('[UserRemoteDataSource] Getting following for user: $userId');
      final response = await dioClient.get(
        '/users/$userId/following',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        print('[UserRemoteDataSource] Found ${data.length} following');
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to get following');
      }
    } on DioException catch (e) {
      print('[UserRemoteDataSource] Error getting following: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      print('[UserRemoteDataSource] Getting stats for user: $userId');
      final response = await dioClient.get('/users/$userId/stats');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        print('[UserRemoteDataSource] Stats retrieved successfully');
        return Map<String, dynamic>.from(data);
      } else {
        throw ServerFailure('Failed to get user stats');
      }
    } on DioException catch (e) {
      print('[UserRemoteDataSource] Error getting stats: ${e.response?.statusCode}');
      throw _handleDioException(e);
    }
  }

  Failure _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['message'] ?? 'Server error';
        if (statusCode == 401) {
          return AuthenticationFailure(message);
        } else if (statusCode == 403) {
          return AuthorizationFailure(message);
        } else if (statusCode == 404) {
          return NotFoundFailure(message);
        } else {
          return ServerFailure(message);
        }
      case DioExceptionType.cancel:
        return NetworkFailure('Request cancelled');
      case DioExceptionType.connectionError:
        return NetworkFailure('No internet connection');
      default:
        return ServerFailure('Unexpected error occurred');
    }
  }
}
