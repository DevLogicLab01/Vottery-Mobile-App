import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class InfrastructureForecastDetailWidget extends StatelessWidget {
  final Map<String, dynamic> forecast;

  const InfrastructureForecastDetailWidget({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text('Infrastructure Forecast Detail View'),
    );
  }
}
