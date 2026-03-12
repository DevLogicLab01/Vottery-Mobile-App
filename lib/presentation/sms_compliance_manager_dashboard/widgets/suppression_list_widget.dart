import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/sms_compliance_service.dart';
import '../../../theme/app_theme.dart';

class SuppressionListWidget extends StatefulWidget {
  const SuppressionListWidget({super.key});

  @override
  State<SuppressionListWidget> createState() => _SuppressionListWidgetState();
}

class _SuppressionListWidgetState extends State<SuppressionListWidget> {
  final SMSComplianceService _service = SMSComplianceService.instance;

  List<Map<String, dynamic>> _suppressions = [];
  bool _isLoading = true;
  String? _filterReason;

  @override
  void initState() {
    super.initState();
    _loadSuppressions();
  }

  Future<void> _loadSuppressions() async {
    setState(() => _isLoading = true);
    final suppressions = await _service.getSuppressionList(reason: _filterReason);
    if (mounted) {
      setState(() {
        _suppressions = suppressions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _suppressions.isEmpty
                  ? _buildEmptyState()
                  : _buildSuppressionList(),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppThemeColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _filterReason,
              decoration: InputDecoration(
                labelText: 'Filter by Reason',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                const DropdownMenuItem(value: 'opted_out', child: Text('Opted Out')),
                const DropdownMenuItem(value: 'bounced', child: Text('Bounced')),
                const DropdownMenuItem(value: 'invalid', child: Text('Invalid')),
                const DropdownMenuItem(value: 'spam_complaint', child: Text('Spam Complaint')),
              ],
              onChanged: (value) {
                setState(() => _filterReason = value);
                _loadSuppressions();
              },
            ),
          ),
          SizedBox(width: 2.w),
          IconButton(
            onPressed: _loadSuppressions,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 48.sp, color: AppTheme.textSecondary),
          SizedBox(height: 2.h),
          Text(
            'No suppressed numbers',
            style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppressionList() {
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _suppressions.length,
      itemBuilder: (context, index) {
        final suppression = _suppressions[index];
        return _buildSuppressionCard(suppression);
      },
    );
  }

  Widget _buildSuppressionCard(Map<String, dynamic> suppression) {
    final reason = suppression['suppression_reason'] as String;
    final phoneNumber = suppression['phone_number'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppThemeColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.block, color: Colors.red, size: 20.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  phoneNumber,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reason.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          if (suppression['notes'] != null) ...[
            SizedBox(height: 1.h),
            Text(
              suppression['notes'],
              style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondary),
            ),
          ],
          SizedBox(height: 1.h),
          ElevatedButton(
            onPressed: () => _removeFromSuppression(phoneNumber),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(double.infinity, 5.h),
            ),
            child: Text('Remove from Suppression', style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFromSuppression(String phoneNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Suppression'),
        content: Text('Remove $phoneNumber from suppression list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.removeFromSuppressionList(phoneNumber);
      _loadSuppressions();
    }
  }
}