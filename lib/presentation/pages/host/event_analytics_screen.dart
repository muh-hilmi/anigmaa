import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/analytics_model.dart';
import '../../../data/services/analytics_service.dart';
import '../../../injection_container.dart';
import 'package:fl_chart/fl_chart.dart';

class EventAnalyticsScreen extends StatefulWidget {
  final String eventId;

  const EventAnalyticsScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventAnalyticsScreen> createState() => _EventAnalyticsScreenState();
}

class _EventAnalyticsScreenState extends State<EventAnalyticsScreen> {
  final AnalyticsService _analyticsService = sl<AnalyticsService>();
  EventAnalyticsModel? _analytics;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final analytics =
          await _analyticsService.getEventAnalytics(widget.eventId);
      setState(() {
        _analytics = analytics;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Event 📊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/event-transactions',
                arguments: widget.eventId,
              );
            },
            tooltip: 'Lihat Transaksi',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _analytics == null
                  ? const Center(child: Text('Waduh... belum ada data nih 😅'))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEventHeader(),
                            const SizedBox(height: 24),
                            _buildRevenueCards(),
                            const SizedBox(height: 24),
                            _buildTransactionStats(),
                            const SizedBox(height: 24),
                            _buildAttendanceStats(),
                            const SizedBox(height: 24),
                            _buildPaymentMethods(),
                            const SizedBox(height: 24),
                            _buildSalesTimeline(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildEventHeader() {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _analytics!.eventTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(_analytics!.eventStatus.toUpperCase()),
                  backgroundColor: _getStatusColor(_analytics!.eventStatus),
                ),
                const SizedBox(width: 8),
                if (!_analytics!.isFree)
                  Chip(
                    label: Text(formatter.format(_analytics!.price)),
                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                  )
                else
                  const Chip(
                    label: Text('GRATIS'),
                    backgroundColor: Colors.blue,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${dateFormat.format(_analytics!.startTime)} - ${dateFormat.format(_analytics!.endTime)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue.withValues(alpha: 0.2);
      case 'ongoing':
        return Colors.green.withValues(alpha: 0.2);
      case 'completed':
        return Colors.grey.withValues(alpha: 0.2);
      case 'cancelled':
        return Colors.red.withValues(alpha: 0.2);
      default:
        return Colors.grey.withValues(alpha: 0.2);
    }
  }

  Widget _buildRevenueCards() {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildRevenueCard(
              'Total Revenue',
              formatter.format(_analytics!.revenue.totalRevenue),
              Colors.green,
              Icons.monetization_on,
            ),
            _buildRevenueCard(
              'Net Revenue',
              formatter.format(_analytics!.revenue.netRevenue),
              Colors.blue,
              Icons.account_balance_wallet,
            ),
            _buildRevenueCard(
              'Pending',
              formatter.format(_analytics!.revenue.pendingRevenue),
              Colors.orange,
              Icons.pending,
            ),
            _buildRevenueCard(
              'Refund',
              formatter.format(_analytics!.revenue.refundedRevenue),
              Colors.red,
              Icons.replay,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaksi 💳',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTransactionRow(
              'Total',
              _analytics!.transactions.totalTransactions,
              Colors.grey,
            ),
            _buildTransactionRow(
              'Sukses',
              _analytics!.transactions.successfulTransactions,
              Colors.green,
            ),
            _buildTransactionRow(
              'Pending',
              _analytics!.transactions.pendingTransactions,
              Colors.orange,
            ),
            _buildTransactionRow(
              'Gagal',
              _analytics!.transactions.failedTransactions,
              Colors.red,
            ),
            _buildTransactionRow(
              'Refund',
              _analytics!.transactions.refundedTransactions,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kehadiran 🎫',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_analytics!.ticketsSold} / ${_analytics!.maxAttendees}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Tiket Terjual'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _analytics!.attendanceRate / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      const SizedBox(height: 4),
                      Text('${_analytics!.attendanceRate.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_analytics!.ticketsCheckedIn} / ${_analytics!.ticketsSold}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Checked In'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _analytics!.checkInRate / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text('${_analytics!.checkInRate.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    if (_analytics!.paymentMethods.isEmpty) {
      return const SizedBox();
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._analytics!.paymentMethods.map((method) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.primaries[
                      method.method.hashCode % Colors.primaries.length],
                  child: Text(
                    method.count.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  method.method.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(formatter.format(method.totalAmount)),
                trailing: Text(
                  '${method.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTimeline() {
    if (_analytics!.timelineStats.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 &&
                              index < _analytics!.timelineStats.length) {
                            final date = _analytics!.timelineStats[index].date;
                            return Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: _analytics!.timelineStats.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.ticketsSold.toDouble(),
                          color: Colors.blue,
                          width: 16,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
