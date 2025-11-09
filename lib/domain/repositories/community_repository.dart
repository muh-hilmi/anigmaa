import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/community.dart';
import '../entities/community_category.dart';

abstract class CommunityRepository {
  Future<Either<Failure, List<Community>>> getCommunities();
  Future<Either<Failure, List<Community>>> getCommunitiesByLocation(String location);
  Future<Either<Failure, List<Community>>> getCommunitiesByCategory(CommunityCategory category);
  Future<Either<Failure, List<Community>>> getJoinedCommunities(String userId);
  Future<Either<Failure, Community>> getCommunityById(String id);
  Future<Either<Failure, Community>> createCommunity(Community community);
  Future<Either<Failure, Community>> updateCommunity(Community community);
  Future<Either<Failure, void>> deleteCommunity(String id);
  Future<Either<Failure, void>> joinCommunity(String communityId, String userId);
  Future<Either<Failure, void>> leaveCommunity(String communityId, String userId);
}
