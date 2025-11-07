import 'package:uuid/uuid.dart';
import '../../domain/entities/ticket_transaction.dart';

/// Payment service for Indonesian market
///
/// NOTE: Midtrans SDK integration is placeholder for now.
/// Real implementation requires:
/// 1. Backend API to generate Snap tokens
/// 2. Midtrans SDK proper configuration
/// 3. Payment callback handling
///
/// For V1, we'll use mock/free payment flow.
class PaymentService {
  bool _isInitialized = false;
  final _uuid = const Uuid();

  /// Initialize payment service
  Future<void> initialize({
    required String clientKey,
    required String merchantBaseUrl,
    MidtransEnvironment environment = MidtransEnvironment.sandbox,
  }) async {
    // TODO: Initialize Midtrans SDK when ready
    _isInitialized = true;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Process payment for event ticket
  ///
  /// For V1: Always succeeds (mock payment)
  /// For V2: Integrate with real Midtrans SDK
  Future<PaymentResult> processPayment({
    required String eventId,
    required String userId,
    required String ticketId,
    required double amount,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
  }) async {
    if (!_isInitialized) {
      throw Exception('PaymentService not initialized. Call initialize() first.');
    }

    try {
      // Generate unique order ID
      final orderId = _generateOrderId();

      // TODO: Real Midtrans integration here
      // For now, simulate successful payment
      await Future.delayed(const Duration(milliseconds: 500));

      return PaymentResult(
        success: true,
        transactionId: orderId,
        message: 'Payment successful (mock)',
        status: TransactionStatus.completed,
        paymentType: 'mock',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment error: ${e.toString()}',
        status: TransactionStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// Process free ticket (no payment required)
  Future<PaymentResult> processFreeTicket({
    required String eventId,
    required String userId,
    required String ticketId,
  }) async {
    final orderId = _generateOrderId();

    return PaymentResult(
      success: true,
      transactionId: orderId,
      message: 'Free ticket reserved',
      status: TransactionStatus.completed,
      paymentType: 'free',
    );
  }

  /// Generate unique order ID
  String _generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4().split('-').first;
    return 'ANM-$timestamp-$uuid';
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}

/// Payment result wrapper
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String message;
  final TransactionStatus status;
  final String? paymentType;
  final Map<String, dynamic>? response;
  final String? error;

  const PaymentResult({
    required this.success,
    this.transactionId,
    required this.message,
    required this.status,
    this.paymentType,
    this.response,
    this.error,
  });

  @override
  String toString() {
    return 'PaymentResult(success: $success, transactionId: $transactionId, '
        'message: $message, status: $status)';
  }
}

/// Midtrans environment
enum MidtransEnvironment {
  sandbox,
  production,
}

/// Extension for MidtransEnvironment
extension MidtransEnvironmentExtension on MidtransEnvironment {
  String get baseUrl {
    switch (this) {
      case MidtransEnvironment.sandbox:
        return 'https://app.sandbox.midtrans.com';
      case MidtransEnvironment.production:
        return 'https://app.midtrans.com';
    }
  }
}
