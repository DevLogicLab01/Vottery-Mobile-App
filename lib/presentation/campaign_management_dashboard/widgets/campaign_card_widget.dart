import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class CampaignCardWidget extends StatefulWidget {
  final Map<String, dynamic> campaign;
  final VoidCallback onPause;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const CampaignCardWidget({
    super.key,
    required this.campaign,
    required this.onPause,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  State<CampaignCardWidget> createState() => _CampaignCardWidgetState();
}

class _CampaignCardWidgetState extends State<CampaignCardWidget> {
  bool _zonesExpanded = false;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF22C55E);
      case 'paused':
        return const Color(0xFFF59E0B);
      case 'ended':
      case 'archived':
      case 'completed':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.play_circle_filled;
      case 'paused':
        return Icons.pause_circle_filled;
      case 'ended':
      case 'archived':
      case 'completed':
        return Icons.stop_circle;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = (widget.campaign['status'] as String? ?? 'active');
    final campaignName =
        widget.campaign['campaign_name'] as String? ??
        widget.campaign['title'] as String? ??
        'Unnamed Campaign';
    final votesCount =
        widget.campaign['votes_count'] ??
        widget.campaign['total_participants'] ??
        0;
    final reachCount =
        widget.campaign['reach_count'] ??
        widget.campaign['target_participants'] ??
        0;
    final cpeValue =
        (widget.campaign['cpe_value'] ??
                widget.campaign['cost_per_participant'] ??
                0.0)
            .toDouble();
    final zoneBreakdown =
        widget.campaign['zone_breakdown'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name + Status Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    campaignName,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 2.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withAlpha(30),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: _statusColor(status), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(status),
                        color: _statusColor(status),
                        size: 3.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),

            // Engagement Metrics Row
            Row(
              children: [
                _MetricChip(
                  icon: Icons.how_to_vote,
                  label: 'Votes',
                  value: _formatNumber(votesCount),
                  color: const Color(0xFF6366F1),
                ),
                SizedBox(width: 2.w),
                _MetricChip(
                  icon: Icons.people,
                  label: 'Reach',
                  value: _formatNumber(reachCount),
                  color: const Color(0xFF0EA5E9),
                ),
                SizedBox(width: 2.w),
                _MetricChip(
                  icon: Icons.attach_money,
                  label: 'CPE',
                  value: '\$${cpeValue.toStringAsFixed(2)}',
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),

            // Controls Row
            Row(
              children: [
                _ControlButton(
                  icon: status == 'paused' ? Icons.play_arrow : Icons.pause,
                  label: status == 'paused' ? 'Resume' : 'Pause',
                  color: const Color(0xFFF59E0B),
                  enabled: status != 'archived' &&
                      status != 'completed' &&
                      status != 'ended',
                  onTap: widget.onPause,
                ),
                SizedBox(width: 2.w),
                _ControlButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  color: const Color(0xFF6366F1),
                  onTap: widget.onEdit,
                ),
                SizedBox(width: 2.w),
                _ControlButton(
                  icon: Icons.archive,
                  label: 'Archive',
                  color: const Color(0xFF6B7280),
                  enabled: status != 'archived' &&
                      status != 'completed' &&
                      status != 'ended',
                  onTap: widget.onArchive,
                ),
              ],
            ),

            // Zone Breakdown ExpansionTile
            if (zoneBreakdown.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Zone Breakdown (${zoneBreakdown.length} zones)',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  trailing: Icon(
                    _zonesExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                  onExpansionChanged: (v) => setState(() => _zonesExpanded = v),
                  children: zoneBreakdown.entries.map((entry) {
                    final zoneData = entry.value as Map<String, dynamic>? ?? {};
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 0.5.h),
                      child: Row(
                        children: [
                          Container(
                            width: 2.w,
                            height: 2.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6366F1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              _formatZoneName(entry.key),
                              style: GoogleFonts.inter(fontSize: 11.sp),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '\$${(zoneData['budget'] ?? 0.0).toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNumber(dynamic value) {
    final n = (value is int) ? value : (value as num?)?.toInt() ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _formatZoneName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        })
        .join(' ');
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 4.w),
            SizedBox(height: 0.3.h),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : color.withAlpha(80);
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.h),
          decoration: BoxDecoration(
            color: effectiveColor.withAlpha(20),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: effectiveColor.withAlpha(80)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: effectiveColor, size: 3.5.w),
              SizedBox(width: 1.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
