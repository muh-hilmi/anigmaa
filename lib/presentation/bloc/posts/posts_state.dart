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

  const PostsLoaded({
    required this.posts,
    this.commentsByPostId = const {},
    this.hasMore = true,
    this.isLoadingMore = false,
    this.currentOffset = 0,
  });

  PostsLoaded copyWith({
    List<Post>? posts,
    Map<String, List<Comment>>? commentsByPostId,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentOffset,
  }) {
    return PostsLoaded(
      posts: posts ?? this.posts,
      commentsByPostId: commentsByPostId ?? this.commentsByPostId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }

  @override
  List<Object?> get props => [posts, commentsByPostId, hasMore, isLoadingMore, currentOffset];
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
