import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/event.dart';
import '../entities/event_category.dart';

abstract class EventRepository {
  Future<Either<Failure, List<Event>>> getEvents();
  Future<Either<Failure, List<Event>>> getEventsByCategory(EventCategory category);
  Future<Either<Failure, List<Event>>> getNearbyEvents();
  Future<Either<Failure, List<Event>>> getStartingSoonEvents();
  Future<Either<Failure, Event>> getEventById(String id);
  Future<Either<Failure, Event>> createEvent(Event event);
  Future<Either<Failure, Event>> updateEvent(Event event);
  Future<Either<Failure, void>> deleteEvent(String id);
  Future<Either<Failure, void>> joinEvent(String eventId, String userId);
  Future<Either<Failure, void>> leaveEvent(String eventId, String userId);
}