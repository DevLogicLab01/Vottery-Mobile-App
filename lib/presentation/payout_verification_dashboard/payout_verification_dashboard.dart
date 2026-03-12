import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/payout_verification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

class PayoutVerificationDashboardScreen extends StatefulWidget {
  const PayoutVerificationDashboardScreen({super.key});

  @override
  State<PayoutVerificationDashboardScreen> createState() =>
      _PayoutVerificationDashboardScreenState();
}

class _PayoutVerificationDashboardScreenState
    extends State<PayoutVerificationDashboardScreen> {
  final PayoutVerificationService _verificationService =
      PayoutVerificationService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};
  List<Map<String, dynamic>> _pendingVerifications = [];
  List<Map<String, dynamic>> _discrepancies = [];

  @override
  void initState() {
    super.initState();
    _loadVerificationData();
  }

  Future<void> _loadVerificationData() async {
    setState(() => _isLoading = true);

    try {
      final metrics = await _verificationService.getVerificationMetrics();
      final pending = await _verificationService.getPendingVerifications();
      final discrepancies = await _verificationService.getDiscrepancyQueue();

      setState(() {
        _metrics = metrics;
        _pendingVerifications = pending;
        _discrepancies = discrepancies;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load verification data error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'PayoutVerificationDashboard',
      onRetry: _loadVerificationData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Payout Verification',
          variant: CustomAppBarVariant.withBack,
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportReport,
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: _loadVerificationData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetricsSection(theme),
                      SizedBox(height: 3.h),
                      _buildPendingVerificationsSection(theme),
                      SizedBox(height: 3.h),
                      _buildDiscrepanciesSection(theme),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Container(
          height: 15.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          height: 30.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Metrics',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Total Settlements',
                '${_metrics['total_settlements_this_month'] ?? 0}',
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Verified',
                '${_metrics['verified_percentage'] ?? 0}%',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Pending',
                '${_metrics['pending_verification_count'] ?? 0}',
                Icons.pending,
                Colors.orange,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Discrepancies',
                '${_metrics['discrepancies_found'] ?? 0}',
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVerificationsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Verifications',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        if (_pendingVerifications.isEmpty)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Center(
              child: Text(
                'No pending verifications',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...List.generate(
            _pendingVerifications.length,
            (index) =>
                _buildVerificationCard(theme, _pendingVerifications[index]),
          ),
      ],
    );
  }

  Widget _buildVerificationCard(
    ThemeData theme,
    Map<String, dynamic> settlement,
  ) {
    final creator = settlement['user_profiles'] ?? {};
    final amount = (settlement['net_amount'] ?? 0.0) as double;
    final settlementId = settlement['settlement_id'] as String;
    final isPriority = amount > 10000;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isPriority ? Colors.red.withAlpha(128) : theme.dividerColor,
          width: isPriority ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator['full_name'] ?? 'Unknown Creator',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      creator['email'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPriority)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(51),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    'HIGH PRIORITY',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount: \$${amount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.vibrantYellow,
                ),
              ),
              Text(
                'ID: ${settlementId.substring(0, 8)}...',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _verifySettlement(settlementId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                  ),
                  child: Text(
                    'Verify',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _flagDiscrepancy(settlementId),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                  ),
                  child: Text(
                    'Flag Issue',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscrepanciesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Open Discrepancies',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        if (_discrepancies.isEmpty)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Center(
              child: Text(
                'No open discrepancies',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...List.generate(
            _discrepancies.length,
            (index) => _buildDiscrepancyCard(theme, _discrepancies[index]),
          ),
      ],
    );
  }

  Widget _buildDiscrepancyCard(
    ThemeData theme,
    Map<String, dynamic> discrepancy,
  ) {
    final amount = (discrepancy['discrepancy_amount'] ?? 0.0) as double;
    final type = discrepancy['discrepancy_type'] ?? 'unknown';
    final status = discrepancy['status'] ?? 'open';

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type.replaceAll('_', ' ').toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withAlpha(51),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            discrepancy['description'] ?? 'No description',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Amount: \$${amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'investigating':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'escalated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _verifySettlement(String settlementId) async {
    final success = await _verificationService.verifySettlement(settlementId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settlement verified successfully')),
      );
      _loadVerificationData();
    }
  }

  Future<void> _flagDiscrepancy(String settlementId) async {
    // Show dialog to collect discrepancy details
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DiscrepancyDialog(),
    );

    if (result != null) {
      final discrepancyId = await _verificationService.flagDiscrepancy(
        settlementId: settlementId,
        discrepancyType: result['type'],
        amount: result['amount'],
        description: result['description'],
      );

      if (discrepancyId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discrepancy flagged successfully')),
        );
        _loadVerificationData();
      }
    }
  }

  Future<void> _exportReport() async {
    try {
      final csv = await _verificationService.exportReconciliationReport();
      if (csv.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export report')),
        );
      }
    }
  }
}

class _DiscrepancyDialog extends StatefulWidget {
  @override
  State<_DiscrepancyDialog> createState() => _DiscrepancyDialogState();
}

class _DiscrepancyDialogState extends State<_DiscrepancyDialog> {
  String _selectedType = 'amount_mismatch';
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Flag Discrepancy'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            items: const [
              DropdownMenuItem(
                value: 'missing_transaction',
                child: Text('Missing Transaction'),
              ),
              DropdownMenuItem(
                value: 'amount_mismatch',
                child: Text('Amount Mismatch'),
              ),
              DropdownMenuItem(value: 'fee_error', child: Text('Fee Error')),
              DropdownMenuItem(
                value: 'currency_error',
                child: Text('Currency Error'),
              ),
              DropdownMenuItem(value: 'tax_error', child: Text('Tax Error')),
            ],
            onChanged: (value) => setState(() => _selectedType = value!),
            decoration: const InputDecoration(labelText: 'Discrepancy Type'),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'type': _selectedType,
              'amount': double.tryParse(_amountController.text) ?? 0.0,
              'description': _descriptionController.text,
            });
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
