import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/sms_alerts_service.dart';

class CostTrackingWidget extends StatefulWidget {
  final Map<String, dynamic> costAnalytics;

  const CostTrackingWidget({super.key, required this.costAnalytics});

  @override
  State<CostTrackingWidget> createState() => _CostTrackingWidgetState();
}

class _CostTrackingWidgetState extends State<CostTrackingWidget> {
  List<Map<String, dynamic>> _costTracking = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCostTracking();
  }

  Future<void> _loadCostTracking() async {
    setState(() => _isLoading = true);

    try {
      final tracking = await SmsAlertsService.instance.getCostTracking();

      if (mounted) {
        setState(() {
          _costTracking = tracking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalBudget = widget.costAnalytics['total_budget'] ?? '0.00';
    final totalSpend = widget.costAnalytics['total_spend'] ?? '0.00';
    final totalMessages = widget.costAnalytics['total_messages'] ?? 0;
    final budgetUsed = widget.costAnalytics['budget_used_percentage'] ?? '0.0';

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall budget summary
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withAlpha(179),
                ],
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                Text(
                  'Total Budget Overview',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBudgetMetric(
                      'Budget',
                      '\$$totalBudget',
                      Icons.account_balance_wallet,
                    ),
                    _buildBudgetMetric(
                      'Spent',
                      '\$$totalSpend',
                      Icons.money_off,
                    ),
                    _buildBudgetMetric(
                      'Messages',
                      '$totalMessages',
                      Icons.message,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                LinearProgressIndicator(
                  value: double.tryParse(budgetUsed) != null
                      ? double.parse(budgetUsed) / 100
                      : 0,
                  backgroundColor: Colors.white.withAlpha(77),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    double.tryParse(budgetUsed) != null &&
                            double.parse(budgetUsed) > 80
                        ? Colors.red
                        : Colors.green,
                  ),
                  minHeight: 1.h,
                ),
                SizedBox(height: 1.h),
                Text(
                  '$budgetUsed% Budget Used',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Zone breakdown
          Text(
            'Cost by Zone (8 Purchasing Power Zones)',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),

          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _costTracking.isEmpty
              ? Center(
                  child: Text(
                    'No cost tracking data available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _costTracking.length,
                  itemBuilder: (context, index) {
                    final zone = _costTracking[index];
                    final zoneName = zone['zone_name'] ?? '';
                    final countryCode = zone['country_code'] ?? '';
                    final costPerSms = zone['cost_per_sms'] ?? 0;
                    final monthlyBudget = zone['monthly_budget'] ?? 0;
                    final currentSpend = zone['current_spend'] ?? 0;
                    final messageCount = zone['message_count'] ?? 0;

                    final budgetPercentage = monthlyBudget > 0
                        ? (currentSpend / monthlyBudget * 100)
                        : 0.0;

                    Color progressColor;
                    if (budgetPercentage >= 90) {
                      progressColor = Colors.red;
                    } else if (budgetPercentage >= 70) {
                      progressColor = Colors.orange;
                    } else {
                      progressColor = Colors.green;
                    }

                    return Card(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        zoneName,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        'Code: $countryCode',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.w,
                                    vertical: 0.5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: progressColor.withAlpha(51),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    '${budgetPercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: progressColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildZoneMetric(
                                  'Cost/SMS',
                                  '\$${costPerSms.toStringAsFixed(4)}',
                                ),
                                _buildZoneMetric('Messages', '$messageCount'),
                                _buildZoneMetric(
                                  'Spent',
                                  '\$${currentSpend.toStringAsFixed(2)}',
                                ),
                                _buildZoneMetric(
                                  'Budget',
                                  '\$${monthlyBudget.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            LinearProgressIndicator(
                              value: budgetPercentage / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progressColor,
                              ),
                              minHeight: 0.8.h,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildBudgetMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.white.withAlpha(230)),
        ),
      ],
    );
  }

  Widget _buildZoneMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
