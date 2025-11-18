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

  // REVIEW: DUAL NAMING CONVENTION FALLBACKS INDICATE LACK OF STANDARDIZATION
  // Frontend is doing ?? fallbacks for every field: snake_case ?? camelCase. This is a symptom of backend not having
  // a clear serialization standard. Backend Event entity uses snake_case consistently (start_time, end_time, etc.),
  // but frontend is hedging bets by accepting both. This is technical debt that will cause confusion.
  // DECISION: Backend MUST use snake_case for all JSON fields (already mostly doing this). Remove camelCase fallbacks
  // from frontend once backend is verified to be 100% snake_case. Document this as THE standard in API guidelines.
  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and snake_case from backend
    final startTime = json['start_time'] ?? json['startTime'];
    final endTime = json['end_time'] ?? json['endTime'];
    final imageUrls = json['image_urls'] ?? json['imageUrls'];
    final maxAttendees = json['max_attendees'] ?? json['maxAttendees'];

    // Handle attendee_ids or attendees_count from backend
    final attendeeIds = json['attendee_ids'] ?? json['attendeeIds'];
    final attendeesCount = json['attendees_count'] ?? json['attendeesCount'];

    final isFree = json['is_free'] ?? json['isFree'];
    final pendingRequests = json['pending_requests'] ?? json['pendingRequests'];

    // REVIEW: NESTED VS FLAT STRUCTURE FALLBACK - Another sign of backend inconsistency
    // Some endpoints return location:{name, address, lat, lng} while others return location_name, location_address, etc.
    // Backend EventWithDetails returns flat fields (location_name, location_lat) but should normalize to nested Location object.
    // Parse location - support both nested object and flat fields
    EventLocationModel location;
    if (json['location'] != null) {
      location = EventLocationModel.fromJson(json['location']);
    } else {
      // Backend sends flat fields
      location = EventLocationModel(
        name: json['location_name'] as String? ?? '',
        address: json['location_address'] as String? ?? '',
        latitude: (json['location_lat'] ?? json['latitude'])?.toDouble() ?? 0.0,
        longitude: (json['location_lng'] ?? json['longitude'])?.toDouble() ?? 0.0,
        venue: json['venue'] as String?,
      );
    }

    // Parse host - support both nested object and flat fields
    EventHostModel host;
    if (json['host'] != null) {
      host = EventHostModel.fromJson(json['host']);
    } else {
      // Backend sends flat fields
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
      status: EventStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => EventStatus.upcoming,
      ),
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
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': (location as EventLocationModel).toJson(),
      'host': (host as EventHostModel).toJson(),
      'imageUrls': imageUrls,
      'maxAttendees': maxAttendees,
      'attendeeIds': attendeeIds,
      'price': price,
      'isFree': isFree,
      'status': status.toString().split('.').last,
      'privacy': privacy.toString().split('.').last,
      'pendingRequests': pendingRequests,
      // 'tags': tags,
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
    // Support both camelCase and snake_case from backend
    final isVerified = json['is_verified'] ?? json['isVerified'];
    final eventsHosted = json['events_hosted'] ?? json['eventsHosted'];

    return EventHostModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      bio: json['bio'] as String? ?? '',
      isVerified: isVerified as bool? ?? false,
      rating: json['rating']?.toDouble() ?? 0.0,
      eventsHosted: eventsHosted as int? ?? 0,
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