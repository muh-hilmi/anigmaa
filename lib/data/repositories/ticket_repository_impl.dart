import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/failures.dart';
import '../../core/services/payment_service.dart';
import '../../core/utils/attendance_code_generator.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_transaction.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_local_datasource.dart';
import '../datasources/ticket_remote_datasource.dart';
import '../models/ticket_model.dart';
import '../models/ticket_transaction_model.dart';

/// Implementation of TicketRepository
///
/// Handles ticket purchases with Midtrans payment integration
class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;
  final TicketLocalDataSource localDataSource;
  final PaymentService paymentService;
  final Uuid uuid = const Uuid();

  TicketRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.paymentService,
  });

  @override
  Future<Either<Failure, Ticket>> purchaseTicket({
    required String userId,
    required String eventId,
    required double amount,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
  }) async {
    try {
      // Generate unique ticket ID and attendance code
      final ticketId = uuid.v4();
      final existingTickets = await localDataSource.getAllTickets();
      final existingCodes = existingTickets.map((t) => t.attendanceCode).toSet();
      final attendanceCode = AttendanceCodeGenerator.generateUnique(existingCodes);

      // Process payment
      final PaymentResult paymentResult;

      if (amount == 0) {
        // Free ticket
        paymentResult = await paymentService.processFreeTicket(
          eventId: eventId,
          userId: userId,
          ticketId: ticketId,
        );
      } else {
        // Paid ticket via Midtrans
        paymentResult = await paymentService.processPayment(
          eventId: eventId,
          userId: userId,
          ticketId: ticketId,
          amount: amount,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
        );
      }

      if (!paymentResult.success) {
        return Left(ServerFailure(paymentResult.message));
      }

      // Create ticket
      final ticket = TicketModel(
        id: ticketId,
        userId: userId,
        eventId: eventId,
        attendanceCode: attendanceCode,
        pricePaid: amount,
        purchasedAt: DateTime.now(),
      );

      // Save ticket
      await localDataSource.saveTicket(ticket);

      // Create transaction record
      final transaction = TicketTransactionModel(
        id: paymentResult.transactionId ?? uuid.v4(),
        ticketId: ticketId,
        userId: userId,
        eventId: eventId,
        amount: amount,
        status: _transactionStatusToString(paymentResult.status),
        paymentMethod: paymentResult.paymentType ?? 'free',
        paymentGatewayId: paymentResult.transactionId,
        paymentGatewayResponse: paymentResult.response?.toString(),
        createdAt: DateTime.now(),
        completedAt: paymentResult.success ? DateTime.now() : null,
      );

      await localDataSource.saveTransaction(transaction);

      return Right(ticket.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Ticket>>> getUserTickets(String userId) async {
    try {
      final tickets = await localDataSource.getUserTickets(userId);
      return Right(tickets.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to load data from cache'));
    }
  }

  @override
  Future<Either<Failure, List<Ticket>>> getEventTickets(String eventId) async {
    try {
      final tickets = await localDataSource.getEventTickets(eventId);
      return Right(tickets.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to load data from cache'));
    }
  }

  @override
  Future<Either<Failure, Ticket>> getTicketById(String ticketId) async {
    try {
      final ticket = await localDataSource.getTicketById(ticketId);
      if (ticket == null) {
        return Left(ServerFailure('Ticket not found'));
      }
      return Right(ticket.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load data from cache'));
    }
  }

  @override
  Future<Either<Failure, Ticket>> getTicketByCode(String attendanceCode) async {
    try {
      final normalizedCode = AttendanceCodeGenerator.normalize(attendanceCode);
      final ticket = await localDataSource.getTicketByCode(normalizedCode);

      if (ticket == null) {
        return Left(ServerFailure('Ticket not found'));
      }

      return Right(ticket.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load data from cache'));
    }
  }

  @override
  Future<Either<Failure, Ticket>> checkInTicket(String ticketId) async {
    try {
      final ticket = await localDataSource.getTicketById(ticketId);

      if (ticket == null) {
        return Left(ServerFailure('Ticket not found'));
      }

      if (ticket.isCheckedIn) {
        return Left(ServerFailure('Ticket already checked in'));
      }

      // Update ticket
      final updatedTicket = TicketModel(
        id: ticket.id,
        userId: ticket.userId,
        eventId: ticket.eventId,
        attendanceCode: ticket.attendanceCode,
        pricePaid: ticket.pricePaid,
        purchasedAt: ticket.purchasedAt,
        isCheckedIn: true,
        checkedInAt: DateTime.now(),
        status: ticket.status,
      );

      await localDataSource.updateTicket(updatedTicket);
      return Right(updatedTicket.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ticket>> cancelTicket(String ticketId) async {
    try {
      final ticket = await localDataSource.getTicketById(ticketId);

      if (ticket == null) {
        return Left(ServerFailure('Ticket not found'));
      }

      if (ticket.isCheckedIn) {
        return Left(ServerFailure('Cannot cancel checked-in ticket'));
      }

      // Update ticket status
      final updatedTicket = TicketModel(
        id: ticket.id,
        userId: ticket.userId,
        eventId: ticket.eventId,
        attendanceCode: ticket.attendanceCode,
        pricePaid: ticket.pricePaid,
        purchasedAt: ticket.purchasedAt,
        isCheckedIn: ticket.isCheckedIn,
        checkedInAt: ticket.checkedInAt,
        status: 'cancelled',
      );

      await localDataSource.updateTicket(updatedTicket);
      return Right(updatedTicket.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TicketTransaction>>> getUserTransactions(
    String userId,
  ) async {
    try {
      final transactions = await localDataSource.getUserTransactions(userId);
      return Right(transactions.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to load data from cache'));
    }
  }

  @override
  Future<Either<Failure, TicketTransaction>> getTransactionById(
    String transactionId,
  ) async {
    try {
      final transaction =
          await localDataSource.getTransactionById(transactionId);
      if (transaction == null) {
        return Left(ServerFailure('Transaction not found'));
      }
      return Right(transaction.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load data from cache'));
    }
  }

  /// Helper: Convert TransactionStatus to string
  String _transactionStatusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.completed:
        return 'completed';
      case TransactionStatus.failed:
        return 'failed';
      case TransactionStatus.cancelled:
        return 'cancelled';
      case TransactionStatus.refunded:
        return 'refunded';
    }
  }
}
