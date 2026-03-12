import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/suggested_elections_service.dart';

class SuggestedElectionsWidget extends StatefulWidget {
  const SuggestedElectionsWidget({super.key});

  @override
  State<SuggestedElectionsWidget> createState() =>
      _SuggestedElectionsWidgetState();
}

class _SuggestedElectionsWidgetState extends State<SuggestedElectionsWidget> {
  final SuggestedElectionsService _service = SuggestedElectionsService.instance;
  bool _isLoading = true;
  bool _isExpanded = false;
  List<Map<String, dynamic>> _suggestedElections = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestedElections();
  }

  Future<void> _loadSuggestedElections() async {
    setState(() => _isLoading = true);
    try {
      final elections = await _service.getSuggestedElections(
        limit: _isExpanded ? 20 : 5,
      );
      setState(() {
        _suggestedElections = elections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight, width: 1),
          bottom: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suggested Elections',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  size: 5.w,
                  color: AppTheme.primaryLight,
                ),
                onPressed: _loadSuggestedElections,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_isLoading)
            _buildShimmerLoading()
          else if (_suggestedElections.isEmpty)
            _buildEmptyState()
          else
            ..._suggestedElections.map(
              (election) => _buildElectionCard(election),
            ),
          if (_suggestedElections.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _isExpanded = !_isExpanded);
                  _loadSuggestedElections();
                },
                child: Text(
                  _isExpanded ? 'See Less' : 'See More',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildElectionCard(Map<String, dynamic> election) {
    final electionId = election['election_id'] ?? election['id'];
    final title = election['title'] ?? 'Untitled Election';
    final imageUrl = election['image_url'];
    final voteCount = election['vote_count'] ?? 0;
    final endDate = election['end_date'] != null
        ? DateTime.parse(election['end_date'])
        : null;
    final prizePool = election['prize_pool'] ?? 0.0;
    final trendingBadge = election['trending_badge'];
    final recommendationReason = election['recommendation_reason'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (trendingBadge != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                        _service
                            .getBadgeColor(trendingBadge)
                            .replaceFirst('#', '0xFF'),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _service.getBadgeEmoji(trendingBadge),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        trendingBadge.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),
              ],
              Expanded(
                child: Text(
                  recommendationReason,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 4.w,
                  color: AppTheme.textSecondaryLight,
                ),
                onPressed: () => _dismissElection(electionId),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CustomImageWidget(
                imageUrl: imageUrl,
                width: double.infinity,
                height: 20.h,
                fit: BoxFit.cover,
                semanticLabel: 'Election image',
              ),
            ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.how_to_vote,
                size: 4.w,
                color: AppTheme.textSecondaryLight,
              ),
              SizedBox(width: 1.w),
              Text(
                '$voteCount votes',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              SizedBox(width: 3.w),
              if (endDate != null) ...[
                Icon(
                  Icons.schedule,
                  size: 4.w,
                  color: AppTheme.textSecondaryLight,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Ends ${_formatDate(endDate)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
          if (prizePool > 0) ...[
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Icon(Icons.emoji_events, size: 4.w, color: Colors.amber),
                SizedBox(width: 1.w),
                Text(
                  'Prize: \$${prizePool.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 1.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToElection(electionId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Vote Now',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: EdgeInsets.only(bottom: 2.h),
          height: 25.h,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Icon(
              Icons.how_to_vote_outlined,
              size: 15.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No suggestions available',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Check back later for personalized recommendations',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToElection(String electionId) {
    _service.trackElectionClicked(electionId);
    Navigator.pushNamed(
      context,
      AppRoutes.voteCasting,
      arguments: {'election_id': electionId},
    );
  }

  void _dismissElection(String electionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Why dismiss this?',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDismissOption('Already voted', electionId),
            _buildDismissOption('Not interested', electionId),
            _buildDismissOption('Inappropriate', electionId),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissOption(String reason, String electionId) {
    return ListTile(
      title: Text(reason, style: GoogleFonts.inter(fontSize: 13.sp)),
      onTap: () async {
        await _service.dismissElection(
          electionId: electionId,
          dismissReason: reason,
        );
        Navigator.pop(context);
        _loadSuggestedElections();
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}