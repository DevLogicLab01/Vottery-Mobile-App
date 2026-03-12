import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class CrossDomainEngineConfigWidget extends StatefulWidget {
  final VoidCallback onConfigChanged;

  const CrossDomainEngineConfigWidget({
    super.key,
    required this.onConfigChanged,
  });

  @override
  State<CrossDomainEngineConfigWidget> createState() =>
      _CrossDomainEngineConfigWidgetState();
}

class _CrossDomainEngineConfigWidgetState
    extends State<CrossDomainEngineConfigWidget> {
  double _electionsWeight = 0.4;
  double _postsWeight = 0.35;
  double _adsWeight = 0.25;

  double _semanticWeight = 0.3;
  double _collaborativeWeight = 0.3;
  double _recencyWeight = 0.2;
  double _popularityWeight = 0.2;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Content Type Distribution',
            'Configure the mix of elections, posts, and ads in recommendations',
          ),
          SizedBox(height: 2.h),
          _buildWeightSlider(
            'Elections',
            _electionsWeight,
            (value) => setState(() => _electionsWeight = value),
            Icons.how_to_vote,
            AppTheme.primaryLight,
          ),
          _buildWeightSlider(
            'Posts',
            _postsWeight,
            (value) => setState(() => _postsWeight = value),
            Icons.article,
            AppTheme.accentLight,
          ),
          _buildWeightSlider(
            'Ads',
            _adsWeight,
            (value) => setState(() => _adsWeight = value),
            Icons.campaign,
            Colors.orange,
          ),
          SizedBox(height: 3.h),
          _buildSectionHeader(
            'Ranking Algorithm Weights',
            'Adjust the importance of different ranking factors',
          ),
          SizedBox(height: 2.h),
          _buildWeightSlider(
            'Semantic Similarity',
            _semanticWeight,
            (value) => setState(() => _semanticWeight = value),
            Icons.psychology,
            Colors.purple,
          ),
          _buildWeightSlider(
            'Collaborative Filtering',
            _collaborativeWeight,
            (value) => setState(() => _collaborativeWeight = value),
            Icons.people,
            Colors.blue,
          ),
          _buildWeightSlider(
            'Recency Boost',
            _recencyWeight,
            (value) => setState(() => _recencyWeight = value),
            Icons.schedule,
            Colors.green,
          ),
          _buildWeightSlider(
            'Popularity',
            _popularityWeight,
            (value) => setState(() => _popularityWeight = value),
            Icons.trending_up,
            Colors.red,
          ),
          SizedBox(height: 3.h),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryLight,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          description,
          style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildWeightSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withAlpha(51),
              thumbColor: color,
              overlayColor: color.withAlpha(51),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          widget.onConfigChanged();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuration saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Text(
          'Save Configuration',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
