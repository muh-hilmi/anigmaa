import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'all';
  String _selectedEventFilter = 'all';
  late TabController _tabController;

  // TODO: Replace with real data from BLoC/Repository
  final List<Transaction> _mockTransactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeMockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeMockData() {
    // Mock transactions as event organizer (incoming revenue from ticket sales)
    _mockTransactions.addAll([
      // Weekend Music Fest - Your Event
      Transaction(
        id: 'tx001',
        userId: 'user123',
        ticketId: 'ticket001',
        eventId: 'event001',
        eventName: 'Weekend Music Fest',
        amount: 150000,
        adminFee: 15000, // 10% platform fee
        status: TransactionStatus.success,
        paymentMethod: PaymentMethod.virtualAccount,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        paidAt: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      ),
      Transaction(
        id: 'tx002',
        userId: 'user456',
        ticketId: 'ticket002',
        eventId: 'event001',
        eventName: 'Weekend Music Fest',
        amount: 150000,
        adminFee: 15000,
        status: TransactionStatus.success,
        paymentMethod: PaymentMethod.ewallet,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        paidAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Transaction(
        id: 'tx003',
        userId: 'user789',
        ticketId: 'ticket003',
        eventId: 'event001',
        eventName: 'Weekend Music Fest',
        amount: 150000,
        adminFee: 15000,
        status: TransactionStatus.pending,
        paymentMethod: PaymentMethod.virtualAccount,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        expiredAt: DateTime.now().add(const Duration(hours: 19)),
      ),

      // Tech Conference 2025 - Your Event
      Transaction(
        id: 'tx004',
        userId: 'user111',
        ticketId: 'ticket004',
        eventId: 'event002',
        eventName: 'Tech Conference 2025',
        amount: 300000,
        adminFee: 30000,
        status: TransactionStatus.success,
        paymentMethod: PaymentMethod.creditCard,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        paidAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Transaction(
        id: 'tx005',
        userId: 'user222',
        ticketId: 'ticket005',
        eventId: 'event002',
        eventName: 'Tech Conference 2025',
        amount: 300000,
        adminFee: 30000,
        status: TransactionStatus.success,
        paymentMethod: PaymentMethod.virtualAccount,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        paidAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      Transaction(
        id: 'tx006',
        userId: 'user333',
        ticketId: 'ticket006',
        eventId: 'event002',
        eventName: 'Tech Conference 2025',
        amount: 300000,
        adminFee: 30000,
        status: TransactionStatus.success,
        paymentMethod: PaymentMethod.ewallet,
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
        paidAt: DateTime.now().subtract(const Duration(days: 9)),
      ),
      Transaction(
        id: 'tx007',
        userId: 'user444',
        ticketId: 'ticket007',
        eventId: 'event002',
        eventName: 'Tech Conference 2025',
        amount: 300000,
        adminFee: 30000,
        status: TransactionStatus.failed,
        paymentMethod: PaymentMethod.virtualAccount,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),

      // Food Festival 2025 - Your Event
      Transaction(
        id: 'tx008',
        userId: 'user555',
        ticketId: 'ticket008',
        eventId: 'event003',
        eventName: 'Food Festival 2025',
        amount: 75000,
        adminFee: 7500,
        status: TransactionStatus.success,
        paymentMethod: PaymentMethod.ewallet,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        paidAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      Transaction(
        id: 'tx009',
        userId: 'user666',
        ticketId: 'ticket009',
        eventId: 'event003',
        eventName: 'Food Festival 2025',
        amount: 75000,
        adminFee: 7500,
        status: TransactionStatus.processing,
        paymentMethod: PaymentMethod.virtualAccount,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ]);
  }

  List<Transaction> get _filteredTransactions {
    var transactions = _mockTransactions;

    // Filter by event
    if (_selectedEventFilter != 'all') {
      transactions = transactions.where((tx) => tx.eventId == _selectedEventFilter).toList();
    }

    // Filter by status
    switch (_selectedFilter) {
      case 'success':
        return transactions.where((tx) => tx.status == TransactionStatus.success).toList();
      case 'pending':
        return transactions.where((tx) =>
          tx.status == TransactionStatus.pending ||
          tx.status == TransactionStatus.processing
        ).toList();
      case 'failed':
        return transactions.where((tx) =>
          tx.status == TransactionStatus.failed ||
          tx.status == TransactionStatus.expired ||
          tx.status == TransactionStatus.cancelled
        ).toList();
      default:
        return transactions;
    }
  }

  // Total revenue earned (after platform fee deduction)
  double get _totalRevenue {
    return _mockTransactions
        .where((tx) => tx.status == TransactionStatus.success)
        .fold(0.0, (sum, tx) => sum + (tx.amount - tx.adminFee));
  }

  // Gross revenue (before platform fee)
  double get _grossRevenue {
    return _mockTransactions
        .where((tx) => tx.status == TransactionStatus.success)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // Total platform fees
  double get _totalFees {
    return _mockTransactions
        .where((tx) => tx.status == TransactionStatus.success)
        .fold(0.0, (sum, tx) => sum + tx.adminFee);
  }

  // Total tickets sold
  int get _totalTicketsSold {
    return _mockTransactions
        .where((tx) => tx.status == TransactionStatus.success)
        .length;
  }

  // Total pending transactions
  int get _pendingCount {
    return _mockTransactions
        .where((tx) =>
          tx.status == TransactionStatus.pending ||
          tx.status == TransactionStatus.processing
        )
        .length;
  }

  // This month revenue
  double get _thisMonthRevenue {
    final now = DateTime.now();
    return _mockTransactions
        .where((tx) =>
          tx.status == TransactionStatus.success &&
          tx.paidAt != null &&
          tx.paidAt!.year == now.year &&
          tx.paidAt!.month == now.month
        )
        .fold(0.0, (sum, tx) => sum + (tx.amount - tx.adminFee));
  }

  // Unique events with transactions
  List<String> get _uniqueEvents {
    return _mockTransactions.map((tx) => tx.eventId).toSet().toList();
  }

  // Get event name by ID
  String _getEventName(String eventId) {
    final tx = _mockTransactions.firstWhere((tx) => tx.eventId == eventId);
    return tx.eventName;
  }

  // Get stats by event
  Map<String, dynamic> _getEventStats(String eventId) {
    final eventTransactions = _mockTransactions.where((tx) => tx.eventId == eventId).toList();
    final successTransactions = eventTransactions.where((tx) => tx.status == TransactionStatus.success).toList();

    return {
      'revenue': successTransactions.fold<double>(0.0, (sum, tx) => sum + (tx.amount - tx.adminFee)),
      'gross': successTransactions.fold<double>(0.0, (sum, tx) => sum + tx.amount),
      'ticketsSold': successTransactions.length,
      'pending': eventTransactions.where((tx) =>
        tx.status == TransactionStatus.pending ||
        tx.status == TransactionStatus.processing
      ).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Keuangan Event',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF000000)),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF84994F),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF84994F),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Per Event'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPerEventTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildRevenueCard(),
        const SizedBox(height: 12),
        _buildStatsGrid(),
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
    );
  }

  Widget _buildPerEventTab() {
    if (_uniqueEvents.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _uniqueEvents.length,
      itemBuilder: (context, index) {
        final eventId = _uniqueEvents[index];
        return _buildEventCard(eventId);
      },
    );
  }

  Widget _buildRevenueCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pendapatan Bersih',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Siap Tarik',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${NumberFormat('#,###', 'id_ID').format(_totalRevenue)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dari Rp ${NumberFormat('#,###', 'id_ID').format(_grossRevenue)} (Fee: Rp ${NumberFormat('#,###', 'id_ID').format(_totalFees)})',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _totalRevenue > 0 ? () {
                _showWithdrawalDialog(context);
              } : null,
              icon: const Icon(Icons.account_balance_wallet, size: 18),
              label: const Text('Tarik Dana'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF84994F),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.white60,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Tiket Terjual',
              _totalTicketsSold.toString(),
              Icons.confirmation_number_outlined,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending',
              _pendingCount.toString(),
              Icons.schedule,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Bulan Ini',
              'Rp ${NumberFormat.compact(locale: 'id_ID').format(_thisMonthRevenue)}',
              Icons.calendar_today,
              const Color(0xFF84994F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(String eventId) {
    final stats = _getEventStats(eventId);
    final eventName = _getEventName(eventId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF84994F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event,
                  color: Color(0xFF84994F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventName,
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
                      '${stats['ticketsSold']} tiket terjual',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedEventFilter = eventId;
                    _tabController.animateTo(0); // Go to overview tab
                  });
                },
                child: const Text('Lihat →'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendapatan Bersih',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(stats['revenue'])}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF84994F),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[200],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Kotor',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(stats['gross'])}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (stats['pending'] > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '${stats['pending']} transaksi pending',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedEventFilter != 'all') ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF84994F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: Color(0xFF84994F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filter: ${_getEventName(_selectedEventFilter)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF84994F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedEventFilter = 'all';
                      });
                    },
                    child: const Icon(Icons.close, size: 18, color: Color(0xFF84994F)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SingleChildScrollView(
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
        ),
      ],
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
    final netRevenue = transaction.amount - transaction.adminFee;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                              ? '+Rp ${NumberFormat('#,###', 'id_ID').format(netRevenue)}'
                              : 'GRATIS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: transaction.status == TransactionStatus.success
                                ? const Color(0xFF84994F)
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildStatusBadge(transaction.status),
                      ],
                    ),
                  ],
                ),
                if (transaction.amount > 0 && transaction.adminFee > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Harga tiket: Rp ${NumberFormat('#,###', 'id_ID').format(transaction.amount)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' • Fee: Rp ${NumberFormat('#,###', 'id_ID').format(transaction.adminFee)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF84994F)),
            SizedBox(width: 8),
            Text(
              'Info Keuangan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Halaman ini menampilkan pendapatan dari event yang lo buat sebagai organizer.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              '💰 Pendapatan Bersih',
              'Uang yang bisa lo tarik setelah dipotong fee platform (10%)',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              '💵 Total Kotor',
              'Harga tiket sebelum dipotong fee platform',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              '🎫 Tiket Terjual',
              'Jumlah tiket yang berhasil terbeli (status sukses)',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              '⏳ Pending',
              'Transaksi yang menunggu pembayaran atau sedang diproses',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF84994F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Dana bisa ditarik setelah event selesai atau mencapai minimum penarikan.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF84994F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF000000),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  void _showWithdrawalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Tarik Dana',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF84994F), Color(0xFF6B7F3F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo Tersedia',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${NumberFormat('#,###', 'id_ID').format(_totalRevenue)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fitur penarikan dana lagi dalam tahap pengembangan. Dana akan ditransfer ke rekening bank yang terdaftar.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Minimal penarikan: Rp 50.000\nProses 1-3 hari kerja',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur penarikan dana coming soon!'),
                  backgroundColor: Color(0xFF84994F),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84994F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Tarik Dana'),
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
