import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class GetPosts implements UseCase<List<Post>, GetPostsParams> {
  final PostRepository repository;

  GetPosts(this.repository);

  @override
  Future<Either<Failure, List<Post>>> call(GetPostsParams params) async {
    return await repository.getPosts(
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetPostsParams {
  final int limit;
  final int offset;

  const GetPostsParams({
    this.limit = 20,
    this.offset = 0,
  });
}

class GetFeedPosts implements UseCase<List<Post>, GetFeedPostsParams> {
  final PostRepository repository;

  GetFeedPosts(this.repository);

  @override
  Future<Either<Failure, List<Post>>> call(GetFeedPostsParams params) async {
    return await repository.getFeedPosts(
      limit: params.limit,
      cursor: params.cursor,
    );
  }
}

class GetFeedPostsParams {
  final int limit;
  final String? cursor;

  const GetFeedPostsParams({
    this.limit = 20,
    this.cursor,
  });
}
