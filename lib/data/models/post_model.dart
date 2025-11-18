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

  // REVIEW: MULTIPLE FALLBACK PATTERN INDICATES BACKEND INCONSISTENCY
  // This code tries 3 different ways to parse author: 'author' object, 'author_data' object, or fallback to 'author_id'.
  // This defensive programming is a RED FLAG that backend is returning different response shapes for the same endpoint.
  // Backend PostResponse.Author is defined as AuthorSummary (nested object) at post/entity.go:138, so frontend should ONLY
  // expect json['author'] as an object, never 'author_data' or flat 'author_id'. The existence of these fallbacks means
  // backend has inconsistent serialization - likely some endpoints return PostWithDetails (flat) vs PostResponse (nested).
  // SOLUTION: Backend must standardize on ALWAYS using ToResponse() method before sending posts to frontend.
  // Remove these fallback branches once backend is fixed - they mask the real problem and allow bugs to persist.
  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Handle author - could be full object or just ID
    UserModel author;
    if (json['author'] != null && json['author'] is Map) {
      author = UserModel.fromJson(json['author']);
    } else if (json['author_data'] != null && json['author_data'] is Map) {
      author = UserModel.fromJson(json['author_data']);
    } else {
      // Fallback: create minimal user from author_id
      print('[PostModel] No author object found, using fallback. Available keys: ${json.keys.toList()}');
      final authorId = json['author_id'] ?? json['authorId'] ?? 'unknown';
      print('[PostModel] Author ID: $authorId');

      // Extract short username from UUID or use as-is if not UUID
      String displayName;
      if (authorId.toString().contains('-') && authorId.toString().length > 20) {
        // It's a UUID, take first 8 characters
        displayName = 'User ${authorId.toString().substring(0, 8)}';
      } else {
        displayName = 'User $authorId';
      }

      print('[PostModel] Using display name: $displayName');

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
      imageUrls: List<String>.from(json['image_urls'] ?? json['imageUrls'] ?? []),
      attachedEvent: _parseAttachedEvent(json),
      poll: json['poll'] != null ? PollModel.fromJson(json['poll']) : null,
      createdAt: (json['created_at'] ?? json['createdAt']) != null
          ? DateTime.parse(json['created_at'] ?? json['createdAt'] as String)
          : DateTime.now(), // Fallback to now if not provided
      editedAt: (json['updated_at'] ?? json['editedAt']) != null
          ? DateTime.parse(json['updated_at'] ?? json['editedAt'] as String)
          : null,
      likesCount: json['likes_count'] ?? json['likesCount'] as int? ?? 0,
      commentsCount: json['comments_count'] ?? json['commentsCount'] as int? ?? 0,
      repostsCount: json['reposts_count'] ?? json['repostsCount'] as int? ?? 0,
      sharesCount: json['shares_count'] ?? json['sharesCount'] as int? ?? 0,
      isLikedByCurrentUser: json['is_liked_by_current_user'] ?? json['isLikedByCurrentUser'] as bool? ?? false,
      isRepostedByCurrentUser: json['is_reposted_by_current_user'] ?? json['isRepostedByCurrentUser'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] ?? json['isBookmarked'] as bool? ?? false,
      originalPost: (json['original_post'] ?? json['originalPost']) != null
          ? PostModel.fromJson(json['original_post'] ?? json['originalPost'])
          : null,
      repostAuthor: (json['repost_author'] ?? json['repostAuthor']) != null
          ? UserModel.fromJson(json['repost_author'] ?? json['repostAuthor'])
          : null,
      repostedAt: (json['reposted_at'] ?? json['repostedAt']) != null
          ? DateTime.parse(json['reposted_at'] ?? json['repostedAt'] as String)
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
      final eventData = json['attached_event'] ?? json['attachedEvent'];
      if (eventData == null) {
        print('[PostModel] No attached_event found in post ${json['id']}');
        return null;
      }

      print('[PostModel] Found attached event data in post ${json['id']}: ${eventData.runtimeType}');

      // Try to parse as EventModel
      final event = EventModel.fromJson(eventData);
      print('[PostModel] Successfully parsed attached event: ${event.id} - ${event.title}');
      return event;
    } catch (e, stackTrace) {
      print('[PostModel] Error parsing attached event: $e');
      print('[PostModel] Stack trace: $stackTrace');
      print('[PostModel] Event data: ${json['attached_event'] ?? json['attachedEvent']}');
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
      endsAt: DateTime.parse(json['endsAt'] as String),
      totalVotes: json['totalVotes'] as int? ?? 0,
      hasVoted: json['hasVoted'] as bool? ?? false,
      votedOptionId: json['votedOptionId'] as String?,
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
