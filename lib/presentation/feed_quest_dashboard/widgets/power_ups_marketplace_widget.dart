import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PowerUpsMarketplaceWidget extends StatelessWidget {
  const PowerUpsMarketplaceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final powerUps = [
      {
        'name': 'Visibility Boost',
        'description': 'Boost your posts to top of feed for 24h',
        'cost': 300,
        'icon': Icons.visibility,
        'color': Colors.blue,
      },
      {
        'name': 'Feed Priority',
        'description': 'Get priority in friend feeds for 24h',
        'cost': 200,
        'icon': Icons.priority_high,
        'color': Colors.purple,
      },
    ];

    return Column(
      children: powerUps.map((powerUp) {
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: InkWell(
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Redeem ${powerUp['name']}?'),
                  content: Text(
                    'This will cost ${powerUp['cost']} VP. Continue?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Redeem'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${powerUp['name']} activated!')),
                );
              }
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: (powerUp['color'] as Color).withAlpha(26),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      powerUp['icon'] as IconData,
                      color: powerUp['color'] as Color,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          powerUp['name'] as String,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          powerUp['description'] as String,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '${powerUp['cost']} VP',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
