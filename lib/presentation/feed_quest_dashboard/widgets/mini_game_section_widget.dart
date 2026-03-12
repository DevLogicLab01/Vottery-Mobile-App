import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MiniGameSectionWidget extends StatelessWidget {
  const MiniGameSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMiniGameCard(
          context,
          icon: Icons.poll,
          title: 'Quick Polls',
          description: 'Answer quick polls',
          vpReward: 5,
          color: Colors.blue,
        ),
        SizedBox(height: 2.h),
        _buildMiniGameCard(
          context,
          icon: Icons.quiz,
          title: 'Trivia Quizzes',
          description: 'Test your knowledge',
          vpReward: 10,
          color: Colors.purple,
        ),
        SizedBox(height: 2.h),
        _buildMiniGameCard(
          context,
          icon: Icons.trending_up,
          title: 'Prediction Cards',
          description: 'Make predictions',
          vpReward: 20,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMiniGameCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required int vpReward,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title mini-game coming soon!')),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '+$vpReward VP',
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
  }
}
