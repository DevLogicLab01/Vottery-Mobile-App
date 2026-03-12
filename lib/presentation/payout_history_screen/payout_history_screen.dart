import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/app_export.dart';
import '../../services/settlement_service.dart';
import '../../theme/app_theme.dart';
import './widgets/payout_card_widget.dart';
import './widgets/payout_filter_widget.dart';

class PayoutHistoryScreen extends StatefulWidget {
  const PayoutHistoryScreen({super.key});

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  final SettlementService _settlementService = SettlementService.instance;

  bool _isLoading = true;
  bool _showCalendar = false;
  List<Map<String, dynamic>> _payouts = [];
  List<Map<String, dynamic>> _filteredPayouts = [];
  String _statusFilter = 'all';
  String _currencyFilter = 'all';
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadPayouts();
  }

  Future<void> _loadPayouts() async {
    setState(() => _isLoading = true);

    try {
      final payouts = await _settlementService.getSettlementHistory();

      setState(() {
        _payouts = payouts;
        _filteredPayouts = payouts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPayouts = _payouts.where((payout) {
        final statusMatch =
            _statusFilter == 'all' || payout['status'] == _statusFilter;
        final currencyMatch =
            _currencyFilter == 'all' || payout['currency'] == _currencyFilter;
        return statusMatch && currencyMatch;
      }).toList();
    });
  }

  void _exportToCSV() {
    // Export functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exporting to CSV...')));
  }

  List<Map<String, dynamic>> _getPayoutsForDay(DateTime day) {
    return _payouts.where((payout) {
      final payoutDate = DateTime.parse(payout['created_at']);
      return payoutDate.year == day.year &&
          payoutDate.month == day.month &&
          payoutDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payout History',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showCalendar ? Icons.list : Icons.calendar_today,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _showCalendar = !_showCalendar);
            },
          ),
          IconButton(
            icon: Icon(Icons.file_download, color: Colors.white),
            onPressed: _exportToCSV,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters
                PayoutFilterWidget(
                  statusFilter: _statusFilter,
                  currencyFilter: _currencyFilter,
                  onStatusChanged: (value) {
                    setState(() => _statusFilter = value);
                    _applyFilters();
                  },
                  onCurrencyChanged: (value) {
                    setState(() => _currencyFilter = value);
                    _applyFilters();
                  },
                ),

                // Content
                Expanded(
                  child: _showCalendar
                      ? _buildCalendarView()
                      : _buildListView(),
                ),
              ],
            ),
    );
  }

  Widget _buildListView() {
    if (_filteredPayouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 20.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No payouts found',
              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _filteredPayouts.length,
      itemBuilder: (context, index) {
        return PayoutCardWidget(
          payout: _filteredPayouts[index],
          onTap: () => _showPayoutDetails(_filteredPayouts[index]),
        );
      },
    );
  }

  Widget _buildCalendarView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getPayoutsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Payouts for selected day
          if (_selectedDay != null) ...[
            Text(
              'Payouts on ${_selectedDay!.toString().split(' ')[0]}',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            ..._getPayoutsForDay(_selectedDay!).map(
              (payout) => PayoutCardWidget(
                payout: payout,
                onTap: () => _showPayoutDetails(payout),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPayoutDetails(Map<String, dynamic> payout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payout Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Amount',
                '${payout['currency']} ${payout['net_amount']}',
              ),
              _buildDetailRow('Status', payout['status']),
              _buildDetailRow('Scheduled', payout['created_at']),
              if (payout['stripe_transfer_id'] != null)
                _buildDetailRow('Transfer ID', payout['stripe_transfer_id']),
              if (payout['tax_withheld'] != null && payout['tax_withheld'] > 0)
                _buildDetailRow('Tax Withheld', '\$${payout['tax_withheld']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
