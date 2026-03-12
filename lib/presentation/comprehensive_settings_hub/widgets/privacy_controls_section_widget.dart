import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../user_profile/widgets/settings_section_widget.dart';

const _kHideActivityStatus = 'privacy_hide_activity_status';
const _kProfileVisibility = 'privacy_profile_visibility';
const _kAllowFriendRequests = 'privacy_allow_friend_requests';
const _kWhoCanMessage = 'privacy_who_can_message';

/// Privacy controls section widget with granular permission toggles.
/// Persists to SharedPreferences and user_preferences (Supabase) when available.
class PrivacyControlsSectionWidget extends StatefulWidget {
  final bool dataSharing;
  final bool anonymousVoting;
  final ValueChanged<bool> onDataSharingChanged;
  final ValueChanged<bool> onAnonymousVotingChanged;

  const PrivacyControlsSectionWidget({
    super.key,
    required this.dataSharing,
    required this.anonymousVoting,
    required this.onDataSharingChanged,
    required this.onAnonymousVotingChanged,
  });

  @override
  State<PrivacyControlsSectionWidget> createState() =>
      _PrivacyControlsSectionWidgetState();
}

class _PrivacyControlsSectionWidgetState
    extends State<PrivacyControlsSectionWidget> {
  bool _hideActivityStatus = false;
  String _profileVisibility = 'public';
  bool _allowFriendRequests = true;
  String _whoCanMessage = 'everyone';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hideActivityStatus = prefs.getBool(_kHideActivityStatus) ?? false;
      _profileVisibility = prefs.getString(_kProfileVisibility) ?? 'public';
      _allowFriendRequests = prefs.getBool(_kAllowFriendRequests) ?? true;
      _whoCanMessage = prefs.getString(_kWhoCanMessage) ?? 'everyone';
      _loaded = true;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else {
      await prefs.setString(key, value.toString());
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await Supabase.instance.client.from('user_preferences').upsert({
          'user_id': userId,
          'preference_type': 'privacy_settings',
          'preferences': {
            'hideActivityStatus': _hideActivityStatus,
            'profileVisibility': _profileVisibility,
            'allowFriendRequests': _allowFriendRequests,
            'whoCanMessage': _whoCanMessage,
          },
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,preference_type');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWidget(
      title: 'Privacy Controls',
      items: [
        {
          'icon': 'share',
          'title': 'Data Sharing',
          'subtitle': 'Share anonymized data for research',
          'value': widget.dataSharing,
          'onToggle': widget.onDataSharingChanged,
        },
        {
          'icon': 'visibility_off',
          'title': 'Anonymous Voting',
          'subtitle': 'Hide your identity in vote results',
          'value': widget.anonymousVoting,
          'onToggle': widget.onAnonymousVotingChanged,
        },
        if (_loaded) ...[
          {
            'icon': 'activity',
            'title': 'Hide Activity Status',
            'subtitle': "Don't show when you're online or last active",
            'value': _hideActivityStatus,
            'onToggle': (v) {
              setState(() => _hideActivityStatus = v);
              _savePreference(_kHideActivityStatus, v);
            },
          },
          {
            'icon': 'eye',
            'title': 'Profile Visibility',
            'subtitle': 'Who can see your profile: $_profileVisibility',
            'onTap': () => _showProfileVisibilityPicker(context),
          },
          {
            'icon': 'person_add',
            'title': 'Allow Friend Requests',
            'subtitle': 'Let others send you friend requests',
            'value': _allowFriendRequests,
            'onToggle': (v) {
              setState(() => _allowFriendRequests = v);
              _savePreference(_kAllowFriendRequests, v);
            },
          },
          {
            'icon': 'message',
            'title': 'Who Can Message',
            'subtitle': 'Message permissions: $_whoCanMessage',
            'onTap': () => _showWhoCanMessagePicker(context),
          },
        ],
        {
          'icon': 'block',
          'title': 'Blocked Users',
          'subtitle': 'Manage blocked accounts',
          'onTap': () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('No blocked users')));
          },
        },
      ],
    );
  }

  void _showProfileVisibilityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Public'),
              subtitle: const Text('Anyone can see your profile'),
              trailing: Radio<String>(
                value: 'public',
                groupValue: _profileVisibility,
                onChanged: (v) {
                  setState(() => _profileVisibility = v!);
                  _savePreference(_kProfileVisibility, v);
                  Navigator.pop(ctx);
                },
              ),
            ),
            ListTile(
              title: const Text('Friends'),
              subtitle: const Text('Only friends can see'),
              trailing: Radio<String>(
                value: 'friends',
                groupValue: _profileVisibility,
                onChanged: (v) {
                  setState(() => _profileVisibility = v!);
                  _savePreference(_kProfileVisibility, v);
                  Navigator.pop(ctx);
                },
              ),
            ),
            ListTile(
              title: const Text('Private'),
              subtitle: const Text('Only you can see'),
              trailing: Radio<String>(
                value: 'private',
                groupValue: _profileVisibility,
                onChanged: (v) {
                  setState(() => _profileVisibility = v!);
                  _savePreference(_kProfileVisibility, v);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWhoCanMessagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Everyone'),
              trailing: Radio<String>(
                value: 'everyone',
                groupValue: _whoCanMessage,
                onChanged: (v) {
                  setState(() => _whoCanMessage = v!);
                  _savePreference(_kWhoCanMessage, v);
                  Navigator.pop(ctx);
                },
              ),
            ),
            ListTile(
              title: const Text('Friends'),
              trailing: Radio<String>(
                value: 'friends',
                groupValue: _whoCanMessage,
                onChanged: (v) {
                  setState(() => _whoCanMessage = v!);
                  _savePreference(_kWhoCanMessage, v);
                  Navigator.pop(ctx);
                },
              ),
            ),
            ListTile(
              title: const Text('Nobody'),
              trailing: Radio<String>(
                value: 'nobody',
                groupValue: _whoCanMessage,
                onChanged: (v) {
                  setState(() => _whoCanMessage = v!);
                  _savePreference(_kWhoCanMessage, v);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
