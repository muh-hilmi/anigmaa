import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_local_datasource.dart';
import '../datasources/event_remote_datasource.dart';
import '../models/event_model.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource remoteDataSource;
  final EventLocalDataSource localDataSource;

  EventRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, PaginatedResponse<Event>>> getEvents({int limit = 20, int offset = 0, String? mode}) async {
    try {
      // Fetch from remote only - no fallback
      final events = await remoteDataSource.getEvents(mode: mode);
      // Cache the events locally for future use
      await localDataSource.cacheEvents(events);

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: events, meta: meta));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get events: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Event>>> getEventsByCategory(EventCategory category, {int limit = 20, int offset = 0}) async {
    try {
      // Fetch from remote only - no fallback
      final categoryString = category.toString().split('.').last;
      final events = await remoteDataSource.getEventsByCategory(categoryString);
      // Cache the events locally
      await localDataSource.cacheEvents(events);

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: events, meta: meta));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get events by category: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Event>>> getNearbyEvents({int limit = 20, int offset = 0}) async {
    try {
      final events = await localDataSource.getEvents();
      // In real implementation, this would filter by location
      final nearbyEvents = events.take(limit).toList();

      // TODO: Use real backend endpoint GET /events/nearby with pagination
      // For now, create empty meta
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: nearbyEvents, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Failed to get nearby events: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Event>>> getStartingSoonEvents({int limit = 20, int offset = 0}) async {
    try {
      final events = await localDataSource.getEvents();
      final startingSoonEvents = events.where((event) => event.isStartingSoon).take(limit).toList();

      // TODO: Use real backend endpoint with pagination
      // For now, create empty meta
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: startingSoonEvents, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Failed to get starting soon events: $e'));
    }
  }

  @override
  Future<Either<Failure, Event>> getEventById(String id) async {
    try {
      // Fetch from remote only - no fallback
      final event = await remoteDataSource.getEventById(id);
      // Cache the event locally
      await localDataSource.cacheEvent(event);
      return Right(event);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get event by id: $e'));
    }
  }

  @override
  Future<Either<Failure, Event>> createEvent(Event event) async {
    try {
      final eventModel = EventModel.fromEntity(event);
      final eventData = eventModel.toJson();
      // Create on remote
      final createdEvent = await remoteDataSource.createEvent(eventData);
      // Cache locally
      await localDataSource.cacheEvent(createdEvent);
      return Right(createdEvent);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to create event: $e'));
    }
  }

  @override
  Future<Either<Failure, Event>> updateEvent(Event event) async {
    try {
      final eventModel = EventModel.fromEntity(event);
      final eventData = eventModel.toJson();
      // Update on remote
      final updatedEvent = await remoteDataSource.updateEvent(event.id, eventData);
      // Cache locally
      await localDataSource.cacheEvent(updatedEvent);
      return Right(updatedEvent);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to update event: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvent(String id) async {
    try {
      // Delete on remote
      await remoteDataSource.deleteEvent(id);
      // Delete from cache
      await localDataSource.deleteEvent(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to delete event: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> joinEvent(String eventId, String userId) async {
    try {
      // Join event on remote
      await remoteDataSource.joinEvent(eventId);
      // Update cache
      final event = await localDataSource.getEventById(eventId);
      if (event != null) {
        final updatedEvent = EventModel(
          id: event.id,
          title: event.title,
          description: event.description,
          category: event.category,
          startTime: event.startTime,
          endTime: event.endTime,
          location: event.location,
          host: event.host,
          imageUrls: event.imageUrls,
          maxAttendees: event.maxAttendees,
          attendeeIds: [...event.attendeeIds, userId],
          price: event.price,
          isFree: event.isFree,
          status: event.status,
          privacy: event.privacy,
          pendingRequests: event.pendingRequests,
          requirements: event.requirements,
        );
        await localDataSource.cacheEvent(updatedEvent);
      }
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to join event: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveEvent(String eventId, String userId) async {
    try {
      // Leave event on remote
      await remoteDataSource.leaveEvent(eventId);
      // Update cache
      final event = await localDataSource.getEventById(eventId);
      if (event != null) {
        final updatedAttendees = event.attendeeIds.where((id) => id != userId).toList();
        final updatedEvent = EventModel(
          id: event.id,
          title: event.title,
          description: event.description,
          category: event.category,
          startTime: event.startTime,
          endTime: event.endTime,
          location: event.location,
          host: event.host,
          imageUrls: event.imageUrls,
          maxAttendees: event.maxAttendees,
          attendeeIds: updatedAttendees,
          price: event.price,
          isFree: event.isFree,
          status: event.status,
          privacy: event.privacy,
          pendingRequests: event.pendingRequests,
          requirements: event.requirements,
        );
        await localDataSource.cacheEvent(updatedEvent);
      }
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to leave event: $e'));
    }
  }
}