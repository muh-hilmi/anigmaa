import 'package:equatable/equatable.dart';
import 'user.dart';
import 'event.dart';

enum PostType {
  text,
  textWithImages,
  textWithEvent,
  poll,
  repost,
}

class Post extends Equatable {
  final String id;
  final User author;
  final String content;
  final PostType type;
  final List<String> imageUrls;
  final Event? attachedEvent;
  final Poll? poll;
  final DateTime createdAt;
  final DateTime? editedAt;

  // Engagement metrics
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final int sharesCount;

  // User interactions
  final bool isLikedByCurrentUser;
  final bool isRepostedByCurrentUser;
  final bool isBookmarked;

  // Repost data (if this post is a repost)
  final Post? originalPost;
  final User? repostAuthor;
  final DateTime? repostedAt;

  // Hashtags and mentions
  final List<String> hashtags;
  final List<String> mentions; // user IDs

  // Visibility
  final PostVisibility visibility;

  const Post({
    required this.id,
    required this.author,
    required this.content,
    required this.type,
    this.imageUrls = const [],
    this.attachedEvent,
    this.poll,
    required this.createdAt,
    this.editedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    this.sharesCount = 0,
    this.isLikedByCurrentUser = false,
    this.isRepostedByCurrentUser = false,
    this.isBookmarked = false,
    this.originalPost,
    this.repostAuthor,
    this.repostedAt,
    this.hashtags = const [],
    this.mentions = const [],
    this.visibility = PostVisibility.public,
  });

  Post copyWith({
    String? id,
    User? author,
    String? content,
    PostType? type,
    List<String>? imageUrls,
    Event? attachedEvent,
    Poll? poll,
    DateTime? createdAt,
    DateTime? editedAt,
    int? likesCount,
    int? commentsCount,
    int? repostsCount,
    int? sharesCount,
    bool? isLikedByCurrentUser,
    bool? isRepostedByCurrentUser,
    bool? isBookmarked,
    Post? originalPost,
    User? repostAuthor,
    DateTime? repostedAt,
    List<String>? hashtags,
    List<String>? mentions,
    PostVisibility? visibility,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      type: type ?? this.type,
      imageUrls: imageUrls ?? this.imageUrls,
      attachedEvent: attachedEvent ?? this.attachedEvent,
      poll: poll ?? this.poll,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      repostsCount: repostsCount ?? this.repostsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isRepostedByCurrentUser: isRepostedByCurrentUser ?? this.isRepostedByCurrentUser,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      originalPost: originalPost ?? this.originalPost,
      repostAuthor: repostAuthor ?? this.repostAuthor,
      repostedAt: repostedAt ?? this.repostedAt,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
      visibility: visibility ?? this.visibility,
    );
  }

  @override
  List<Object?> get props => [
        id,
        author,
        content,
        type,
        imageUrls,
        attachedEvent,
        poll,
        createdAt,
        editedAt,
        likesCount,
        commentsCount,
        repostsCount,
        sharesCount,
        isLikedByCurrentUser,
        isRepostedByCurrentUser,
        isBookmarked,
        originalPost,
        repostAuthor,
        repostedAt,
        hashtags,
        mentions,
        visibility,
      ];
}

class Poll extends Equatable {
  final String id;
  final String question;
  final List<PollOption> options;
  final DateTime endsAt;
  final int totalVotes;
  final bool hasVoted;
  final String? votedOptionId;

  const Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.endsAt,
    this.totalVotes = 0,
    this.hasVoted = false,
    this.votedOptionId,
  });

  bool get isEnded => DateTime.now().isAfter(endsAt);

  @override
  List<Object?> get props => [
        id,
        question,
        options,
        endsAt,
        totalVotes,
        hasVoted,
        votedOptionId,
      ];
}

class PollOption extends Equatable {
  final String id;
  final String text;
  final int votes;

  const PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
  });

  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0;
    return (votes / totalVotes) * 100;
  }

  @override
  List<Object?> get props => [id, text, votes];
}

enum PostVisibility {
  public,
  followers,
  private,
}
