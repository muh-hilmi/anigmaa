import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/event_model.dart';

abstract class EventRemoteDataSource {
  Future<List<EventModel>> getEvents();
  Future<List<EventModel>> getEventsByCategory(String category);
  Future<EventModel> getEventById(String id);
  Future<EventModel> createEvent(Map<String, dynamic> eventData);
  Future<EventModel> updateEvent(String id, Map<String, dynamic> eventData);
  Future<void> deleteEvent(String id);
  Future<void> joinEvent(String eventId);
  Future<void> leaveEvent(String eventId);
  Future<List<EventModel>> getMyEvents();
  Future<List<EventModel>> getMyHostedEvents();
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final DioClient dioClient;

  EventRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<EventModel>> getEvents() async {
    try {
      print('[EventRemoteDataSource] Fetching events...');
      final response = await dioClient.get('/events');
      print('[EventRemoteDataSource] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        print('[EventRemoteDataSource] Received ${data.length} events');

        if (data.isNotEmpty) {
          print('[EventRemoteDataSource] Sample event data: ${data[0]}');
        }

        final events = <EventModel>[];
        for (int i = 0; i < data.length; i++) {
          try {
            final event = EventModel.fromJson(data[i]);
            events.add(event);
          } catch (e) {
            print('[EventRemoteDataSource] Error parsing event $i: $e');
            print('[EventRemoteDataSource] Event data: ${data[i]}');
          }
        }

        print('[EventRemoteDataSource] Successfully parsed ${events.length} events');
        return events;
      } else {
        throw ServerFailure('Failed to fetch events');
      }
    } on DioException catch (e) {
      print('[EventRemoteDataSource] Error fetching events: ${e.response?.statusCode} - ${e.response?.data}');

      // If backend has database issues (500), return empty list instead of crashing
      if (e.response?.statusCode == 500) {
        print('[EventRemoteDataSource] Backend error (500) - returning empty list');
        return [];
      }

      throw _handleDioException(e);
    } catch (e) {
      print('[EventRemoteDataSource] Unexpected error: $e');
      return [];
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
      print('[EventRemoteDataSource] Error fetching events by category: ${e.response?.statusCode}');

      // If backend has database issues (500), return empty list instead of crashing
      if (e.response?.statusCode == 500) {
        print('[EventRemoteDataSource] Backend error (500) - returning empty list');
        return [];
      }

      throw _handleDioException(e);
    } catch (e) {
      print('[EventRemoteDataSource] Unexpected error: $e');
      return [];
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
