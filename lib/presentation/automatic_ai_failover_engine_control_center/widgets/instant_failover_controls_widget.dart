import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class InstantFailoverControlsWidget extends StatelessWidget {
  final Map<String, dynamic> serviceHealth;
  final Function({required String fromProvider, required String toProvider})
  onTriggerFailover;

  const InstantFailoverControlsWidget({
    super.key,
    required this.serviceHealth,
    required this.onTriggerFailover,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instant Failover Controls',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              '500ms Gemini switching with traffic queuing',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFailoverButton(
                  context,
                  'OpenAI → Gemini',
                  'openai',
                  'gemini',
                  Colors.green,
                ),
                _buildFailoverButton(
                  context,
                  'Anthropic → Gemini',
                  'anthropic',
                  'gemini',
                  Colors.orange,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFailoverButton(
                  context,
                  'Perplexity → Gemini',
                  'perplexity',
                  'gemini',
                  Colors.blue,
                ),
                _buildFailoverButton(
                  context,
                  'All → Gemini',
                  'all',
                  'gemini',
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailoverButton(
    BuildContext context,
    String label,
    String from,
    String to,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: () => onTriggerFailover(fromProvider: from, toProvider: to),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      ),
      child: Text(label, style: TextStyle(fontSize: 12.sp)),
    );
  }
}
