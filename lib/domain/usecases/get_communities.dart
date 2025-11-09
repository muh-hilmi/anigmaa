import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/community.dart';
import '../repositories/community_repository.dart';

class GetCommunities implements UseCase<List<Community>, NoParams> {
  final CommunityRepository repository;

  GetCommunities(this.repository);

  @override
  Future<Either<Failure, List<Community>>> call(NoParams params) async {
    return await repository.getCommunities();
  }
}
