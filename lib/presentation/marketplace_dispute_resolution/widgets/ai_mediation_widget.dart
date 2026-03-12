import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/marketplace_dispute_service.dart';
import '../../../theme/app_theme.dart';

class AIMediationWidget extends StatefulWidget {
  final List<Map<String, dynamic>> disputes;
  final VoidCallback onRefresh;

  const AIMediationWidget({
    super.key,
    required this.disputes,
    required this.onRefresh,
  });

  @override
  State<AIMediationWidget> createState() => _AIMediationWidgetState();
}

class _AIMediationWidgetState extends State<AIMediationWidget> {
  final MarketplaceDisputeService _disputeService =
      MarketplaceDisputeService.instance;
  String? _selectedDisputeId;
  bool _isMediating = false;
  Map<String, dynamic>? _mediationResult;

  Future<void> _requestMediation(Map<String, dynamic> dispute) async {
    setState(() {
      _selectedDisputeId = dispute['id'];
      _isMediating = true;
    });

    try {
      final result = await _disputeService.requestAIMediation(
        transactionId: dispute['id'],
        disputeDetails: {
          'buyer_evidence': dispute['dispute_reason'] ?? '',
          'seller_evidence': 'Service was delivered as agreed',
          'amount_usd': dispute['amount_usd'] ?? 0.0,
        },
      );

      setState(() {
        _mediationResult = result;
        _isMediating = false;
      });
    } catch (e) {
      setState(() => _isMediating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mediation request failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.disputes.isEmpty) {
      return Center(
        child: Text(
          'No disputes available for mediation',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, color: Colors.blue, size: 8.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Claude AI Mediation',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Impartial AI analysis of disputes with fair resolution recommendations',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          ...widget.disputes.map((dispute) {
            final isSelected = _selectedDisputeId == dispute['id'];
            return _buildDisputeCard(dispute, isSelected);
          }),
          if (_mediationResult != null) ...[
            SizedBox(height: 3.h),
            _buildMediationResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildDisputeCard(Map<String, dynamic> dispute, bool isSelected) {
    final serviceTitle =
        dispute['marketplace_services']?['title'] ?? 'Unknown Service';
    final amountUsd = dispute['amount_usd'] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryLight
              : Colors.grey.withValues(alpha: 0.3),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  serviceTitle,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '\$${amountUsd.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isMediating ? null : () => _requestMediation(dispute),
              icon: _isMediating && isSelected
                  ? SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.psychology),
              label: Text(
                _isMediating && isSelected
                    ? 'Analyzing...'
                    : 'Request AI Mediation',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediationResult() {
    final recommendedAction = _mediationResult!['recommended_action'] ?? '';
    final refundPercentage = _mediationResult!['refund_percentage'] ?? 0;
    final reasoning = _mediationResult!['reasoning'] ?? '';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 6.w),
              SizedBox(width: 3.w),
              Text(
                'AI Mediation Complete',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildResultRow('Recommended Action', recommendedAction),
          SizedBox(height: 1.h),
          _buildResultRow('Refund Amount', '$refundPercentage%'),
          SizedBox(height: 2.h),
          Text(
            'AI Reasoning:',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            reasoning,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Accept & Process'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _mediationResult = null);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
