import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/models/pagination.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_datasource.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;

  PostRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, PaginatedResponse<Post>>> getPosts({int limit = 20, int offset = 0}) async {
    try {
      print('[PostRepository] Fetching posts from remote (limit: $limit, offset: $offset)...');
      // Fetch from remote only - no fallback
      final posts = await remoteDataSource.getPosts(limit: limit, offset: offset);
      print('[PostRepository] Successfully fetched ${posts.length} posts');

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: posts, meta: meta));
    } on Failure catch (e) {
      print('[PostRepository] Failure fetching posts: $e');
      return Left(e);
    } catch (e, stackTrace) {
      print('[PostRepository] Exception fetching posts: $e');
      print('[PostRepository] Stack trace: $stackTrace');
      return Left(ServerFailure('Failed to get posts: $e'));
    }
  }

  @override
  Future<Either<Failure, Post>> getPostById(String postId) async {
    try {
      // Fetch from remote only - no fallback
      final post = await remoteDataSource.getPostById(postId);
      return Right(post);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get post: $e'));
    }
  }

  @override
  Future<Either<Failure, Post>> createPost(Post post) async {
    try {
      final postData = {
        'content': post.content,
        'type': post.type.toString().split('.').last,
        if (post.imageUrls.isNotEmpty) 'image_urls': post.imageUrls,
        if (post.originalPost != null) 'original_post_id': post.originalPost!.id,
        if (post.attachedEvent != null) 'attached_event_id': post.attachedEvent!.id,
      };
      final newPost = await remoteDataSource.createPost(postData);
      return Right(newPost);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Post>> updatePost(Post post) async {
    try {
      final postData = {
        'content': post.content,
        'type': post.type.toString().split('.').last,
        if (post.imageUrls.isNotEmpty) 'image_urls': post.imageUrls,
      };
      final updatedPost = await remoteDataSource.updatePost(post.id, postData);
      return Right(updatedPost);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(String postId) async {
    try {
      await remoteDataSource.deletePost(postId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Post>> likePost(String postId) async {
    try {
      print('[PostRepository] Liking post $postId...');
      await remoteDataSource.likePost(postId);
      print('[PostRepository] Like successful');
      // Backend doesn't return updated post, so we return a placeholder
      // The bloc will handle optimistic update
      return Right(Post(
        id: postId,
        author: User(
          id: '', email: '', name: '',
          createdAt: DateTime.now(),
          settings: const UserSettings(),
          stats: const UserStats(),
          privacy: const UserPrivacy(),
        ),
        content: '',
        type: PostType.text,
        createdAt: DateTime.now(),
      ));
    } catch (e, stackTrace) {
      print('[PostRepository] Error liking post: $e');
      print('[PostRepository] Stack trace: $stackTrace');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Post>> unlikePost(String postId) async {
    try {
      print('[PostRepository] Unliking post $postId...');
      await remoteDataSource.unlikePost(postId);
      print('[PostRepository] Unlike successful');
      // Backend doesn't return updated post, so we return a placeholder
      // The bloc will handle optimistic update
      return Right(Post(
        id: postId,
        author: User(
          id: '', email: '', name: '',
          createdAt: DateTime.now(),
          settings: const UserSettings(),
          stats: const UserStats(),
          privacy: const UserPrivacy(),
        ),
        content: '',
        type: PostType.text,
        createdAt: DateTime.now(),
      ));
    } catch (e, stackTrace) {
      print('[PostRepository] Error unliking post: $e');
      print('[PostRepository] Stack trace: $stackTrace');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Post>> repostPost(String postId, {String? quoteContent}) async {
    try {
      final post = await remoteDataSource.repostPost(postId, comment: quoteContent);
      return Right(post);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> undoRepost(String postId) async {
    try {
      await remoteDataSource.undoRepost(postId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> bookmarkPost(String postId) async {
    // TODO: Implement bookmarks
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> unbookmarkPost(String postId) async {
    // TODO: Implement bookmarks
    return const Right(null);
  }

  @override
  Future<Either<Failure, PaginatedResponse<Post>>> getBookmarkedPosts({int limit = 20, int offset = 0}) async {
    try {
      final posts = await remoteDataSource.getBookmarkedPosts(limit: limit, offset: offset);

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: posts, meta: meta));
    } catch (e) {
      return Left(ServerFailure('Failed to get bookmarked posts: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Comment>>> getComments(String postId, {int limit = 20, int offset = 0}) async {
    try {
      // Convert offset to page for now (until backend supports offset)
      final page = (offset ~/ limit) + 1;

      // Fetch from remote only - no fallback
      final comments = await remoteDataSource.getPostComments(postId, page: page, limit: limit);

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: comments, meta: meta));
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('Failed to get comments: $e'));
    }
  }

  @override
  Future<Either<Failure, Comment>> createComment(Comment comment) async {
    try {
      final commentData = {
        'content': comment.content,
        'author_id': comment.author.id,
        if (comment.parentCommentId != null) 'parent_comment_id': comment.parentCommentId,
      };
      final newComment = await remoteDataSource.createComment(comment.postId, commentData);
      return Right(newComment);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Comment>> updateComment(Comment comment) async {
    try {
      final commentData = {
        'content': comment.content,
      };
      final updatedComment = await remoteDataSource.updateComment(comment.id, commentData);
      return Right(updatedComment);
    } catch (e) {
      return Left(ServerFailure('Failed to update comment: $e'));
    }
  }

  @override
  Future<Either<Failure, Comment>> likeComment(String postId, String commentId) async {
    try {
      print('[PostRepository] Liking comment $commentId on post $postId...');
      await remoteDataSource.likeComment(postId, commentId);
      print('[PostRepository] Like comment successful');

      // Create a placeholder comment - the bloc will handle optimistic update
      return Right(Comment(
        id: commentId,
        postId: postId,
        author: User(
          id: '', email: '', name: '',
          createdAt: DateTime.now(),
          settings: const UserSettings(),
          stats: const UserStats(),
          privacy: const UserPrivacy(),
        ),
        content: '',
        createdAt: DateTime.now(),
        isLikedByCurrentUser: true,
      ));
    } catch (e, stackTrace) {
      print('[PostRepository] Error liking comment: $e');
      print('[PostRepository] Stack trace: $stackTrace');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Comment>> unlikeComment(String postId, String commentId) async {
    try {
      print('[PostRepository] Unliking comment $commentId on post $postId...');
      await remoteDataSource.unlikeComment(postId, commentId);
      print('[PostRepository] Unlike comment successful');

      // Create a placeholder comment - the bloc will handle optimistic update
      return Right(Comment(
        id: commentId,
        postId: postId,
        author: User(
          id: '', email: '', name: '',
          createdAt: DateTime.now(),
          settings: const UserSettings(),
          stats: const UserStats(),
          privacy: const UserPrivacy(),
        ),
        content: '',
        createdAt: DateTime.now(),
        isLikedByCurrentUser: false,
      ));
    } catch (e, stackTrace) {
      print('[PostRepository] Error unliking comment: $e');
      print('[PostRepository] Stack trace: $stackTrace');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComment(String commentId) async {
    try {
      await remoteDataSource.deleteComment(commentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete comment: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Post>>> getFeedPosts({int limit = 20, int offset = 0}) async {
    try {
      final posts = await remoteDataSource.getPosts(limit: limit, offset: offset);

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: posts, meta: meta));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<Post>>> getUserPosts(String userId, {int limit = 20, int offset = 0}) async {
    try {
      // TODO: Use proper backend endpoint GET /users/{id}/posts instead of filtering
      final posts = await remoteDataSource.getPostsByUser(userId, page: (offset ~/ limit) + 1, limit: limit);

      // TODO: Parse meta field from API response when backend implements it
      // For now, create empty meta for backward compatibility
      final meta = PaginationMeta.empty();

      return Right(PaginatedResponse(data: posts, meta: meta));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sharePost(String postId) async {
    // TODO: Implement share tracking
    return const Right(null);
  }
}
