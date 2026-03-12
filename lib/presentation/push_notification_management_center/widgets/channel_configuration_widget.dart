import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';

class ChannelConfigurationWidget extends StatefulWidget {
  final VoidCallback onChannelUpdated;

  const ChannelConfigurationWidget({super.key, required this.onChannelUpdated});

  @override
  State<ChannelConfigurationWidget> createState() =>
      _ChannelConfigurationWidgetState();
}

class _ChannelConfigurationWidgetState
    extends State<ChannelConfigurationWidget> {
  final SupabaseService _supabaseService = SupabaseService.instance;

  final Map<String, bool> _channelSettings = {
    'quest_completions': true,
    'security_alerts': true,
    'vp_rewards': true,
    'social_interactions': true,
  };

  @override
  void initState() {
    super.initState();
    _loadChannelSettings();
  }

  Future<void> _loadChannelSettings() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabaseService.client
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _channelSettings['quest_completions'] =
              response['quest_completions'] ?? true;
          _channelSettings['security_alerts'] =
              response['security_alerts'] ?? true;
          _channelSettings['vp_rewards'] = response['vp_rewards'] ?? true;
          _channelSettings['social_interactions'] =
              response['social_interactions'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Load channel settings error: $e');
    }
  }

  Future<void> _updateChannelSetting(String channel, bool enabled) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client.from('notification_preferences').upsert({
        'user_id': userId,
        channel: enabled,
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _channelSettings[channel] = enabled;
      });

      widget.onChannelUpdated();
    } catch (e) {
      debugPrint('Update channel setting error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Channel Configuration',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            _buildChannelToggle(
              title: 'Quest Completions',
              subtitle: 'Notifications for completed quests',
              icon: Icons.emoji_events,
              color: Colors.purple,
              channel: 'quest_completions',
            ),
            Divider(height: 2.h),
            _buildChannelToggle(
              title: 'Security Alerts',
              subtitle: 'Critical security notifications',
              icon: Icons.security,
              color: Colors.red,
              channel: 'security_alerts',
            ),
            Divider(height: 2.h),
            _buildChannelToggle(
              title: 'VP Rewards',
              subtitle: 'Vottery Points earnings',
              icon: Icons.monetization_on,
              color: Colors.green,
              channel: 'vp_rewards',
            ),
            Divider(height: 2.h),
            _buildChannelToggle(
              title: 'Social Interactions',
              subtitle: 'Likes, comments, and follows',
              icon: Icons.people,
              color: Colors.blue,
              channel: 'social_interactions',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String channel,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
        Switch(
          value: _channelSettings[channel] ?? true,
          onChanged: (value) => _updateChannelSetting(channel, value),
          activeThumbColor: color,
        ),
      ],
    );
  }
}
