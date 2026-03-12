import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RecommendationsPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  final Function(String, String) onStatusUpdate;

  const RecommendationsPanelWidget({
    super.key,
    required this.recommendations,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text('Recommendations Panel'),
    );
  }
}
