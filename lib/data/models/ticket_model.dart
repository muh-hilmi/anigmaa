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
    );
  }

  /// Create from JSON
  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      attendanceCode: json['attendanceCode'] as String,
      pricePaid: (json['pricePaid'] as num).toDouble(),
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      isCheckedIn: json['isCheckedIn'] as bool? ?? false,
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.parse(json['checkedInAt'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
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
