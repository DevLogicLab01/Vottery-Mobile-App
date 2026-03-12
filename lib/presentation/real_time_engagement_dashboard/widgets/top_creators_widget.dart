import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TopCreatorsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> creators;

  const TopCreatorsWidget({super.key, required this.creators});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top 5 Active Creators',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: creators.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final creator = creators[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withAlpha(51),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                title: Text(
                  creator['username'] ?? 'Unknown',
                  style: TextStyle(fontSize: 13.sp),
                ),
                subtitle: Text(
                  '${creator['engagement_level'] ?? 0} engagement',
                  style: TextStyle(fontSize: 11.sp),
                ),
                trailing: Icon(Icons.star, color: Colors.amber, size: 16.sp),
              );
            },
          ),
        ),
      ],
    );
  }
}
