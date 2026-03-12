import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class NegotiationInterfaceWidget extends StatefulWidget {
  final Map<String, dynamic> currentSplit;
  final double monthlyRevenue;
  final Function(Map<String, dynamic>) onSubmit;

  const NegotiationInterfaceWidget({
    super.key,
    required this.currentSplit,
    required this.monthlyRevenue,
    required this.onSubmit,
  });

  @override
  State<NegotiationInterfaceWidget> createState() =>
      _NegotiationInterfaceWidgetState();
}

class _NegotiationInterfaceWidgetState
    extends State<NegotiationInterfaceWidget> {
  final _formKey = GlobalKey<FormState>();
  final _justificationController = TextEditingController();
  double _requestedPercentage = 75.0;

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit({
        'requested_percentage': _requestedPercentage,
        'justification': _justificationController.text,
        'monthly_revenue': widget.monthlyRevenue,
        'performance_metrics': {
          'current_split': widget.currentSplit['creator_percentage'],
          'requested_split': _requestedPercentage,
        },
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Request Custom Split',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              // Eligibility Notice
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20.sp,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'You qualify! Monthly revenue: \$${widget.monthlyRevenue.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              // Requested Percentage Slider
              Text(
                'Requested Creator Share',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _requestedPercentage,
                      min: 70.0,
                      max: 90.0,
                      divisions: 20,
                      label: '${_requestedPercentage.toStringAsFixed(0)}%',
                      onChanged: (value) {
                        setState(() => _requestedPercentage = value);
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_requestedPercentage.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              // Justification
              Text(
                'Justification',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _justificationController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                      'Explain why you deserve a higher revenue split (e.g., consistent high-quality content, strong audience engagement, unique value proposition)...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade700),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide justification';
                  }
                  if (value.trim().length < 50) {
                    return 'Please provide at least 50 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              // Impact Preview
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Impact on Monthly Earnings',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current:',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '\$${widget.monthlyRevenue.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'With ${_requestedPercentage.toStringAsFixed(0)}%:',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '\$${_calculateNewEarnings().toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Increase:',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '+\$${(_calculateNewEarnings() - widget.monthlyRevenue).toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Submit Negotiation Request',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Your request will be reviewed by our finance team within 5-7 business days.',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateNewEarnings() {
    final currentPercentage = widget.currentSplit['creator_percentage'] ?? 70.0;
    final grossRevenue = widget.monthlyRevenue / (currentPercentage / 100);
    return grossRevenue * (_requestedPercentage / 100);
  }
}
