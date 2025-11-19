import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/ranked_feed_model.dart';

abstract class RankingRemoteDataSource {
  Future<RankedFeedModel> getRankedFeed(RankingRequestModel request);
}

class RankingRemoteDataSourceImpl implements RankingRemoteDataSource {
  final DioClient dioClient;

  RankingRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<RankedFeedModel> getRankedFeed(RankingRequestModel request) async {
    try {
      print('[RankingRemoteDataSource] Sending ranking request...');
      print('[RankingRemoteDataSource] User ID: ${request.userProfile.id}');
      print('[RankingRemoteDataSource] Posts count: ${request.posts.length}');
      print('[RankingRemoteDataSource] Events count: ${request.events.length}');

      final response = await dioClient.post(
        '/feed/rank',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        print('[RankingRemoteDataSource] Successfully received ranked feed');
        final data = response.data;

        // Log the ranked feed summary
        print('[RankingRemoteDataSource] Trending events: ${(data['trending_event'] as List?)?.length ?? 0}');
        print('[RankingRemoteDataSource] For you posts: ${(data['for_you_posts'] as List?)?.length ?? 0}');
        print('[RankingRemoteDataSource] For you events: ${(data['for_you_events'] as List?)?.length ?? 0}');

        return RankedFeedModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to rank feed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      print('[RankingRemoteDataSource] Unexpected error: $e');
      throw ServerFailure('Failed to rank feed: $e');
    }
  }

  Failure _handleDioException(DioException e) {
    print('[RankingRemoteDataSource] DioException: ${e.type}');
    print('[RankingRemoteDataSource] Error message: ${e.message}');
    print('[RankingRemoteDataSource] Response: ${e.response?.data}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? e.response?.data?['error'] ?? 'Unknown error';
        if (statusCode == 401) {
          return AuthFailure('Unauthorized');
        } else if (statusCode == 404) {
          return NotFoundFailure('Ranking endpoint not found');
        } else if (statusCode == 400) {
          return ValidationFailure(message);
        }
        return ServerFailure('Server error: $message');
      case DioExceptionType.cancel:
        return NetworkFailure('Request cancelled');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return NetworkFailure('Network error: ${e.message}');
      default:
        return ServerFailure('Unknown error: ${e.message}');
    }
  }
}
