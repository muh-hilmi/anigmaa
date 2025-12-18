import 'dart:convert';
import '../../domain/entities/ticket.dart';

/// Data model for Ticket with JSON serialization
class TicketModel {
  final String id;
  final String userId;
  final String eventId;
  final String attendanceCode;
  final double pricePaid;
  final DateTime purchasedAt;
  final bool isCheckedIn;
  final DateTime? checkedInAt;
  final String status;

  // Event details from TicketWithDetails
  final String? eventTitle;
  final DateTime? eventStartTime;
  final String? eventLocation;

  const TicketModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.attendanceCode,
    required this.pricePaid,
    required this.purchasedAt,
    this.isCheckedIn = false,
    this.checkedInAt,
    this.status = 'active',
    this.eventTitle,
    this.eventStartTime,
    this.eventLocation,
  });

  /// Convert to domain entity
  Ticket toEntity() {
    return Ticket(
      id: id,
      userId: userId,
      eventId: eventId,
      attendanceCode: attendanceCode,
      pricePaid: pricePaid,
      purchasedAt: purchasedAt,
      isCheckedIn: isCheckedIn,
      checkedInAt: checkedInAt,
      status: _parseTicketStatus(status),
      eventTitle: eventTitle,
      eventStartTime: eventStartTime,
      eventLocation: eventLocation,
    );
  }

  /// Create from domain entity
  factory TicketModel.fromEntity(Ticket ticket) {
    return TicketModel(
      id: ticket.id,
      userId: ticket.userId,
      eventId: ticket.eventId,
      attendanceCode: ticket.attendanceCode,
      pricePaid: ticket.pricePaid,
      purchasedAt: ticket.purchasedAt,
      isCheckedIn: ticket.isCheckedIn,
      checkedInAt: ticket.checkedInAt,
      status: _ticketStatusToString(ticket.status),
      eventTitle: ticket.eventTitle,
      eventStartTime: ticket.eventStartTime,
      eventLocation: ticket.eventLocation,
    );
  }

  /// Create from JSON
  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      attendanceCode: json['attendance_code'] as String,
      pricePaid: (json['price_paid'] as num).toDouble(),
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
      isCheckedIn: json['is_checked_in'] as bool? ?? false,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
      // Parse event details if available (from TicketWithDetails)
      eventTitle: json['event_title'] as String?,
      eventStartTime: json['event_start_time'] != null
          ? DateTime.parse(json['event_start_time'] as String)
          : null,
      eventLocation: json['event_location'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'eventId': eventId,
      'attendanceCode': attendanceCode,
      'pricePaid': pricePaid,
      'purchasedAt': purchasedAt.toIso8601String(),
      'isCheckedIn': isCheckedIn,
      'checkedInAt': checkedInAt?.toIso8601String(),
      'status': status,
    };
  }

  /// Parse TicketStatus from string
  static TicketStatus _parseTicketStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return TicketStatus.active;
      case 'cancelled':
        return TicketStatus.cancelled;
      case 'refunded':
        return TicketStatus.refunded;
      case 'expired':
        return TicketStatus.expired;
      default:
        return TicketStatus.active;
    }
  }

  /// Convert TicketStatus to string
  static String _ticketStatusToString(TicketStatus status) {
    switch (status) {
      case TicketStatus.active:
        return 'active';
      case TicketStatus.cancelled:
        return 'cancelled';
      case TicketStatus.refunded:
        return 'refunded';
      case TicketStatus.expired:
        return 'expired';
    }
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());

  /// Create from JSON string
  factory TicketModel.fromJsonString(String jsonString) {
    return TicketModel.fromJson(json.decode(jsonString));
  }
}
