import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/reconciliation_service.dart';

class DiscrepancyAlertWidget extends StatefulWidget {
  final List<Map<String, dynamic>> discrepancies;
  final VoidCallback onRefresh;

  const DiscrepancyAlertWidget({
    super.key,
    required this.discrepancies,
    required this.onRefresh,
  });

  @override
  State<DiscrepancyAlertWidget> createState() => _DiscrepancyAlertWidgetState();
}

class _DiscrepancyAlertWidgetState extends State<DiscrepancyAlertWidget> {
  String _severityFilter = 'all';
  String _statusFilter = 'all';

  List<Map<String, dynamic>> get _filteredDiscrepancies {
    return widget.discrepancies.where((d) {
      final severityMatch =
          _severityFilter == 'all' || d['severity'] == _severityFilter;
      final statusMatch =
          _statusFilter == 'all' || d['status'] == _statusFilter;
      return severityMatch && statusMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Filters
        Container(
          padding: EdgeInsets.all(3.w),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _severityFilter,
                  decoration: InputDecoration(
                    labelText: 'Severity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                  ),
                  items: ['all', 'minor', 'major', 'critical']
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _severityFilter = value);
                  },
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                  ),
                  items: ['all', 'unresolved', 'investigating', 'resolved']
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _statusFilter = value);
                  },
                ),
              ),
            ],
          ),
        ),

        // Discrepancy list
        Expanded(
          child: _filteredDiscrepancies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20.sp,
                        color: Colors.green,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No discrepancies found',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(3.w),
                  itemCount: _filteredDiscrepancies.length,
                  itemBuilder: (context, index) {
                    final discrepancy = _filteredDiscrepancies[index];
                    return _buildDiscrepancyCard(discrepancy, theme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDiscrepancyCard(
    Map<String, dynamic> discrepancy,
    ThemeData theme,
  ) {
    final severity = discrepancy['severity'] as String;
    final status = discrepancy['status'] as String;

    Color severityColor;
    switch (severity) {
      case 'minor':
        severityColor = Colors.yellow[700]!;
        break;
      case 'major':
        severityColor = Colors.orange;
        break;
      case 'critical':
        severityColor = Colors.red;
        break;
      default:
        severityColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => _showDiscrepancyDetails(discrepancy),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      severity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'resolved'
                          ? Colors.green.withAlpha(51)
                          : Colors.grey.withAlpha(51),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: status == 'resolved'
                            ? Colors.green
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    discrepancy['reconciliation_date'] ?? '',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '\$${discrepancy['expected_amount']}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actual',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '\$${discrepancy['actual_amount']}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discrepancy',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '\$${discrepancy['discrepancy_amount']}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (status != 'resolved') ...[
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _resolveDiscrepancy(discrepancy),
                        icon: Icon(Icons.check, size: 14.sp),
                        label: Text(
                          'Resolve',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _escalateDiscrepancy(discrepancy),
                        icon: Icon(Icons.arrow_upward, size: 14.sp),
                        label: Text(
                          'Escalate',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDiscrepancyDetails(Map<String, dynamic> discrepancy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discrepancy Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Date',
                discrepancy['reconciliation_date'] ?? 'N/A',
              ),
              _buildDetailRow(
                'Expected Amount',
                '\$${discrepancy['expected_amount']}',
              ),
              _buildDetailRow(
                'Actual Amount',
                '\$${discrepancy['actual_amount']}',
              ),
              _buildDetailRow(
                'Discrepancy',
                '\$${discrepancy['discrepancy_amount']}',
              ),
              _buildDetailRow('Severity', discrepancy['severity'] ?? 'N/A'),
              _buildDetailRow('Status', discrepancy['status'] ?? 'N/A'),
              if (discrepancy['root_cause'] != null)
                _buildDetailRow('Root Cause', discrepancy['root_cause']),
              if (discrepancy['resolution_notes'] != null)
                _buildDetailRow(
                  'Resolution Notes',
                  discrepancy['resolution_notes'],
                ),
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
          SizedBox(
            width: 30.w,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.sp),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 11.sp)),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveDiscrepancy(Map<String, dynamic> discrepancy) async {
    final rootCauseController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resolve Discrepancy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Root Cause'),
              items:
                  [
                        'timing_delay',
                        'webhook_miss',
                        'database_inconsistency',
                        'fraud_refund',
                      ]
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.replaceAll('_', ' ').toUpperCase()),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) rootCauseController.text = value;
              },
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Resolution Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Resolve'),
          ),
        ],
      ),
    );

    if (result == true && rootCauseController.text.isNotEmpty) {
      // Use reportDiscrepancy to update the status since resolveDiscrepancy doesn't exist
      final success = await ReconciliationService.instance.reportDiscrepancy(
        transactionId: discrepancy['id'],
        discrepancyReason:
            'Resolved: ${rootCauseController.text} - ${notesController.text}',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Discrepancy resolved successfully')),
        );
        widget.onRefresh();
      }
    }
  }

  Future<void> _escalateDiscrepancy(Map<String, dynamic> discrepancy) async {
    // Use reportDiscrepancy to update the status since escalateDiscrepancy doesn't exist
    final success = await ReconciliationService.instance.reportDiscrepancy(
      transactionId: discrepancy['id'],
      discrepancyReason: 'Escalated for investigation',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Discrepancy escalated for investigation')),
      );
      widget.onRefresh();
    }
  }
}
