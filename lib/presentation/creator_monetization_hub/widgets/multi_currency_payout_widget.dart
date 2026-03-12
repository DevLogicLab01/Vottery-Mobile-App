import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class MultiCurrencyPayoutWidget extends StatelessWidget {
  final Map<String, dynamic> payoutSummary;
  final Map<String, double> exchangeRates;
  final Function(Map<String, dynamic>) onWithdrawalRequest;

  const MultiCurrencyPayoutWidget({
    super.key,
    required this.payoutSummary,
    required this.exchangeRates,
    required this.onWithdrawalRequest,
  });

  static const List<String> zones = [
    'US_Canada',
    'Western_Europe',
    'Eastern_Europe',
    'Africa',
    'Latin_America',
    'Middle_East_Asia',
    'Australasia',
    'China_Hong_Kong',
  ];

  @override
  Widget build(BuildContext context) {
    final totalPending = (payoutSummary['total_pending'] ?? 0.0) as num;
    final activeZones = payoutSummary['active_zones'] ?? 0;
    final nextSettlement = payoutSummary['next_settlement_date'] as String?;

    return SingleChildScrollView(
      padding: EdgeInsets.all(2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPayoutSummaryCard(
            totalPending.toDouble(),
            activeZones,
            nextSettlement,
          ),
          SizedBox(height: 3.h),
          Text(
            'Regional Zones',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ...zones.map((zone) => _buildZoneCard(zone)),
          SizedBox(height: 3.h),
          Text(
            'Live Exchange Rates',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildExchangeRatesCard(),
        ],
      ),
    );
  }

  Widget _buildPayoutSummaryCard(
    double totalPending,
    int activeZones,
    String? nextSettlement,
  ) {
    final currencyFormat = NumberFormat.currency(
      symbol: r'$',
      decimalDigits: 2,
    );

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Payouts',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    currencyFormat.format(totalPending),
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance,
                  color: Colors.white,
                  size: 6.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  'Active Zones',
                  activeZones.toString(),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildSummaryMetric(
                  'Next Settlement',
                  nextSettlement != null
                      ? DateFormat(
                          'MMM dd',
                        ).format(DateTime.parse(nextSettlement))
                      : 'N/A',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.white.withAlpha(230),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(String zone) {
    final zoneName = zone.replaceAll('_', ' ');

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(Icons.public, color: Colors.blue, size: 5.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              zoneName,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              'Active',
              style: TextStyle(
                fontSize: 8.sp,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRatesCard() {
    final currencies = ['EUR', 'GBP', 'JPY', 'CNY', 'AUD'];

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: currencies.map((currency) {
          final rate = exchangeRates[currency] ?? 1.0;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'USD/$currency',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  rate.toStringAsFixed(4),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
