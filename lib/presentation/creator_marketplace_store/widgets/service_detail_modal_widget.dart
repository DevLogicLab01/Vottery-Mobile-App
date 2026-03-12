import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import './availability_calendar_widget.dart';
import './deliverables_checklist_widget.dart';
import './pricing_tiers_widget.dart';

class ServiceDetailModalWidget extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onPurchase;

  const ServiceDetailModalWidget({
    super.key,
    required this.service,
    required this.onClose,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Service Details',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    IconButton(icon: Icon(Icons.close), onPressed: onClose),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['title'] as String,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        service['description'] as String,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      PricingTiersWidget(
                        tiers:
                            service['price_tiers']
                                as List<Map<String, dynamic>>,
                        onSelectTier: onPurchase,
                      ),
                      SizedBox(height: 3.h),
                      DeliverablesChecklistWidget(service: service),
                      SizedBox(height: 3.h),
                      AvailabilityCalendarWidget(
                        creatorId: service['creator_id'] as String,
                        onDateSelected: (date) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Selected date: ${date.toString().split(' ')[0]}',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
