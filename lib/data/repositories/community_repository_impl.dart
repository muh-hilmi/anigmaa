import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/community.dart';
import '../../domain/entities/community_category.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_local_datasource.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityLocalDataSource localDataSource;

  CommunityRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Community>>> getCommunities() async {
    try {
      final communities = await localDataSource.getCommunities();
      await localDataSource.cacheCommunities(communities);
      return Right(communities);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to get communities: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getCommunitiesByLocation(String location) async {
    try {
      final communities = await localDataSource.getCommunitiesByLocation(location);
      return Right(communities);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to get communities by location: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getCommunitiesByCategory(CommunityCategory category) async {
    try {
      final communities = await localDataSource.getCommunitiesByCategory(category);
      return Right(communities);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to get communities by category: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Community>>> getJoinedCommunities(String userId) async {
    try {
      final communities = await localDataSource.getJoinedCommunities(userId);
      return Right(communities);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to get joined communities: $e'));
    }
  }

  @override
  Future<Either<Failure, Community>> getCommunityById(String id) async {
    try {
      final community = await localDataSource.getCommunityById(id);
      if (community == null) {
        return Left(CacheFailure('Community not found'));
      }
      return Right(community);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to get community: $e'));
    }
  }

  @override
  Future<Either<Failure, Community>> createCommunity(Community community) async {
    try {
      await localDataSource.cacheCommunity(community);
      return Right(community);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to create community: $e'));
    }
  }

  @override
  Future<Either<Failure, Community>> updateCommunity(Community community) async {
    try {
      await localDataSource.cacheCommunity(community);
      return Right(community);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to update community: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCommunity(String id) async {
    try {
      await localDataSource.deleteCommunity(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to delete community: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> joinCommunity(String communityId, String userId) async {
    try {
      // Mock implementation - in real app, this would call API
      // For now, just return success
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to join community: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveCommunity(String communityId, String userId) async {
    try {
      // Mock implementation - in real app, this would call API
      // For now, just return success
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to leave community: $e'));
    }
  }
}
