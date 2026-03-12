import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/sms_alerts_service.dart';
import 'package:fl_chart/fl_chart.dart';

class DeliveryAnalyticsWidget extends StatefulWidget {
  final Map<String, dynamic> analytics;

  const DeliveryAnalyticsWidget({super.key, required this.analytics});

  @override
  State<DeliveryAnalyticsWidget> createState() =>
      _DeliveryAnalyticsWidgetState();
}

class _DeliveryAnalyticsWidgetState extends State<DeliveryAnalyticsWidget> {
  List<Map<String, dynamic>> _deliveryHistory = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadDeliveryHistory();
  }

  Future<void> _loadDeliveryHistory() async {
    setState(() => _isLoading = true);

    try {
      final history = await SmsAlertsService.instance.getDeliveryHistory(
        deliveryStatus: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _deliveryHistory = history;
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
    final total = widget.analytics['total'] ?? 0;
    final delivered = widget.analytics['delivered'] ?? 0;
    final failed = widget.analytics['failed'] ?? 0;
    final pending = widget.analytics['pending'] ?? 0;
    final read = widget.analytics['read'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Success Rate',
                  '${widget.analytics['success_rate'] ?? '0.0'}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildSummaryCard(
                  'Total Sent',
                  '$total',
                  Icons.send,
                  Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Pie chart
          Text(
            'Delivery Status Distribution',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 30.h,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: total > 0
                ? PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: delivered.toDouble(),
                          title: '$delivered',
                          color: Colors.green,
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: read.toDouble(),
                          title: '$read',
                          color: Colors.blue,
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: pending.toDouble(),
                          title: '$pending',
                          color: Colors.orange,
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: failed.toDouble(),
                          title: '$failed',
                          color: Colors.red,
                          radius: 50,
                          titleStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  )
                : Center(
                    child: Text(
                      'No delivery data available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
          ),
          SizedBox(height: 2.h),

          // Legend
          Wrap(
            spacing: 3.w,
            runSpacing: 1.h,
            children: [
              _buildLegendItem('Delivered', Colors.green, delivered),
              _buildLegendItem('Read', Colors.blue, read),
              _buildLegendItem('Pending', Colors.orange, pending),
              _buildLegendItem('Failed', Colors.red, failed),
            ],
          ),
          SizedBox(height: 3.h),

          // Filter chips
          Text(
            'Delivery History',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            children: [
              _buildFilterChip('all', 'All'),
              _buildFilterChip('delivered', 'Delivered'),
              _buildFilterChip('failed', 'Failed'),
              _buildFilterChip('pending', 'Pending'),
            ],
          ),
          SizedBox(height: 2.h),

          // Delivery history list
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _deliveryHistory.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Text(
                      'No delivery history found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _deliveryHistory.length,
                  itemBuilder: (context, index) {
                    final delivery = _deliveryHistory[index];
                    final status = delivery['delivery_status'] ?? 'pending';

                    Color statusColor;
                    IconData statusIcon;
                    switch (status) {
                      case 'delivered':
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                        break;
                      case 'read':
                        statusColor = Colors.blue;
                        statusIcon = Icons.mark_email_read;
                        break;
                      case 'failed':
                        statusColor = Colors.red;
                        statusIcon = Icons.error;
                        break;
                      default:
                        statusColor = Colors.orange;
                        statusIcon = Icons.schedule;
                    }

                    return Card(
                      margin: EdgeInsets.only(bottom: 1.h),
                      child: ListTile(
                        leading: Icon(statusIcon, color: statusColor),
                        title: Text(
                          delivery['phone_number'] ?? '',
                          style: TextStyle(fontSize: 13.sp),
                        ),
                        subtitle: Text(
                          delivery['message_content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.sp),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 1.w),
        Text('$label ($count)', style: TextStyle(fontSize: 11.sp)),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = value);
          _loadDeliveryHistory();
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary.withAlpha(51),
      labelStyle: TextStyle(
        fontSize: 11.sp,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
