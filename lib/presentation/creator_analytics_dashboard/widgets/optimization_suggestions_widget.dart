import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class OptimizationSuggestionsWidget extends StatefulWidget {
  final Map<String, dynamic> userData;

  const OptimizationSuggestionsWidget({super.key, required this.userData});

  @override
  State<OptimizationSuggestionsWidget> createState() =>
      _OptimizationSuggestionsWidgetState();
}

class _OptimizationSuggestionsWidgetState
    extends State<OptimizationSuggestionsWidget> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _generateSuggestions();
  }

  Future<void> _generateSuggestions() async {
    setState(() => _isLoading = true);

    try {
      // Simulate Claude AI recommendations (replace with actual API call)
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _suggestions = [
          {
            'title': 'Post more Jolts to boost VP by 20%',
            'description':
                'You\'ve only posted 2 Jolts this week. Increase to 5 Jolts to earn 250 VP.',
            'impact': 'High',
            'icon': Icons.video_library,
            'color': Colors.purple,
            'action': 'Create Jolt',
          },
          {
            'title': 'Participate in prediction pools for 5x VP multiplier',
            'description':
                'Your prediction accuracy is 78%. Join high-reward pools to earn up to 1000 VP.',
            'impact': 'Very High',
            'icon': Icons.psychology,
            'color': Colors.orange,
            'action': 'Browse Pools',
          },
          {
            'title': 'Complete daily feed quests for streak bonus',
            'description':
                'You\'re 1 quest away from a 7-day streak. Complete it for a 2x VP multiplier.',
            'impact': 'Medium',
            'icon': Icons.local_fire_department,
            'color': Colors.red,
            'action': 'View Quests',
          },
          {
            'title': 'Engage with community posts for social VP',
            'description':
                'Liking and commenting on posts earns 5 VP each. Aim for 20 interactions daily.',
            'impact': 'Medium',
            'icon': Icons.groups,
            'color': Colors.blue,
            'action': 'Explore Feed',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Generate suggestions error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: theme.colorScheme.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'AI Optimization Tips',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purple, size: 12.sp),
                    SizedBox(width: 1.w),
                    Text(
                      'Claude',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.h),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return _buildSuggestionCard(suggestion, theme);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
    Map<String, dynamic> suggestion,
    ThemeData theme,
  ) {
    final impact = suggestion['impact'] as String;
    final impactColor = _getImpactColor(impact);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (suggestion['color'] as Color).withAlpha(26),
            (suggestion['color'] as Color).withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: suggestion['color'] as Color, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: (suggestion['color'] as Color).withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  suggestion['icon'] as IconData,
                  color: suggestion['color'] as Color,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: impactColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        '$impact Impact',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: impactColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            suggestion['description'] as String,
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Handle action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${suggestion['action']} action triggered'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: suggestion['color'] as Color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                suggestion['action'] as String,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getImpactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'very high':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
