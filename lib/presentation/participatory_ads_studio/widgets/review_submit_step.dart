import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import './ad_format_selection_step.dart';

class ReviewSubmitStep extends StatelessWidget {
  final String campaignName;
  final String description;
  final String imageUrl;
  final AdFormatType? selectedFormat;
  final List<int> targetZones;
  final List<String> tags;
  final Map<int, Map<String, double>> budgetByZone;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final void Function(int step) onEditStep;

  const ReviewSubmitStep({
    super.key,
    required this.campaignName,
    required this.description,
    required this.imageUrl,
    required this.selectedFormat,
    required this.targetZones,
    required this.tags,
    required this.budgetByZone,
    required this.onSubmit,
    required this.isSubmitting,
    required this.onEditStep,
  });

  double get _totalBudget {
    return budgetByZone.values.fold(
      0.0,
      (sum, z) => sum + (z['budget'] ?? 0.0),
    );
  }

  String _formatTypeName(AdFormatType? type) {
    switch (type) {
      case AdFormatType.marketResearch:
        return '📊 Market Research';
      case AdFormatType.hypePrediction:
        return '🔥 Hype Prediction';
      case AdFormatType.csrVote:
        return '🌱 CSR Vote';
      default:
        return 'Not selected';
    }
  }

  String _getZoneName(int zone) {
    const names = {
      1: 'US & Canada',
      2: 'Western Europe',
      3: 'Eastern Europe',
      4: 'Africa',
      5: 'Latin America',
      6: 'Middle East & Asia',
      7: 'Australasia',
      8: 'China & HK',
    };
    return names[zone] ?? 'Zone $zone';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Submit',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Review your campaign before submitting',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          // Basic Info Section
          _buildSection(
            context,
            title: 'Basic Info',
            stepIndex: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewRow(
                  'Campaign Name',
                  campaignName.isEmpty ? 'Not set' : campaignName,
                ),
                if (description.isNotEmpty)
                  _reviewRow('Description', description),
                if (imageUrl.isNotEmpty) _reviewRow('Image', 'Uploaded ✓'),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          // Ad Format Section
          _buildSection(
            context,
            title: 'Ad Format',
            stepIndex: 1,
            child: _reviewRow('Format', _formatTypeName(selectedFormat)),
          ),
          SizedBox(height: 1.5.h),
          // Targeting Section
          _buildSection(
            context,
            title: 'Audience Targeting',
            stepIndex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewRow(
                  'Zones',
                  targetZones.isEmpty
                      ? 'None selected'
                      : targetZones.map((z) => 'Zone $z').join(', '),
                ),
                if (tags.isNotEmpty) _reviewRow('Tags', tags.join(', ')),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          // Budget Section
          _buildSection(
            context,
            title: 'Budget',
            stepIndex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...budgetByZone.entries.map(
                  (e) => _reviewRow(
                    _getZoneName(e.key),
                    '\$${e.value['budget']?.toStringAsFixed(2) ?? '0.00'} (CPE: \$${e.value['cpe']?.toStringAsFixed(2) ?? '0.50'})',
                  ),
                ),
                Divider(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Budget',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '\$${_totalBudget.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit Campaign',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required int stepIndex,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              TextButton(
                onPressed: () => onEditStep(stepIndex),
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 1.5.h),
          child,
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
