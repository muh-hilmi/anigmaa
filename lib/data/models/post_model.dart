import '../../domain/entities/post.dart';
import '../../domain/entities/event.dart';
import 'user_model.dart';
import 'event_model.dart';

class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.author,
    required super.content,
    required super.type,
    super.imageUrls = const [],
    super.attachedEvent,
    super.poll,
    required super.createdAt,
    super.editedAt,
    super.likesCount = 0,
    super.commentsCount = 0,
    super.repostsCount = 0,
    super.sharesCount = 0,
    super.isLikedByCurrentUser = false,
    super.isRepostedByCurrentUser = false,
    super.isBookmarked = false,
    super.originalPost,
    super.repostAuthor,
    super.repostedAt,
    super.hashtags = const [],
    super.mentions = const [],
    super.visibility = PostVisibility.public,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Backend should always send author as nested object via ToResponse()
    // Temporary fallback for backward compatibility during backend migration
    UserModel author;
    if (json['author'] != null && json['author'] is Map) {
      author = UserModel.fromJson(json['author']);
    } else {
      // Temporary fallback - backend should use ToResponse() to send nested author object
      final authorId = json['author_id'] ?? 'unknown';

      // Extract short username from UUID or use as-is if not UUID
      String displayName;
      if (authorId.toString().contains('-') && authorId.toString().length > 20) {
        displayName = 'User ${authorId.toString().substring(0, 8)}';
      } else {
        displayName = 'User $authorId';
      }

      author = UserModel(
        id: authorId as String,
        email: 'user@anigmaa.com',
        name: displayName,
        createdAt: DateTime.now(),
        settings: const UserSettingsModel(),
        stats: const UserStatsModel(),
        privacy: const UserPrivacyModel(),
      );
    }

    return PostModel(
      id: json['id'] as String,
      author: author,
      content: json['content'] as String,
      type: PostType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PostType.text,
      ),
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      attachedEvent: _parseAttachedEvent(json),
      poll: json['poll'] != null ? PollModel.fromJson(json['poll']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      editedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      repostsCount: json['reposts_count'] as int? ?? 0,
      sharesCount: json['shares_count'] as int? ?? 0,
      isLikedByCurrentUser: json['is_liked_by_user'] as bool? ?? false,
      isRepostedByCurrentUser: json['is_reposted_by_user'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      originalPost: json['original_post'] != null
          ? PostModel.fromJson(json['original_post'])
          : null,
      repostAuthor: json['repost_author'] != null
          ? UserModel.fromJson(json['repost_author'])
          : null,
      repostedAt: json['reposted_at'] != null
          ? DateTime.parse(json['reposted_at'] as String)
          : null,
      hashtags: List<String>.from(json['hashtags'] ?? []),
      mentions: List<String>.from(json['mentions'] ?? []),
      visibility: PostVisibility.values.firstWhere(
        (e) => e.toString().split('.').last == (json['visibility'] ?? 'public'),
        orElse: () => PostVisibility.public,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': (author as UserModel).toJson(),
      'content': content,
      'type': type.toString().split('.').last,
      'imageUrls': imageUrls,
      'attachedEvent': attachedEvent != null
          ? (attachedEvent as EventModel).toJson()
          : null,
      'poll': poll != null ? (poll as PollModel).toJson() : null,
      'createdAt': createdAt.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'repostsCount': repostsCount,
      'sharesCount': sharesCount,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'isRepostedByCurrentUser': isRepostedByCurrentUser,
      'isBookmarked': isBookmarked,
      'originalPost':
          originalPost != null ? (originalPost as PostModel).toJson() : null,
      'repostAuthor':
          repostAuthor != null ? (repostAuthor as UserModel).toJson() : null,
      'repostedAt': repostedAt?.toIso8601String(),
      'hashtags': hashtags,
      'mentions': mentions,
      'visibility': visibility.toString().split('.').last,
    };
  }

  factory PostModel.fromEntity(Post post) {
    return PostModel(
      id: post.id,
      author: post.author,
      content: post.content,
      type: post.type,
      imageUrls: post.imageUrls,
      attachedEvent: post.attachedEvent,
      poll: post.poll,
      createdAt: post.createdAt,
      editedAt: post.editedAt,
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      repostsCount: post.repostsCount,
      sharesCount: post.sharesCount,
      isLikedByCurrentUser: post.isLikedByCurrentUser,
      isRepostedByCurrentUser: post.isRepostedByCurrentUser,
      isBookmarked: post.isBookmarked,
      originalPost: post.originalPost,
      repostAuthor: post.repostAuthor,
      repostedAt: post.repostedAt,
      hashtags: post.hashtags,
      mentions: post.mentions,
      visibility: post.visibility,
    );
  }

  static Event? _parseAttachedEvent(Map<String, dynamic> json) {
    try {
      final eventData = json['attached_event'];
      if (eventData == null) {
        return null;
      }

      // Parse as EventModel
      final event = EventModel.fromJson(eventData);
      return event;
    } catch (e, stackTrace) {
      print('[PostModel] Error parsing attached event: $e');
      print('[PostModel] Stack trace: $stackTrace');
      return null;
    }
  }
}

class PollModel extends Poll {
  const PollModel({
    required super.id,
    required super.question,
    required super.options,
    required super.endsAt,
    super.totalVotes = 0,
    super.hasVoted = false,
    super.votedOptionId,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((option) => PollOptionModel.fromJson(option))
          .toList(),
      endsAt: DateTime.parse(json['ends_at'] as String),
      totalVotes: json['total_votes'] as int? ?? 0,
      hasVoted: json['has_voted'] as bool? ?? false,
      votedOptionId: json['voted_option_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options.map((option) => (option as PollOptionModel).toJson()).toList(),
      'endsAt': endsAt.toIso8601String(),
      'totalVotes': totalVotes,
      'hasVoted': hasVoted,
      'votedOptionId': votedOptionId,
    };
  }
}

class PollOptionModel extends PollOption {
  const PollOptionModel({
    required super.id,
    required super.text,
    super.votes = 0,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      votes: json['votes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'votes': votes,
    };
  }
}
