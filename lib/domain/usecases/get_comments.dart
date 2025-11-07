import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/comment.dart';
import '../repositories/post_repository.dart';

class GetCommentsParams {
  final String postId;
  final int page;
  final int limit;

  GetCommentsParams({
    required this.postId,
    this.page = 1,
    this.limit = 20,
  });
}

class GetComments implements UseCase<List<Comment>, GetCommentsParams> {
  final PostRepository repository;

  GetComments(this.repository);

  @override
  Future<Either<Failure, List<Comment>>> call(GetCommentsParams params) async {
    return await repository.getComments(
      params.postId,
      page: params.page,
      limit: params.limit,
    );
  }
}
