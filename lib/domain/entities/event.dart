import 'event_category.dart';
import 'event_host.dart';
import 'event_location.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? createdAt; // Event creation timestamp
  final EventLocation location;
  final EventHost host;
  final List<String> imageUrls;
  final int maxAttendees;
  final List<String> attendeeIds;
  final double? price;
  final bool isFree;
  final EventStatus status;
  final EventPrivacy privacy;
  final List<String> pendingRequests;
  final String? requirements;

  // Community fields
  final String? communityId; // ID of community if event created by community
  final bool isCommunityEvent; // True if event is from a community
  final bool communityMemberOnly; // True if only community members can join

  // Ticketing fields
  final bool ticketingEnabled; // Enable/disable ticket sales
  final int ticketsSold;
  final List<String> waitlistIds; // Waitlist when event is full

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startTime,
    required this.endTime,
    this.createdAt,
    required this.location,
    required this.host,
    this.imageUrls = const [],
    required this.maxAttendees,
    this.attendeeIds = const [],
    this.price,
    this.isFree = true,
    this.status = EventStatus.upcoming,
    this.privacy = EventPrivacy.public,
    this.pendingRequests = const [],
    this.requirements,
    this.communityId,
    this.isCommunityEvent = false,
    this.communityMemberOnly = false,
    this.ticketingEnabled = false,
    this.ticketsSold = 0,
    this.waitlistIds = const [],
  });

  // Business logic getters
  int get currentAttendees => attendeeIds.length;
  int get spotsLeft => maxAttendees - currentAttendees;
  bool get isFull => currentAttendees >= maxAttendees;
  bool get isStartingSoon => startTime.difference(DateTime.now()).inHours < 2;
  bool get isPrivate => privacy == EventPrivacy.private;
  bool get isPublic => privacy == EventPrivacy.public;
  bool get hasEnded => DateTime.now().isAfter(endTime) || status == EventStatus.ended;
  bool get canJoin => !hasEnded && !isFull && status != EventStatus.cancelled;

  // Ticketing getters
  bool get hasTicketsAvailable => ticketingEnabled && !isSoldOut;
  bool get isSoldOut => ticketingEnabled && ticketsSold >= maxAttendees;
  int get ticketsRemaining => maxAttendees - ticketsSold;
  bool get hasWaitlist => waitlistIds.isNotEmpty;
  int get waitlistCount => waitlistIds.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Event copyWith({
    String? id,
    String? title,
    String? description,
    EventCategory? category,
    DateTime? startTime,
    DateTime? endTime,
    EventLocation? location,
    EventHost? host,
    List<String>? imageUrls,
    int? maxAttendees,
    List<String>? attendeeIds,
    double? price,
    bool? isFree,
    EventStatus? status,
    EventPrivacy? privacy,
    List<String>? pendingRequests,
    String? requirements,
    String? communityId,
    bool? isCommunityEvent,
    bool? communityMemberOnly,
    bool? ticketingEnabled,
    int? ticketsSold,
    List<String>? waitlistIds,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      host: host ?? this.host,
      imageUrls: imageUrls ?? this.imageUrls,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      status: status ?? this.status,
      privacy: privacy ?? this.privacy,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      requirements: requirements ?? this.requirements,
      communityId: communityId ?? this.communityId,
      isCommunityEvent: isCommunityEvent ?? this.isCommunityEvent,
      communityMemberOnly: communityMemberOnly ?? this.communityMemberOnly,
      ticketingEnabled: ticketingEnabled ?? this.ticketingEnabled,
      ticketsSold: ticketsSold ?? this.ticketsSold,
      waitlistIds: waitlistIds ?? this.waitlistIds,
    );
  }
}