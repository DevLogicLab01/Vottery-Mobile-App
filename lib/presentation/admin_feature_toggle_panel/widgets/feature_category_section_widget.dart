import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './bulk_action_panel_widget.dart';
import './feature_toggle_card_widget.dart';

class FeatureCategorySectionWidget extends StatefulWidget {
  final String category;
  final List<Map<String, dynamic>> features;
  final Function({
    required String featureId,
    required String featureName,
    required bool currentStatus,
    List<dynamic>? dependencies,
  })
  onFeatureToggle;
  final Function(String category, bool enable) onBulkAction;

  const FeatureCategorySectionWidget({
    super.key,
    required this.category,
    required this.features,
    required this.onFeatureToggle,
    required this.onBulkAction,
  });

  @override
  State<FeatureCategorySectionWidget> createState() =>
      _FeatureCategorySectionWidgetState();
}

class _FeatureCategorySectionWidgetState
    extends State<FeatureCategorySectionWidget> {
  bool _isExpanded = true;

  String _getCategoryDisplayName() {
    return widget.category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  IconData _getCategoryIcon() {
    switch (widget.category) {
      case 'platform':
        return Icons.business_center;
      case 'voting_methods':
        return Icons.how_to_vote;
      case 'gamification':
        return Icons.emoji_events;
      case 'payments':
        return Icons.payment;
      case 'social':
        return Icons.people;
      case 'analytics':
        return Icons.analytics;
      case 'notifications':
        return Icons.notifications;
      case 'authentication':
        return Icons.security;
      case 'content_moderation':
        return Icons.shield;
      case 'admin_tools':
        return Icons.admin_panel_settings;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor() {
    switch (widget.category) {
      case 'platform':
        return Colors.indigo;
      case 'voting_methods':
        return Colors.blue;
      case 'gamification':
        return Colors.purple;
      case 'payments':
        return Colors.green;
      case 'social':
        return Colors.pink;
      case 'analytics':
        return Colors.orange;
      case 'notifications':
        return Colors.teal;
      case 'authentication':
        return Colors.red;
      case 'content_moderation':
        return Colors.amber;
      case 'admin_tools':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabledCount = widget.features
        .where((f) => f['is_enabled'] == true)
        .length;
    final totalCount = widget.features.length;
    final categoryColor = _getCategoryColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(26),
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryDisplayName(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '$enabledCount of $totalCount enabled',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            BulkActionPanelWidget(
              category: widget.category,
              onBulkAction: widget.onBulkAction,
            ),
            Divider(height: 1, thickness: 1),
            ...widget.features.map<Widget>(
              (feature) => FeatureToggleCardWidget(
                feature: feature,
                onToggle: widget.onFeatureToggle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
