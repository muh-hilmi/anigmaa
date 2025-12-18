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
import '../../../domain/usecases/bookmark_post.dart';
import '../../../domain/usecases/unbookmark_post.dart';
import '../../../domain/usecases/get_bookmarked_posts.dart';
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
  final BookmarkPost bookmarkPost;
  final UnbookmarkPost unbookmarkPost;
  final GetBookmarkedPosts getBookmarkedPosts;

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
    required this.bookmarkPost,
    required this.unbookmarkPost,
    required this.getBookmarkedPosts,
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
    on<SavePostToggled>(_onSavePostToggled);
    on<LoadSavedPosts>(_onLoadSavedPosts);
  }

  Future<void> _onLoadPosts(LoadPosts event, Emitter<PostsState> emit) async {
    emit(PostsLoading());

    try {
      final result = await getPosts(
        const GetPostsParams(limit: postsPerPage, offset: 0),
      );

      result.fold(
        (failure) {
          emit(PostsError('Failed to load posts: ${failure.toString()}'));
        },
        (paginatedResponse) {
          emit(
            PostsLoaded(
              posts: paginatedResponse.data,
              paginationMeta: paginatedResponse.meta,
            ),
          );
        },
      );
    } catch (e) {
      emit(PostsError('Exception loading posts: $e'));
    }
  }

  Future<void> _onRefreshPosts(
    RefreshPosts event,
    Emitter<PostsState> emit,
  ) async {
    final result = await getPosts(
      const GetPostsParams(limit: postsPerPage, offset: 0),
    );

    result.fold(
      (failure) => emit(const PostsError('Failed to refresh posts')),
      (paginatedResponse) {
        // Preserve existing comments when refreshing posts
        final currentState = state is PostsLoaded ? state as PostsLoaded : null;
        emit(
          PostsLoaded(
            posts: paginatedResponse.data,
            commentsByPostId: currentState?.commentsByPostId ?? const {},
            paginationMeta: paginatedResponse.meta,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMorePosts(
    LoadMorePosts event,
    Emitter<PostsState> emit,
  ) async {
    if (state is! PostsLoaded) return;

    final currentState = state as PostsLoaded;

    // Don't load more if already loading or no more posts
    if (currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    // Set loading state
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final result = await getPosts(
        GetPostsParams(limit: postsPerPage, offset: currentState.currentOffset),
      );

      result.fold(
        (failure) {
          // Revert loading state on error
          emit(currentState.copyWith(isLoadingMore: false));
        },
        (paginatedResponse) {
          final updatedPosts = [
            ...currentState.posts,
            ...paginatedResponse.data,
          ];
          emit(
            currentState.copyWith(
              posts: updatedPosts,
              paginationMeta: paginatedResponse.meta,
              isLoadingMore: false,
            ),
          );
        },
      );
    } catch (e) {
      // Revert loading state on error
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onCreatePost(
    CreatePostRequested event,
    Emitter<PostsState> emit,
  ) async {
    // Set creating state
    if (state is PostsLoaded) {
      final currentState = state as PostsLoaded;
      emit(currentState.copyWith(isCreatingPost: true));
    }

    final result = await createPost(CreatePostParams(post: event.post));

    result.fold(
      (failure) {
        // Set error message so UI can show snackbar
        if (state is PostsLoaded) {
          final currentState = state as PostsLoaded;
          emit(
            currentState.copyWith(
              isCreatingPost: false,
              createErrorMessage: 'Gagal bikin post: ${failure.message}',
            ),
          );
        }
      },
      (newPost) {
        // Add new post to the list with success message
        if (state is PostsLoaded) {
          final currentState = state as PostsLoaded;
          final updatedPosts = [newPost, ...currentState.posts];
          emit(
            currentState.copyWith(
              posts: updatedPosts,
              isCreatingPost: false,
              successMessage: 'Post berhasil dibuat! 🎉',
            ),
          );
        }
      },
    );
  }

  Future<void> _onLikePostToggled(
    LikePostToggled event,
    Emitter<PostsState> emit,
  ) async {
    if (state is! PostsLoaded) return;

    final currentState = state as PostsLoaded;

    // Optimistic update - update UI immediately
    // event.isCurrentlyLiked is the NEW state after toggle
    final updatedPosts = currentState.posts.map((post) {
      if (post.id == event.postId) {
        return post.copyWith(
          isLikedByCurrentUser: event.isCurrentlyLiked,
          likesCount: event.isCurrentlyLiked
              ? post.likesCount +
                    1 // Just liked, increment
              : (post.likesCount > 0
                    ? post.likesCount - 1
                    : 0), // Just unliked, decrement
        );
      }
      return post;
    }).toList();

    emit(currentState.copyWith(posts: updatedPosts));

    // Call API in background (don't wait for response)
    final result = event.isCurrentlyLiked
        ? await likePost(event.postId) // New state is liked, so call likePost
        : await unlikePost(
            event.postId,
          ); // New state is unliked, so call unlikePost

    result.fold(
      (failure) {
        // If API fails, revert the optimistic update
        final revertedPosts = updatedPosts.map((post) {
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
        emit(currentState.copyWith(posts: revertedPosts));
      },
      (updatedPost) {
        // API success - keep the optimistic update
      },
    );
  }

  Future<void> _onRepostRequested(
    RepostRequested event,
    Emitter<PostsState> emit,
  ) async {
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

  Future<void> _onLoadComments(
    LoadComments event,
    Emitter<PostsState> emit,
  ) async {
    if (state is! PostsLoaded) return;

    final currentState = state as PostsLoaded;
    final result = await getComments(GetCommentsParams(postId: event.postId));

    result.fold(
      (failure) {
        // Don't emit error - just log it. Keep posts visible!
        // Optionally emit state with empty comments for this post
        final updatedComments = Map<String, List<Comment>>.from(
          currentState.commentsByPostId,
        );
        updatedComments[event.postId] = [];
        emit(currentState.copyWith(commentsByPostId: updatedComments));
      },
      (paginatedResponse) {
        final updatedComments = Map<String, List<Comment>>.from(
          currentState.commentsByPostId,
        );
        updatedComments[event.postId] = paginatedResponse.data;
        emit(currentState.copyWith(commentsByPostId: updatedComments));
      },
    );
  }

  Future<void> _onCreateComment(
    CreateCommentRequested event,
    Emitter<PostsState> emit,
  ) async {
    if (state is! PostsLoaded) return;

    final currentState = state as PostsLoaded;

    // Mark comment as sending
    final sendingIds = Set<String>.from(currentState.sendingCommentIds);
    sendingIds.add(event.comment.id);

    // Optimistic update: Add comment immediately to UI
    final updatedComments = Map<String, List<Comment>>.from(
      currentState.commentsByPostId,
    );
    final existingComments = updatedComments[event.comment.postId] ?? [];
    updatedComments[event.comment.postId] = [
      event.comment,
      ...existingComments,
    ];

    // Update comment count in posts
    final updatedPosts = currentState.posts.map((post) {
      if (post.id == event.comment.postId) {
        return post.copyWith(commentsCount: post.commentsCount + 1);
      }
      return post;
    }).toList();

    emit(
      currentState.copyWith(
        posts: updatedPosts,
        commentsByPostId: updatedComments,
        sendingCommentIds: sendingIds,
      ),
    );

    final result = await createComment(
      CreateCommentParams(comment: event.comment),
    );

    result.fold(
      (failure) {
        // Revert optimistic update on failure - use current state not old state
        if (state is! PostsLoaded) return;
        final latestState = state as PostsLoaded;

        // Remove from sending state
        final sendingIds = Set<String>.from(latestState.sendingCommentIds);
        sendingIds.remove(event.comment.id);

        final revertedComments = Map<String, List<Comment>>.from(
          latestState.commentsByPostId,
        );
        // Remove the temporary comment
        if (revertedComments.containsKey(event.comment.postId)) {
          revertedComments[event.comment.postId] =
              revertedComments[event.comment.postId]!
                  .where((c) => c.id != event.comment.id)
                  .toList();
        }

        final revertedPosts = latestState.posts.map((post) {
          if (post.id == event.comment.postId) {
            return post.copyWith(
              commentsCount: post.commentsCount > 0
                  ? post.commentsCount - 1
                  : 0,
            );
          }
          return post;
        }).toList();

        emit(
          latestState.copyWith(
            posts: revertedPosts,
            commentsByPostId: revertedComments,
            sendingCommentIds: sendingIds,
          ),
        );
      },
      (newComment) {
        // Replace temporary comment with actual comment from server - use current state
        if (state is! PostsLoaded) return;
        final latestState = state as PostsLoaded;

        // Comment created successfully

        // Remove from sending state
        final sendingIds = Set<String>.from(latestState.sendingCommentIds);
        sendingIds.remove(event.comment.id);

        final finalComments = Map<String, List<Comment>>.from(
          latestState.commentsByPostId,
        );
        final postComments = finalComments[event.comment.postId] ?? [];

        finalComments[event.comment.postId] = postComments.map((c) {
          if (c.id == event.comment.id) {
            return newComment;
          }
          return c;
        }).toList();

        emit(
          latestState.copyWith(
            commentsByPostId: finalComments,
            sendingCommentIds: sendingIds,
          ),
        );
      },
    );
  }

  Future<void> _onLikeCommentToggled(
    LikeCommentToggled event,
    Emitter<PostsState> emit,
  ) async {
    if (state is! PostsLoaded) return;

    final currentState = state as PostsLoaded;

    // Optimistic update
    final updatedComments = Map<String, List<Comment>>.from(
      currentState.commentsByPostId,
    );

    if (updatedComments.containsKey(event.postId)) {
      final postComments = List<Comment>.from(updatedComments[event.postId]!);
      final commentIndex = postComments.indexWhere(
        (c) => c.id == event.commentId,
      );

      if (commentIndex != -1) {
        final comment = postComments[commentIndex];
        final newLikeCount = event.isCurrentlyLiked
            ? (comment.likesCount > 0 ? comment.likesCount - 1 : 0)
            : comment.likesCount + 1;

        postComments[commentIndex] = comment.copyWith(
          isLikedByCurrentUser: !event.isCurrentlyLiked,
          likesCount: newLikeCount,
        );
        updatedComments[event.postId] = postComments;

        emit(currentState.copyWith(commentsByPostId: updatedComments));
      }
    }

    // Make API call
    final result = event.isCurrentlyLiked
        ? await unlikeComment(
            UnlikeCommentParams(
              postId: event.postId,
              commentId: event.commentId,
            ),
          )
        : await likeComment(
            LikeCommentParams(postId: event.postId, commentId: event.commentId),
          );

    result.fold(
      (failure) {
        // Revert optimistic update on failure
        if (state is! PostsLoaded) return;
        final latestState = state as PostsLoaded;

        final revertedComments = Map<String, List<Comment>>.from(
          latestState.commentsByPostId,
        );
        if (revertedComments.containsKey(event.postId)) {
          final postComments = List<Comment>.from(
            revertedComments[event.postId]!,
          );
          final commentIndex = postComments.indexWhere(
            (c) => c.id == event.commentId,
          );

          if (commentIndex != -1) {
            final comment = postComments[commentIndex];
            final revertedLikeCount = event.isCurrentlyLiked
                ? comment.likesCount + 1
                : (comment.likesCount > 0 ? comment.likesCount - 1 : 0);

            postComments[commentIndex] = comment.copyWith(
              isLikedByCurrentUser: event.isCurrentlyLiked,
              likesCount: revertedLikeCount,
            );
            revertedComments[event.postId] = postComments;

            emit(latestState.copyWith(commentsByPostId: revertedComments));
          }
        }
      },
      (_) {
        // Success - optimistic update already applied
      },
    );
  }

  Future<void> _onSavePostToggled(
    SavePostToggled event,
    Emitter<PostsState> emit,
  ) async {
    // Optimistic update
    if (state is PostsLoaded) {
      final currentState = state as PostsLoaded;
      final updatedPosts = currentState.posts.map((post) {
        if (post.id == event.postId) {
          return post.copyWith(isBookmarked: !event.isCurrentlySaved);
        }
        return post;
      }).toList();

      emit(currentState.copyWith(posts: updatedPosts));
    }

    // Make API call
    final result = event.isCurrentlySaved
        ? await unbookmarkPost(event.postId)
        : await bookmarkPost(event.postId);

    result.fold(
      (failure) {
        // Revert optimistic update on failure
        if (state is! PostsLoaded) return;
        final latestState = state as PostsLoaded;

        final revertedPosts = latestState.posts.map((post) {
          if (post.id == event.postId) {
            return post.copyWith(isBookmarked: event.isCurrentlySaved);
          }
          return post;
        }).toList();

        emit(latestState.copyWith(posts: revertedPosts));
      },
      (updatedPost) {
        // Success - update with server response
        if (state is! PostsLoaded) return;
        final latestState = state as PostsLoaded;

        final serverUpdatedPosts = latestState.posts.map((post) {
          if (post.id == event.postId) {
            return updatedPost;
          }
          return post;
        }).toList();

        emit(latestState.copyWith(posts: serverUpdatedPosts));
      },
    );
  }

  Future<void> _onLoadSavedPosts(
    LoadSavedPosts event,
    Emitter<PostsState> emit,
  ) async {
    emit(PostsLoading());

    try {
      final result = await getBookmarkedPosts(
        const GetBookmarkedPostsParams(limit: postsPerPage, offset: 0),
      );

      result.fold(
        (failure) {
          emit(PostsError('Failed to load saved posts: ${failure.toString()}'));
        },
        (posts) {
          emit(
            PostsLoaded(
              posts: posts,
              paginationMeta: null,
            ),
          );
        },
      );
    } catch (e) {
      emit(PostsError('Exception loading saved posts: $e'));
    }
  }
}
