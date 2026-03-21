import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/captcha_service.dart';
import '../../services/participation_fee_service.dart';
import '../../widgets/error_boundary_wrapper.dart';

class ParticipationFeePaymentScreen extends StatefulWidget {
  final String electionId;
  final String electionTitle;
  final String feeType;
  final double? generalFeeAmount;
  final Map<String, dynamic>? regionalFees;

  const ParticipationFeePaymentScreen({
    super.key,
    required this.electionId,
    required this.electionTitle,
    required this.feeType,
    this.generalFeeAmount,
    this.regionalFees,
  });

  @override
  State<ParticipationFeePaymentScreen> createState() =>
      _ParticipationFeePaymentScreenState();
}

class _ParticipationFeePaymentScreenState
    extends State<ParticipationFeePaymentScreen> {
  final ParticipationFeeService _feeService = ParticipationFeeService.instance;
  final AuthService _authService = AuthService.instance;

  bool _isLoading = true;
  bool _isProcessing = false;
  bool _hasPaid = false;
  int _failedPaymentAttempts = 0;
  double _feeAmount = 0.0;
  String _userZone = 'zone_1_us_canada';
  final TextEditingController _captchaTokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPaymentStatus();
  }

  @override
  void dispose() {
    _captchaTokenController.dispose();
    super.dispose();
  }

  Future<void> _checkPaymentStatus() async {
    setState(() => _isLoading = true);

    try {
      final hasPaid = await _feeService.hasPaidFee(widget.electionId);

      if (hasPaid) {
        setState(() {
          _hasPaid = true;
          _isLoading = false;
        });
        return;
      }

      if (widget.feeType == 'free') {
        _navigateToVoting();
        return;
      } else if (widget.feeType == 'paid_general') {
        _feeAmount = widget.generalFeeAmount ?? 0.0;
      } else if (widget.feeType == 'paid_regional') {
        _userZone = 'zone_1_us_canada';
        _feeAmount = (widget.regionalFees?[_userZone] ?? 0.0).toDouble();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Check payment status error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processPayment() async {
    if (!_authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to continue'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (_failedPaymentAttempts >= 2) {
        final captchaValid = await CaptchaService.instance.validateToken(
          _captchaTokenController.text,
        );
        if (!captchaValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Captcha verification failed. Enter a valid token and retry.'),
                backgroundColor: AppTheme.errorLight,
              ),
            );
          }
          setState(() => _isProcessing = false);
          return;
        }
      }

      final result = await _feeService.processPayment(
        electionId: widget.electionId,
        amount: _feeAmount,
        zone: _userZone,
      );

      if (result.success) {
        _failedPaymentAttempts = 0;
        _captchaTokenController.clear();
        setState(() => _hasPaid = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment successful! You can now vote.'),
              backgroundColor: AppTheme.accentLight,
            ),
          );
        }
        await Future.delayed(Duration(seconds: 2));
        _navigateToVoting();
      } else {
        _failedPaymentAttempts += 1;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.errorLight,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Process payment error: $e');
      _failedPaymentAttempts += 1;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed. Please try again.'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _navigateToVoting() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.voteCasting,
      arguments: widget.electionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ParticipationFeePayment',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text('Participation Fee'),
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.accentLight),
              )
            : _hasPaid
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.accentLight,
                      size: 20.w,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Payment Confirmed',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Redirecting to voting...',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 4.0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Election',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            widget.electionTitle,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight.withAlpha(26),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: AppTheme.accentLight),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Participation Fee',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                              Text(
                                '\$${_feeAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentLight,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.primaryLight,
                                  size: 5.w,
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Text(
                                    'This one-time fee is required to participate in this election. Payment is processed securely via Stripe.',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),
                    if (_failedPaymentAttempts >= 2) ...[
                      TextField(
                        controller: _captchaTokenController,
                        decoration: InputDecoration(
                          labelText: 'hCaptcha Token',
                          hintText: 'Paste token from captcha challenge',
                          prefixIcon: Icon(Icons.verified_user_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentLight,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2,
                      ),
                      child: _isProcessing
                          ? SizedBox(
                              width: 6.w,
                              height: 6.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payment, size: 6.w),
                                SizedBox(width: 2.w),
                                Text(
                                  'Pay \$${_feeAmount.toStringAsFixed(2)} & Continue',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}