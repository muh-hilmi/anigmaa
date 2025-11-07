import 'package:equatable/equatable.dart';

/// Transaction record for ticket purchases
///
/// Tracks payment information, status, and integration with payment gateway
/// Used for payment reconciliation and refund processing
class TicketTransaction extends Equatable {
  final String id;
  final String ticketId;
  final String userId;
  final String eventId;
  final double amount;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  final String? paymentGatewayId; // Midtrans transaction ID
  final String? paymentGatewayResponse; // Full response JSON
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? failureReason;

  const TicketTransaction({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.eventId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.paymentGatewayId,
    this.paymentGatewayResponse,
    required this.createdAt,
    this.completedAt,
    this.cancelledAt,
    this.failureReason,
  });

  bool get isSuccessful => status == TransactionStatus.completed;
  bool get isPending => status == TransactionStatus.pending;
  bool get isFailed => status == TransactionStatus.failed;

  @override
  List<Object?> get props => [
        id,
        ticketId,
        userId,
        eventId,
        amount,
        status,
        paymentMethod,
        paymentGatewayId,
        paymentGatewayResponse,
        createdAt,
        completedAt,
        cancelledAt,
        failureReason,
      ];

  TicketTransaction copyWith({
    String? id,
    String? ticketId,
    String? userId,
    String? eventId,
    double? amount,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentGatewayId,
    String? paymentGatewayResponse,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? failureReason,
  }) {
    return TicketTransaction(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentGatewayId: paymentGatewayId ?? this.paymentGatewayId,
      paymentGatewayResponse:
          paymentGatewayResponse ?? this.paymentGatewayResponse,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  String toString() {
    return 'TicketTransaction(id: $id, amount: $amount, status: $status, '
        'method: $paymentMethod, gatewayId: $paymentGatewayId)';
  }
}

/// Transaction status
enum TransactionStatus {
  pending,    // Payment initiated, waiting for completion
  completed,  // Payment successful
  failed,     // Payment failed
  cancelled,  // User cancelled
  refunded,   // Payment refunded
}

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.refunded:
        return 'Refunded';
    }
  }

  bool get isTerminal =>
      this == TransactionStatus.completed ||
      this == TransactionStatus.failed ||
      this == TransactionStatus.cancelled;
}

/// Payment methods supported by the app
enum PaymentMethod {
  gopay,
  ovo,
  dana,
  shopeepay,
  qris,
  bankTransfer,
  creditCard,
  debitCard,
  free, // For free event reservations
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.gopay:
        return 'GoPay';
      case PaymentMethod.ovo:
        return 'OVO';
      case PaymentMethod.dana:
        return 'DANA';
      case PaymentMethod.shopeepay:
        return 'ShopeePay';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.free:
        return 'Free';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.gopay:
        return '🏍️';
      case PaymentMethod.ovo:
        return '🦉';
      case PaymentMethod.dana:
        return '💙';
      case PaymentMethod.shopeepay:
        return '🛍️';
      case PaymentMethod.qris:
        return '📱';
      case PaymentMethod.bankTransfer:
        return '🏦';
      case PaymentMethod.creditCard:
        return '💳';
      case PaymentMethod.debitCard:
        return '💳';
      case PaymentMethod.free:
        return '🎁';
    }
  }

  bool get isEWallet =>
      this == PaymentMethod.gopay ||
      this == PaymentMethod.ovo ||
      this == PaymentMethod.dana ||
      this == PaymentMethod.shopeepay;
}
