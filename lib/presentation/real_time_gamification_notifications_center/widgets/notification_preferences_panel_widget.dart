import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_theme.dart';

class NotificationPreferencesPanelWidget extends StatefulWidget {
  final VoidCallback onSave;

  const NotificationPreferencesPanelWidget({super.key, required this.onSave});

  @override
  State<NotificationPreferencesPanelWidget> createState() =>
      _NotificationPreferencesPanelWidgetState();
}

class _NotificationPreferencesPanelWidgetState
    extends State<NotificationPreferencesPanelWidget> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, bool> _preferences = {};
  bool _enableQuietHours = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _preferences = {
            'achievement_enabled': response['achievement_enabled'] ?? true,
            'streak_enabled': response['streak_enabled'] ?? true,
            'leaderboard_enabled': response['leaderboard_enabled'] ?? true,
            'quest_enabled': response['quest_enabled'] ?? true,
            'vp_opportunity_enabled':
                response['vp_opportunity_enabled'] ?? true,
          };
          _enableQuietHours = response['enable_quiet_hours'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _preferences = {
            'achievement_enabled': true,
            'streak_enabled': true,
            'leaderboard_enabled': true,
            'quest_enabled': true,
            'vp_opportunity_enabled': true,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load preferences error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('notification_preferences').upsert({
        'user_id': userId,
        ..._preferences,
        'enable_quiet_hours': _enableQuietHours,
        'quiet_hours_start':
            '${_quietHoursStart.hour}:${_quietHoursStart.minute}',
        'quiet_hours_end': '${_quietHoursEnd.hour}:${_quietHoursEnd.minute}',
        'updated_at': DateTime.now().toIso8601String(),
      });

      widget.onSave();
    } catch (e) {
      debugPrint('Save preferences error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notification Preferences',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Types',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        _buildPreferenceSwitch(
                          'Achievements',
                          'Badge earned, milestones reached',
                          'achievement_enabled',
                          Icons.emoji_events,
                          AppTheme.vibrantYellow,
                        ),
                        _buildPreferenceSwitch(
                          'Streaks',
                          'Streak maintained, multiplier activated',
                          'streak_enabled',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                        _buildPreferenceSwitch(
                          'Leaderboard',
                          'Rank changes, position updates',
                          'leaderboard_enabled',
                          Icons.leaderboard,
                          AppTheme.primaryLight,
                        ),
                        _buildPreferenceSwitch(
                          'Quests',
                          'Quest progress, completion rewards',
                          'quest_enabled',
                          Icons.flag,
                          Colors.green,
                        ),
                        _buildPreferenceSwitch(
                          'VP Opportunities',
                          'High-reward pools, bonus VP events',
                          'vp_opportunity_enabled',
                          Icons.stars,
                          Colors.purple,
                        ),
                        SizedBox(height: 3.h),

                        // Quiet hours
                        Text(
                          'Quiet Hours',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        SwitchListTile(
                          title: Text(
                            'Enable Quiet Hours',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Only critical notifications during quiet hours',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                          value: _enableQuietHours,
                          onChanged: (value) {
                            setState(() => _enableQuietHours = value);
                          },
                          activeThumbColor: AppTheme.primaryLight,
                        ),
                        if (_enableQuietHours) ...[
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeSelector(
                                  'Start',
                                  _quietHoursStart,
                                  (time) =>
                                      setState(() => _quietHoursStart = time),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: _buildTimeSelector(
                                  'End',
                                  _quietHoursEnd,
                                  (time) =>
                                      setState(() => _quietHoursEnd = time),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
          ),

          // Save button
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  'Save Preferences',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSwitch(
    String title,
    String description,
    String key,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, color: color, size: 5.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _preferences[key] ?? true,
            onChanged: (value) {
              setState(() => _preferences[key] = value);
            },
            activeThumbColor: AppTheme.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onTimeChanged,
  ) {
    return GestureDetector(
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (newTime != null) {
          onTimeChanged(newTime);
        }
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              time.format(context),
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
