import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/ranked_feed.dart';
import '../../domain/repositories/ranking_repository.dart';
import '../datasources/ranking_remote_datasource.dart';
import '../models/ranked_feed_model.dart';

class RankingRepositoryImpl implements RankingRepository {
  final RankingRemoteDataSource remoteDataSource;

  RankingRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, RankedFeed>> getRankedFeed(RankingRequest request) async {
    try {
      print('[RankingRepository] Getting ranked feed...');

      // Convert entity to model
      final requestModel = RankingRequestModel.fromEntity(request);

      // Fetch from remote
      final rankedFeed = await remoteDataSource.getRankedFeed(requestModel);

      print('[RankingRepository] Successfully ranked feed');
      return Right(rankedFeed);
    } on Failure catch (e) {
      print('[RankingRepository] Failure ranking feed: $e');
      return Left(e);
    } catch (e, stackTrace) {
      print('[RankingRepository] Exception ranking feed: $e');
      print('[RankingRepository] Stack trace: $stackTrace');
      return Left(ServerFailure('Failed to rank feed: $e'));
    }
  }
}
