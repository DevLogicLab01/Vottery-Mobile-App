import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/revenue_share_service.dart';

class AISplitRecommendationWidget extends StatefulWidget {
  final List<Map<String, dynamic>> revenueSplits;
  final VoidCallback onApply;

  const AISplitRecommendationWidget({
    super.key,
    required this.revenueSplits,
    required this.onApply,
  });

  @override
  State<AISplitRecommendationWidget> createState() =>
      _AISplitRecommendationWidgetState();
}

class _AISplitRecommendationWidgetState
    extends State<AISplitRecommendationWidget> {
  final RevenueShareService _revenueService = RevenueShareService.instance;
  String? _selectedCountryCode;
  Map<String, dynamic>? _recommendation;
  bool _isLoading = false;

  Future<void> _getRecommendation(String countryCode) async {
    setState(() => _isLoading = true);

    final recommendation = await _revenueService.getAISplitRecommendation(
      countryCode: countryCode,
    );

    if (mounted) {
      setState(() {
        _recommendation = recommendation;
        _isLoading = false;
      });
    }
  }

  Future<void> _applyRecommendation() async {
    if (_recommendation == null || _selectedCountryCode == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply AI Recommendation'),
        content: Text(
          'Apply recommended split of ${_recommendation!['recommended_platform_percentage']}% / ${_recommendation!['recommended_creator_percentage']}% to $_selectedCountryCode?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _revenueService.updateRevenueSplit(
        countryCode: _selectedCountryCode!,
        platformPercentage: _recommendation!['recommended_platform_percentage'],
        creatorPercentage: _recommendation!['recommended_creator_percentage'],
        changeReason: 'Applied Claude AI recommendation',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Recommendation applied successfully'
                  : 'Failed to apply recommendation',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) widget.onApply();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple, size: 24.sp),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Claude AI analyzes creator performance data to suggest optimal splits per country',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.purple[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedCountryCode,
            decoration: InputDecoration(
              labelText: 'Select Country',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            items: widget.revenueSplits.map((split) {
              return DropdownMenuItem<String>(
                value: split['country_code'] as String,
                child: Text(
                  '${split['country_name']} (${split['country_code']})',
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountryCode = value;
                _recommendation = null;
              });
              if (value != null) _getRecommendation(value);
            },
          ),
          if (_isLoading) ...[
            SizedBox(height: 4.h),
            Center(child: CircularProgressIndicator()),
          ],
          if (_recommendation != null && !_isLoading) ...[
            SizedBox(height: 3.h),
            _buildRecommendationCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    final platformPercentage =
        (_recommendation!['recommended_platform_percentage'] as num).toDouble();
    final creatorPercentage =
        (_recommendation!['recommended_creator_percentage'] as num).toDouble();
    final confidenceScore = (_recommendation!['confidence_score'] as num? ?? 0)
        .toDouble();
    final reasoning = _recommendation!['reasoning'] as String? ?? '';
    final isCached = _recommendation!['cached'] as bool? ?? false;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Recommendation',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isCached)
                  Chip(
                    label: Text('Cached', style: TextStyle(fontSize: 10.sp)),
                    backgroundColor: Colors.grey[200],
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildPercentageCard(
                    'Platform',
                    platformPercentage,
                    Color(0xFFEF4444),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildPercentageCard(
                    'Creator',
                    creatorPercentage,
                    Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: confidenceScore / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                confidenceScore >= 70
                    ? Colors.green
                    : confidenceScore >= 40
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Confidence: ${confidenceScore.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            Text(
              'Reasoning:',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              reasoning,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyRecommendation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Apply Recommendation',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageCard(String label, double percentage, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
