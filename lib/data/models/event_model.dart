import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';
import '../../domain/entities/event_host.dart';
import '../../domain/entities/event_location.dart';

class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.startTime,
    required super.endTime,
    super.createdAt,
    required super.location,
    required super.host,
    super.imageUrls = const [],
    required super.maxAttendees,
    super.attendeeIds = const [],
    super.price,
    super.isFree = true,
    super.status = EventStatus.upcoming,
    super.privacy = EventPrivacy.public,
    super.pendingRequests = const [],
    // super.tags = const [],
    super.requirements,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Backend uses snake_case consistently
    final startTime = json['start_time'];
    final endTime = json['end_time'];
    final createdAt = json['created_at'];
    final imageUrls = json['image_urls'];
    final maxAttendees = json['max_attendees'];

    // Handle attendee_ids or attendees_count from backend
    final attendeeIds = json['attendee_ids'];
    final attendeesCount = json['attendees_count'];

    final isFree = json['is_free'];
    final pendingRequests = json['pending_requests'];

    // Parse location - expect nested object (backend standard)
    // Fallback to flat fields for backward compatibility (should be removed once backend is standardized)
    EventLocationModel location;
    if (json['location'] != null && json['location'] is Map) {
      location = EventLocationModel.fromJson(json['location']);
    } else {
      // Temporary fallback for legacy flat fields - backend should use nested Location object
      location = EventLocationModel(
        name: json['location_name'] as String? ?? '',
        address: json['location_address'] as String? ?? '',
        latitude: json['location_lat']?.toDouble() ?? 0.0,
        longitude: json['location_lng']?.toDouble() ?? 0.0,
        venue: json['venue'] as String?,
      );
    }

    // Debug logging - check what format backend sends
    print('[EventModel] host field type: ${json['host']?.runtimeType}, host_id: ${json['host_id']}, host_name: ${json['host_name']}, host_avatar_url: ${json['host_avatar_url']}');

    // Parse host - expect nested object (backend standard)
    // Fallback to flat fields for backward compatibility (should be removed once backend is standardized)
    EventHostModel host;
    if (json['host'] != null && json['host'] is Map) {
      host = EventHostModel.fromJson(json['host']);
    } else {
      // Temporary fallback for legacy flat fields - backend should use nested Host object
      host = EventHostModel(
        id: json['host_id'] as String? ?? '',
        name: json['host_name'] as String? ?? 'Unknown',
        avatar: json['host_avatar_url'] as String? ?? '',
        bio: json['host_bio'] as String? ?? '',
        isVerified: json['host_is_verified'] as bool? ?? false,
        rating: json['host_rating']?.toDouble() ?? 0.0,
        eventsHosted: json['host_events_hosted'] as int? ?? 0,
      );
    }

    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: EventCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => EventCategory.meetup,
      ),
      startTime: DateTime.parse(startTime as String),
      endTime: DateTime.parse(endTime as String),
      createdAt: createdAt != null ? DateTime.parse(createdAt as String) : null,
      location: location,
      host: host,
      imageUrls: List<String>.from(imageUrls ?? []),
      maxAttendees: maxAttendees as int,
      // Generate dummy attendee IDs based on count if available
      attendeeIds: attendeeIds != null
          ? List<String>.from(attendeeIds)
          : (attendeesCount != null
              ? List<String>.generate(attendeesCount as int, (i) => 'attendee_$i')
              : <String>[]),
      price: json['price']?.toDouble(),
      isFree: isFree as bool? ?? true,
      status: _parseEventStatus(json['status'] as String?),
      privacy: EventPrivacy.values.firstWhere(
        (e) => e.toString().split('.').last == json['privacy'],
        orElse: () => EventPrivacy.public,
      ),
      pendingRequests: List<String>.from(pendingRequests ?? []),
      // tags: List<String>.from(json['tags'] ?? []),
      requirements: json['requirements'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'price': price ?? 0.0,
      'is_free': isFree,
      'max_attendees': maxAttendees,
      'attendees_count': attendeeIds.length,
      'visibility': privacy.toString().split('.').last,
      'status': status.toString().split('.').last,
      'author_id': host.id,
      'location': (location as EventLocationModel).toJson(),
      'host': (host as EventHostModel).toJson(),
      'image_urls': imageUrls,
      'attendee_ids': attendeeIds,
      'pending_requests': pendingRequests,
      'requirements': requirements,
    };
  }

  factory EventModel.fromEntity(Event event) {
    return EventModel(
      id: event.id,
      title: event.title,
      description: event.description,
      category: event.category,
      startTime: event.startTime,
      endTime: event.endTime,
      createdAt: event.createdAt,
      location: event.location,
      host: event.host,
      imageUrls: event.imageUrls,
      maxAttendees: event.maxAttendees,
      attendeeIds: event.attendeeIds,
      price: event.price,
      isFree: event.isFree,
      status: event.status,
      privacy: event.privacy,
      pendingRequests: event.pendingRequests,
      // tags: event.tags,
      requirements: event.requirements,
    );
  }

  /// Convert EventModel to Event entity
  /// Since EventModel extends Event, this just returns itself
  Event toEntity() => this;

  /// Parse event status from backend string
  static EventStatus _parseEventStatus(String? status) {
    if (status == null) return EventStatus.upcoming;

    final statusLower = status.toLowerCase();
    return EventStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == statusLower,
      orElse: () => EventStatus.upcoming,
    );
  }
}

class EventHostModel extends EventHost {
  const EventHostModel({
    required super.id,
    required super.name,
    required super.avatar,
    required super.bio,
    super.isVerified = false,
    super.rating = 0.0,
    super.eventsHosted = 0,
  });

  factory EventHostModel.fromJson(Map<String, dynamic> json) {
    // Backend uses snake_case consistently
    // Support both 'avatar' and 'avatar_url' field names
    final avatarUrl = json['avatar_url'] ?? json['avatar'] ?? '';

    // Debug logging
    print('[EventHostModel] Parsing host: ${json['name']}, avatar_url: $avatarUrl');

    return EventHostModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: avatarUrl as String,
      bio: json['bio'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      rating: json['rating']?.toDouble() ?? 0.0,
      eventsHosted: json['events_hosted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'isVerified': isVerified,
      'rating': rating,
      'eventsHosted': eventsHosted,
    };
  }
}

class EventLocationModel extends EventLocation {
  const EventLocationModel({
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
    super.venue,
  });

  factory EventLocationModel.fromJson(Map<String, dynamic> json) {
    return EventLocationModel(
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      venue: json['venue'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'venue': venue,
    };
  }
}