import 'package:equatable/equatable.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/comment.dart';

abstract class PostsState extends Equatable {
  const PostsState();

  @override
  List<Object?> get props => [];
}

class PostsInitial extends PostsState {}

class PostsLoading extends PostsState {}

class PostsLoaded extends PostsState {
  final List<Post> posts;
  final Map<String, List<Comment>> commentsByPostId;
  final bool hasMore;
  final bool isLoadingMore;
  final int currentOffset;
  final bool isCreatingPost;
  final String? createErrorMessage;
  final String? successMessage;

  const PostsLoaded({
    required this.posts,
    this.commentsByPostId = const {},
    this.hasMore = true,
    this.isLoadingMore = false,
    this.currentOffset = 0,
    this.isCreatingPost = false,
    this.createErrorMessage,
    this.successMessage,
  });

  PostsLoaded copyWith({
    List<Post>? posts,
    Map<String, List<Comment>>? commentsByPostId,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentOffset,
    bool? isCreatingPost,
    String? createErrorMessage,
    String? successMessage,
  }) {
    return PostsLoaded(
      posts: posts ?? this.posts,
      commentsByPostId: commentsByPostId ?? this.commentsByPostId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentOffset: currentOffset ?? this.currentOffset,
      isCreatingPost: isCreatingPost ?? this.isCreatingPost,
      createErrorMessage: createErrorMessage,
      successMessage: successMessage,
    );
  }

  PostsLoaded clearMessages() {
    return PostsLoaded(
      posts: posts,
      commentsByPostId: commentsByPostId,
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
      currentOffset: currentOffset,
      isCreatingPost: isCreatingPost,
      createErrorMessage: null,
      successMessage: null,
    );
  }

  @override
  List<Object?> get props => [
        posts,
        commentsByPostId,
        hasMore,
        isLoadingMore,
        currentOffset,
        isCreatingPost,
        createErrorMessage,
        successMessage,
      ];
}

class PostsError extends PostsState {
  final String message;

  const PostsError(this.message);

  @override
  List<Object?> get props => [message];
}

class CommentsLoading extends PostsState {
  final List<Post> posts;

  const CommentsLoading(this.posts);

  @override
  List<Object?> get props => [posts];
}

class CommentCreated extends PostsState {
  final Comment comment;

  const CommentCreated(this.comment);

  @override
  List<Object?> get props => [comment];
}
