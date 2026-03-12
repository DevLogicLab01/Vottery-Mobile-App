import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/topic_preference_service.dart';
import '../../../theme/app_theme.dart';

class ColdStartSolutionWidget extends StatefulWidget {
  const ColdStartSolutionWidget({super.key});

  @override
  State<ColdStartSolutionWidget> createState() =>
      _ColdStartSolutionWidgetState();
}

class _ColdStartSolutionWidgetState extends State<ColdStartSolutionWidget> {
  final TopicPreferenceService _topicService = TopicPreferenceService.instance;
  bool _isLoading = true;
  Map<String, dynamic> _coldStartMetrics = {};

  @override
  void initState() {
    super.initState();
    _loadColdStartData();
  }

  Future<void> _loadColdStartData() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _coldStartMetrics = {
        'new_users_today': 247,
        'topic_swipes_collected': 1893,
        'immediate_recommendations': 1847,
        'avg_satisfaction': 4.2,
        'signal_generation_time': 2.3,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 2.h),
          _buildMetricsGrid(),
          SizedBox(height: 2.h),
          _buildWorkflowDiagram(),
          SizedBox(height: 2.h),
          _buildBehavioralClustering(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch, color: Colors.white, size: 8.w),
              SizedBox(width: 2.w),
              Text(
                'Cold-Start Solution',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Immediate signal generation from topic preference swipes with behavioral clustering for new users',
            style: TextStyle(fontSize: 11.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 2.w,
      mainAxisSpacing: 2.h,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'New Users Today',
          _coldStartMetrics['new_users_today'].toString(),
          Icons.person_add,
          Colors.blue,
        ),
        _buildMetricCard(
          'Topic Swipes',
          _coldStartMetrics['topic_swipes_collected'].toString(),
          Icons.swipe,
          Colors.purple,
        ),
        _buildMetricCard(
          'Recommendations',
          _coldStartMetrics['immediate_recommendations'].toString(),
          Icons.recommend,
          Colors.green,
        ),
        _buildMetricCard(
          'Avg Satisfaction',
          '${_coldStartMetrics['avg_satisfaction']}/5.0',
          Icons.star,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowDiagram() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cold-Start Workflow',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildWorkflowStep(
            1,
            'User Signs Up',
            'New user creates account',
            Icons.person_add,
            Colors.blue,
          ),
          _buildWorkflowArrow(),
          _buildWorkflowStep(
            2,
            'Topic Swipe Game',
            'User swipes on 10-15 topics',
            Icons.swipe,
            Colors.purple,
          ),
          _buildWorkflowArrow(),
          _buildWorkflowStep(
            3,
            'Signal Generation',
            'Immediate preference signals created',
            Icons.flash_on,
            Colors.orange,
          ),
          _buildWorkflowArrow(),
          _buildWorkflowStep(
            4,
            'Recommendations',
            'Personalized feed generated instantly',
            Icons.recommend,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStep(
    int step,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: color, size: 6.w),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step $step: $title',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowArrow() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
      child: Icon(
        Icons.arrow_downward,
        color: AppTheme.textSecondaryLight,
        size: 6.w,
      ),
    );
  }

  Widget _buildBehavioralClustering() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Behavioral Clustering',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'New users are clustered with similar users based on topic preferences, enabling immediate personalized recommendations without historical data.',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildClusterCard('Political Enthusiasts', 1247, Colors.blue),
          _buildClusterCard('Tech & Innovation', 983, Colors.purple),
          _buildClusterCard('Environmental Advocates', 756, Colors.green),
        ],
      ),
    );
  }

  Widget _buildClusterCard(String name, int userCount, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.group, color: color, size: 6.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
          Text(
            '$userCount users',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
