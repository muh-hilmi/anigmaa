import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'all';

  // TODO: Replace with real data from BLoC/Repository
  final List<Transaction> _mockTransactions = [];

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    // Mock transactions for development
    _mockTransactions.addAll([
      Transaction(
        id: 'tx001',
        userId: 'user001',
        ticketId: 'ticket001',
        eventId: 'event001',
        eventName: 'Weekend Music Fest',
        amount: 150000,
        adminFee: 5000,
        status: TransactionStatus.success,
        paymentMethod: PaymentMethod.virtualAccount,
        virtualAccountNumber: '8770123456789',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        paidAt: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      ),
      Transaction(
        id: 'tx002',
        userId: 'user001',
        ticketId: 'ticket002',
        eventId: 'event002',
        eventName: 'Tech Conference 2025',
        amount: 300000,
        adminFee: 10000,
        status: TransactionStatus.success,
        paymentMethod: PaymentMethod.ewallet,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        paidAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Transaction(
        id: 'tx003',
        userId: 'user001',
        ticketId: 'ticket003',
        eventId: 'event003',
        eventName: 'Startup Meetup Jakarta',
        amount: 0,
        status: TransactionStatus.success,
        paymentMethod: PaymentMethod.free,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        paidAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Transaction(
        id: 'tx004',
        userId: 'user001',
        ticketId: 'ticket004',
        eventId: 'event004',
        eventName: 'Food Festival 2025',
        amount: 75000,
        adminFee: 3000,
        status: TransactionStatus.pending,
        paymentMethod: PaymentMethod.virtualAccount,
        virtualAccountNumber: '8770987654321',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiredAt: DateTime.now().add(const Duration(hours: 22)),
      ),
    ]);
  }

  List<Transaction> get _filteredTransactions {
    switch (_selectedFilter) {
      case 'success':
        return _mockTransactions.where((tx) => tx.status == TransactionStatus.success).toList();
      case 'pending':
        return _mockTransactions.where((tx) => tx.status == TransactionStatus.pending).toList();
      case 'failed':
        return _mockTransactions.where((tx) =>
          tx.status == TransactionStatus.failed ||
          tx.status == TransactionStatus.expired ||
          tx.status == TransactionStatus.cancelled
        ).toList();
      default:
        return _mockTransactions;
    }
  }

  double get _totalSpent {
    return _mockTransactions
        .where((tx) => tx.status == TransactionStatus.success)
        .fold(0.0, (sum, tx) => sum + tx.totalAmount);
  }

  int get _totalEvents {
    return _mockTransactions
        .where((tx) => tx.status == TransactionStatus.success)
        .length;
  }

  double get _thisMonthSpent {
    final now = DateTime.now();
    return _mockTransactions
        .where((tx) =>
          tx.status == TransactionStatus.success &&
          tx.paidAt != null &&
          tx.paidAt!.year == now.year &&
          tx.paidAt!.month == now.month
        )
        .fold(0.0, (sum, tx) => sum + tx.totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF000000),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF000000)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildFilterChips(),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredTransactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionCard(_filteredTransactions[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF84994F), Color(0xFF6B7F3F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Pengeluaran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${NumberFormat('#,###', 'id_ID').format(_totalSpent)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Acara',
                  _totalEvents.toString(),
                  Icons.event,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Bulan Ini',
                  'Rp ${NumberFormat('#,###', 'id_ID').format(_thisMonthSpent)}',
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Semua', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Sukses', 'success'),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip('Gagal', 'failed'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF84994F),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : Colors.grey[700],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF84994F) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to transaction detail
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Detail transaksi ${transaction.displayId} bentar lagi ya!'),
                backgroundColor: const Color(0xFF84994F),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatusIcon(transaction.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.eventName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF000000),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(transaction.createdAt)} • ${transaction.displayId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            transaction.paymentMethod.icon,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            transaction.paymentMethod.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      transaction.amount > 0
                          ? 'Rp ${NumberFormat('#,###', 'id_ID').format(transaction.totalAmount)}'
                          : 'GRATIS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: transaction.amount > 0
                            ? const Color(0xFF000000)
                            : const Color(0xFF84994F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildStatusBadge(transaction.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(TransactionStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case TransactionStatus.success:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case TransactionStatus.failed:
      case TransactionStatus.expired:
      case TransactionStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case TransactionStatus.refunded:
        icon = Icons.refresh;
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status) {
    Color color;

    switch (status) {
      case TransactionStatus.success:
        color = Colors.green;
        break;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        color = Colors.orange;
        break;
      case TransactionStatus.failed:
      case TransactionStatus.expired:
      case TransactionStatus.cancelled:
        color = Colors.red;
        break;
      case TransactionStatus.refunded:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi nih',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transaksi lo bakal muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }
}
