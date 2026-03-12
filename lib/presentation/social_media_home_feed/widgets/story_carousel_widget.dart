import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Story-style horizontal carousel for active elections
class StoryCarouselWidget extends StatelessWidget {
  final List<Map<String, dynamic>> activeElections;
  final Function(String) onElectionTap;

  const StoryCarouselWidget({
    super.key,
    required this.activeElections,
    required this.onElectionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (activeElections.isEmpty) return SizedBox.shrink();

    return Container(
      height: 18.h,
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: activeElections.length,
        itemBuilder: (context, index) {
          final election = activeElections[index];
          final title = election['title'] as String? ?? 'Election';
          final voteCount = election['vote_count'] as int? ?? 0;
          final imageUrl = election['image_url'] as String?;

          return GestureDetector(
            onTap: () => onElectionTap(election['id'] as String),
            child: Container(
              width: 35.w,
              margin: EdgeInsets.only(right: 3.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppTheme.primaryLight, width: 2),
              ),
              child: Stack(
                children: [
                  // Background Image or Gradient
                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: CustomImageWidget(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        semanticLabel: 'Election story',
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryLight,
                            AppTheme.secondaryLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(179),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.how_to_vote, size: 6.w, color: Colors.white),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              '$voteCount votes',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withAlpha(230),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
