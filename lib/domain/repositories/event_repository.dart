import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../entities/event.dart';
import '../entities/event_category.dart';

abstract class EventRepository {
  Future<Either<Failure, PaginatedResponse<Event>>> getEvents({int limit = 20, int offset = 0});
  Future<Either<Failure, PaginatedResponse<Event>>> getEventsByCategory(EventCategory category, {int limit = 20, int offset = 0});
  Future<Either<Failure, PaginatedResponse<Event>>> getNearbyEvents({int limit = 20, int offset = 0});
  Future<Either<Failure, PaginatedResponse<Event>>> getStartingSoonEvents({int limit = 20, int offset = 0});
  Future<Either<Failure, Event>> getEventById(String id);
  Future<Either<Failure, Event>> createEvent(Event event);
  Future<Either<Failure, Event>> updateEvent(Event event);
  Future<Either<Failure, void>> deleteEvent(String id);
  Future<Either<Failure, void>> joinEvent(String eventId, String userId);
  Future<Either<Failure, void>> leaveEvent(String eventId, String userId);
}