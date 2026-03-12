import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../routes/app_routes.dart';

/// Prediction Pool Notifications Hub
/// User preference customization for pool creation, lock-in countdowns, resolution events, leaderboard rank changes
class PredictionPoolNotificationsHub extends StatefulWidget {
  const PredictionPoolNotificationsHub({super.key});

  @override
  State<PredictionPoolNotificationsHub> createState() =>
      _PredictionPoolNotificationsHubState();
}

class _PredictionPoolNotificationsHubState
    extends State<PredictionPoolNotificationsHub> {
  final Map<String, bool> _prefs = {
    'prediction_confirmations': true,
    'prediction_countdowns': true,
    'pool_resolutions': true,
    'leaderboard_changes': true,
  };
  bool _loading = true;
  bool _saving = false;
  String? _message;
  bool _messageSuccess = true;

  SupabaseClient get _client => SupabaseService.instance.client;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await _client
          .from('user_preferences')
          .select('notification_settings')
          .eq('user_id', userId)
          .maybeSingle();
      final settings = res?.data?['notification_settings'];
      if (settings is Map) {
        setState(() {
          for (final k in _prefs.keys) {
            if (settings[k] != null) _prefs[k] = settings[k] == true;
          }
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePrefs() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final existing = await _client
          .from('user_preferences')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (existing.data != null) {
        await _client
            .from('user_preferences')
            .update({'notification_settings': _prefs})
            .eq('user_id', userId);
      } else {
        await _client
            .from('user_preferences')
            .insert({'user_id': userId, 'notification_settings': _prefs});
      }
      if (mounted) {
        setState(() {
          _saving = false;
          _message = 'Preferences saved.';
          _messageSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = e.toString();
          _messageSuccess = false;
        });
      }
    }
  }

  void _toggle(String key) {
    setState(() => _prefs[key] = !(_prefs[key] ?? true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [
      ('prediction_confirmations', 'Prediction confirmations',
          'Notify when you lock in a prediction'),
      ('prediction_countdowns', 'Lock-in countdowns',
          'Remind before election closes (15 min, 1 hr, 24 hr)'),
      ('pool_resolutions', 'Pool resolution events',
          'Notify when a pool is resolved with your accuracy & rank'),
      ('leaderboard_changes', 'Leaderboard rank changes',
          'Notify when you enter top 10 in a pool'),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: 'Prediction Pool Notifications',
          variant: CustomAppBarVariant.withBack,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose which prediction pool events trigger notifications (push, email, SMS)',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  if (_message != null)
                    Container(
                      padding: EdgeInsets.all(3.w),
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: _messageSuccess
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _messageSuccess
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ...options.map((o) => _buildSwitchTile(
                        theme,
                        o.$1,
                        o.$2,
                        o.$3,
                      )),
                  SizedBox(height: 4.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _savePrefs,
                      icon: _saving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save preferences'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme,
    String key,
    String label,
    String desc,
  ) {
    final value = _prefs[key] ?? true;
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (_) => _toggle(key),
          ),
        ],
      ),
    );
  }
}
