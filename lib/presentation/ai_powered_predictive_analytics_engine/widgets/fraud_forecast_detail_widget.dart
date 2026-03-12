import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FraudForecastDetailWidget extends StatelessWidget {
  final Map<String, dynamic> forecast;

  const FraudForecastDetailWidget({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text('Fraud Forecast Detail View'),
    );
  }
}
