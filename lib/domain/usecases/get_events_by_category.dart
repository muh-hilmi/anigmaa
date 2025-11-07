import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/event.dart';
import '../entities/event_category.dart';
import '../repositories/event_repository.dart';

class GetEventsByCategory implements UseCase<List<Event>, GetEventsByCategoryParams> {
  final EventRepository repository;

  GetEventsByCategory(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(GetEventsByCategoryParams params) async {
    return await repository.getEventsByCategory(params.category);
  }
}

class GetEventsByCategoryParams {
  final EventCategory category;

  GetEventsByCategoryParams({required this.category});
}