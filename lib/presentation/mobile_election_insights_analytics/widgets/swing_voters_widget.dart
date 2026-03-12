import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SwingVotersWidget extends StatelessWidget {
  final List<Map<String, dynamic>> swingVoters;

  const SwingVotersWidget({super.key, required this.swingVoters});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: Colors.orange),
                SizedBox(width: 2.w),
                Text(
                  'Swing Voters',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            if (swingVoters.isEmpty)
              Center(
                child: Text(
                  'No swing voters identified',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              )
            else
              Column(
                children: swingVoters.take(5).map((voter) {
                  final score =
                      (voter['undecided_score'] as num?)?.toDouble() ?? 0.0;

                  return Card(
                    margin: EdgeInsets.only(bottom: 1.h),
                    color: Colors.orange.withAlpha(13),
                    child: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 5.w,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Voter ${voter['user_id'].toString().substring(0, 8)}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Undecided Score: ${score.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              'Target',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
