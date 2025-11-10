import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/get_posts.dart';
import '../../../domain/usecases/create_post.dart';
import '../../../domain/usecases/like_post.dart';
import '../../../domain/usecases/unlike_post.dart';
import '../../../domain/usecases/repost_post.dart';
import '../../../domain/usecases/get_comments.dart';
import '../../../domain/usecases/create_comment.dart';
import '../../../domain/usecases/like_comment.dart';
import '../../../domain/usecases/unlike_comment.dart';
import 'posts_event.dart';
import 'posts_state.dart';
import '../../../domain/entities/comment.dart';

const int postsPerPage = 20;

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final GetPosts getPosts;
  final CreatePost createPost;
  final LikePost likePost;
  final UnlikePost unlikePost;
  final RepostPost repostPost;
  final GetComments getComments;
  final CreateComment createComment;
  final LikeComment likeComment;
  final UnlikeComment unlikeComment;

  PostsBloc({
    required this.getPosts,
    required this.createPost,
    required this.likePost,
    required this.unlikePost,
    required this.repostPost,
    required this.getComments,
    required this.createComment,
    required this.likeComment,
    required this.unlikeComment,
  }) : super(PostsInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<RefreshPosts>(_onRefreshPosts);
    on<LoadMorePosts>(_onLoadMorePosts);
    on<CreatePostRequested>(_onCreatePost);
    on<LikePostToggled>(_onLikePostToggled);
    on<RepostRequested>(_onRepostRequested);
    on<LoadComments>(_onLoadComments);
    on<CreateCommentRequested>(_onCreateComment);
    on<LikeCommentToggled>(_onLikeCommentToggled);
  }

  Future<void> _onLoadPosts(LoadPosts event, Emitter<PostsState> emit) async {
    emit(PostsLoading());

    try {
      final result = await getPosts(const GetPostsParams(limit: postsPerPage, offset: 0));

      result.fold(
        (failure) {
          emit(PostsError('Failed to load posts: ${failure.toString()}'));
        },
        (posts) {
          emit(PostsLoaded(
            posts: posts,
            hasMore: posts.length >= postsPerPage,
            currentOffset: posts.length,
          ));
        },
      );
    } catch (e, stackTrace) {
      emit(PostsError('Exception loading posts: $e'));
    }
  }

  Future<void> _onRefreshPosts(RefreshPosts event, Emitter<PostsState> emit) async {
    final result = await getPosts(const GetPostsParams(limit: postsPerPage, offset: 0));

    result.fold(
      (failure) => emit(const PostsError('Failed to refresh posts')),
      (posts) {
        emit(PostsLoaded(
          posts: posts,
          hasMore: posts.length >= postsPerPage,
          currentOffset: posts.length,
        ));
      },
    );
  }

  Future<void> _onLoadMorePosts(LoadMorePosts event, Emitter<PostsState> emit) async {
    if (state is! PostsLoaded) return;

    final currentState = state as PostsLoaded;

    // Don't load more if already loading or no more posts
    if (currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    // Set loading state
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final result = await getPosts(GetPostsParams(
        limit: postsPerPage,
        offset: currentState.currentOffset,
      ));

      result.fold(
        (failure) {
          // Revert loading state on error
          emit(currentState.copyWith(isLoadingMore: false));
        },
        (newPosts) {
          final updatedPosts = [...currentState.posts, ...newPosts];
          emit(currentState.copyWith(
            posts: updatedPosts,
            hasMore: newPosts.length >= postsPerPage,
            isLoadingMore: false,
            currentOffset: updatedPosts.length,
          ));
        },
      );
    } catch (e, stackTrace) {
      // Revert loading state on error
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onCreatePost(CreatePostRequested event, Emitter<PostsState> emit) async {
    final result = await createPost(CreatePostParams(post: event.post));

    result.fold(
      (failure) {
        // Don't emit error - just log it. Keep posts visible!
      },
      (newPost) {
        if (state is PostsLoaded) {
          final currentState = state as PostsLoaded;
          final updatedPosts = [newPost, ...currentState.posts];
          emit(currentState.copyWith(posts: updatedPosts));
        }
      },
    );
  }

  Future<void> _onLikePostToggled(LikePostToggled event, Emitter<PostsState> emit) async {
    if (state is! PostsLoaded) return;

    final currentState = state as PostsLoaded;

    // Optimistic update - update UI immediately
    final updatedPosts = currentState.posts.map((post) {
      if (post.id == event.postId) {
        return post.copyWith(
          isLikedByCurrentUser: !event.isCurrentlyLiked,
          likesCount: event.isCurrentlyLiked
              ? (post.likesCount > 0 ? post.likesCount - 1 : 0)
              : post.likesCount + 1,
        );
      }
      return post;
    }).toList();

    emit(currentState.copyWith(posts: updatedPosts));

    // Call API in background (don't wait for response)
    final result = event.isCurrentlyLiked
        ? await unlikePost(event.postId)
        : await likePost(event.postId);

    result.fold(
      (failure) {
        // If API fails, revert the optimistic update
        final revertedPosts = updatedPosts.map((post) {
          if (post.id == event.postId) {
            return post.copyWith(
              isLikedByCurrentUser: event.isCurrentlyLiked,
              likesCount: event.isCurrentlyLiked
                  ? post.likesCount + 1
                  : (post.likesCount > 0 ? post.likesCount - 1 : 0),
            );
          }
          return post;
        }).toList();
        emit(currentState.copyWith(posts: revertedPosts));
      },
      (updatedPost) {
        // API success - keep the optimistic update
      },
    );
  }

  Future<void> _onRepostRequested(RepostRequested event, Emitter<PostsState> emit) async {
    if (state is! PostsLoaded) return;

    final result = await repostPost(
      RepostPostParams(postId: event.postId, quoteContent: event.quoteContent),
    );

    result.fold(
      (failure) {
        // Don't emit error - just log it. Keep posts visible!
      },
      (repostedPost) {
        // Refresh posts to get updated repost
        add(RefreshPosts());
      },
    );
  }

  Future<void> _onLoadComments(LoadComments event, Emitter<PostsState> emit) async {
    if (state is! PostsLoaded) return;

    final currentState = state as PostsLoaded;
    final result = await getComments(GetCommentsParams(postId: event.postId));

    result.fold(
      (failure) {
        // Don't emit error - just log it. Keep posts visible!
        // Optionally emit state with empty comments for this post
        final updatedComments = Map<String, List<Comment>>.from(currentState.commentsByPostId);
        updatedComments[event.postId] = [];
        emit(currentState.copyWith(commentsByPostId: updatedComments));
      },
      (comments) {
        final updatedComments = Map<String, List<Comment>>.from(currentState.commentsByPostId);
        updatedComments[event.postId] = comments;
        emit(currentState.copyWith(commentsByPostId: updatedComments));
      },
    );
  }

  Future<void> _onCreateComment(CreateCommentRequested event, Emitter<PostsState> emit) async {
    if (state is! PostsLoaded) return;

    final result = await createComment(CreateCommentParams(comment: event.comment));

    result.fold(
      (failure) {
        // Don't emit error - just log it. Keep posts visible!
      },
      (newComment) {
        // Refresh posts to get updated comment count
        add(RefreshPosts());
        // Reload comments for this post
        add(LoadComments(event.comment.postId));
      },
    );
  }

  Future<void> _onLikeCommentToggled(LikeCommentToggled event, Emitter<PostsState> emit) async {
    if (state is! PostsLoaded) return;

    final result = event.isCurrentlyLiked
        ? await unlikeComment(UnlikeCommentParams(postId: event.postId, commentId: event.commentId))
        : await likeComment(LikeCommentParams(postId: event.postId, commentId: event.commentId));

    result.fold(
      (failure) {
        // Don't emit error - just log it. Keep posts visible!
      },
      (updatedComment) {
        final currentState = state as PostsLoaded;
        final updatedComments = Map<String, List<Comment>>.from(currentState.commentsByPostId);

        // Update the specific comment in the map
        if (updatedComments.containsKey(updatedComment.postId)) {
          final postComments = List<Comment>.from(updatedComments[updatedComment.postId]!);
          final commentIndex = postComments.indexWhere((c) => c.id == updatedComment.id);
          if (commentIndex != -1) {
            postComments[commentIndex] = updatedComment;
            updatedComments[updatedComment.postId] = postComments;
          }
        }

        emit(currentState.copyWith(commentsByPostId: updatedComments));
      },
    );
  }
}
