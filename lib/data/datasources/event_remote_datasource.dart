import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';

abstract class EventRemoteDataSource {
  Future<List<EventModel>> getEvents({String? mode});
  Future<List<EventModel>> getEventsByCategory(String category);
  Future<EventModel> getEventById(String id);
  Future<EventModel> createEvent(Map<String, dynamic> eventData);
  Future<EventModel> updateEvent(String id, Map<String, dynamic> eventData);
  Future<void> deleteEvent(String id);
  Future<void> joinEvent(String eventId);
  Future<void> leaveEvent(String eventId);
  Future<List<EventModel>> getMyEvents();
  Future<List<EventModel>> getMyHostedEvents();
  Future<List<EventModel>> getJoinedEvents({int limit = 20, int offset = 0});
  Future<List<UserModel>> getEventAttendees(String eventId, {int limit = 20, int offset = 0});
  Future<List<EventModel>> getUserEventsByUsername(String username, {int limit = 20, int offset = 0});
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final DioClient dioClient;

  EventRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<EventModel>> getEvents({String? mode}) async {
    try {
      print('[EventRemoteDataSource] Fetching events with mode: $mode');
      final queryParams = mode != null ? {'mode': mode} : null;
      final response = await dioClient.get('/events', queryParameters: queryParams);
      print('[EventRemoteDataSource] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        print('[EventRemoteDataSource] ===== MODE: $mode =====');
        print('[EventRemoteDataSource] Received ${data.length} events');

        final events = <EventModel>[];
        for (int i = 0; i < data.length; i++) {
          try {
            final event = EventModel.fromJson(data[i]);
            events.add(event);
            // Log first 5 events to see ordering
            if (i < 5) {
              print('[EventRemoteDataSource] #${i + 1}: ${event.title} (${event.currentAttendees} attendees)');
            }
          } catch (e) {
            print('[EventRemoteDataSource] Error parsing event $i: $e');
            print('[EventRemoteDataSource] Event data: ${data[i]}');
            // Skip malformed events but continue parsing others
          }
        }

        print('[EventRemoteDataSource] Successfully parsed ${events.length} events');
        print('[EventRemoteDataSource] ===========================');
        return events;
      } else {
        throw ServerFailure('Failed to fetch events');
      }
    } on DioException catch (e) {
      print('[EventRemoteDataSource] DioException: ${e.response?.statusCode} - ${e.message}');
      print('[EventRemoteDataSource] Response data: ${e.response?.data}');
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      print('[EventRemoteDataSource] Unexpected error: $e');
      print('[EventRemoteDataSource] Stack trace: $stackTrace');
      throw ServerFailure('Unexpected error while fetching events: $e');
    }
  }

  @override
  Future<List<EventModel>> getEventsByCategory(String category) async {
    try {
      print('[EventRemoteDataSource] Fetching events by category: $category');
      final response = await dioClient.get(
        '/events',
        queryParameters: {'category': category},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        print('[EventRemoteDataSource] Received ${data.length} events for category $category');
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch events by category');
      }
    } on DioException catch (e) {
      print('[EventRemoteDataSource] DioException category: ${e.response?.statusCode} - ${e.message}');
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      print('[EventRemoteDataSource] Unexpected error in getEventsByCategory: $e');
      print('[EventRemoteDataSource] Stack trace: $stackTrace');
      throw ServerFailure('Unexpected error while fetching events by category: $e');
    }
  }

  @override
  Future<EventModel> getEventById(String id) async {
    try {
      final response = await dioClient.get('/events/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return EventModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to fetch event');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<EventModel> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await dioClient.post(
        '/events',
        data: eventData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return EventModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to create event');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<EventModel> updateEvent(String id, Map<String, dynamic> eventData) async {
    try {
      final response = await dioClient.put(
        '/events/$id',
        data: eventData,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return EventModel.fromJson(data);
      } else {
        throw ServerFailure('Failed to update event');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      final response = await dioClient.delete('/events/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to delete event');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> joinEvent(String eventId) async {
    try {
      final response = await dioClient.post('/events/$eventId/join');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure('Failed to join event');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> leaveEvent(String eventId) async {
    try {
      final response = await dioClient.delete('/events/$eventId/join');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to leave event');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<EventModel>> getMyEvents() async {
    try {
      final response = await dioClient.get('/events/my-events');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch my events');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<EventModel>> getMyHostedEvents() async {
    try {
      final response = await dioClient.get('/events/hosted');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch hosted events');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<EventModel>> getJoinedEvents({int limit = 20, int offset = 0}) async {
    try {
      final response = await dioClient.get(
        '/events/joined',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch joined events');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<UserModel>> getEventAttendees(String eventId, {int limit = 20, int offset = 0}) async {
    try {
      final response = await dioClient.get(
        '/events/$eventId/attendees',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch event attendees');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<List<EventModel>> getUserEventsByUsername(String username, {int limit = 20, int offset = 0}) async {
    try {
      final response = await dioClient.get(
        '/profile/$username/events',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch user events');
      }
    } on DioException catch (e) {
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
