import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TopElectionsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> elections;

  const TopElectionsWidget({super.key, required this.elections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top 5 Active Elections',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: elections.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final election = elections[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.withAlpha(51),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
                title: Text(
                  election['title'] ?? 'Untitled',
                  style: TextStyle(fontSize: 13.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${election['participation_count'] ?? 0} participants',
                  style: TextStyle(fontSize: 11.sp),
                ),
                trailing: Icon(
                  Icons.trending_up,
                  color: Colors.green,
                  size: 16.sp,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
