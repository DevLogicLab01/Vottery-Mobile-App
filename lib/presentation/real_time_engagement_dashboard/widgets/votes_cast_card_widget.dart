import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class VotesCastCardWidget extends StatelessWidget {
  final int count;
  final double velocity;

  const VotesCastCardWidget({
    super.key,
    required this.count,
    required this.velocity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.how_to_vote, color: Colors.purple, size: 16.sp),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votes Cast (1 hour)',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
                Text(
                  '${velocity.toStringAsFixed(1)}/min velocity',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
