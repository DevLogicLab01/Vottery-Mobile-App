import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';

class EnhancedProfilePrivacyControlsCenter extends StatefulWidget {
  const EnhancedProfilePrivacyControlsCenter({super.key});

  @override
  State<EnhancedProfilePrivacyControlsCenter> createState() =>
      _EnhancedProfilePrivacyControlsCenterState();
}

class _EnhancedProfilePrivacyControlsCenterState
    extends State<EnhancedProfilePrivacyControlsCenter> {
  final _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  bool _isSaving = false;

  // Activity Privacy
  String _onlineStatusVisibility = 'everyone';
  String _lastSeenVisibility = 'everyone';
  String _votingHistoryVisibility = 'everyone';
  String _earningsVisibility = 'show_all';

  // Profile Visibility
  String _profileVisibilityLevel = 'public';
  bool _searchable = true;
  bool _showCompletionBadge = true;
  bool _showActivityFeed = true;

  // Content Privacy
  String _defaultPostPrivacy = 'public';
  bool _showCreatedElections = true;
  bool _allowComments = true;
  bool _allowSharing = true;

  // Communication Privacy
  String _messagePrivacy = 'everyone';
  String _friendRequestPrivacy = 'everyone';
  bool _emailVisibility = false;
  bool _phoneVisibility = false;
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;

  // Data Sharing
  bool _analyticsConsent = true;
  bool _marketingConsent = false;
  bool _partnerDataSharing = false;

  int _privacyScore = 50;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabaseService.client
          .from('user_privacy_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _onlineStatusVisibility =
              response['online_status_visibility'] ?? 'everyone';
          _lastSeenVisibility = response['last_seen_visibility'] ?? 'everyone';
          _votingHistoryVisibility =
              response['voting_history_visibility'] ?? 'everyone';
          _earningsVisibility = response['earnings_visibility'] ?? 'show_all';
          _profileVisibilityLevel =
              response['profile_visibility_level'] ?? 'public';
          _searchable = response['searchable'] ?? true;
          _showCompletionBadge = response['show_completion_badge'] ?? true;
          _showActivityFeed = response['show_activity_feed'] ?? true;
          _defaultPostPrivacy = response['default_post_privacy'] ?? 'public';
          _showCreatedElections = response['show_created_elections'] ?? true;
          _allowComments = response['allow_comments'] ?? true;
          _allowSharing = response['allow_sharing'] ?? true;
          _messagePrivacy = response['message_privacy'] ?? 'everyone';
          _friendRequestPrivacy =
              response['friend_request_privacy'] ?? 'everyone';
          _emailVisibility = response['email_visibility'] ?? false;
          _phoneVisibility = response['phone_visibility'] ?? false;
          _pushNotificationsEnabled =
              response['push_notifications_enabled'] ?? true;
          _emailNotificationsEnabled =
              response['email_notifications_enabled'] ?? true;
          _analyticsConsent = response['analytics_consent'] ?? true;
          _marketingConsent = response['marketing_consent'] ?? false;
          _partnerDataSharing = response['partner_data_sharing'] ?? false;
          _privacyScore = response['privacy_score'] ?? 50;
        });
      }
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrivacySettings() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client.from('user_privacy_settings').upsert({
        'user_id': userId,
        'online_status_visibility': _onlineStatusVisibility,
        'last_seen_visibility': _lastSeenVisibility,
        'voting_history_visibility': _votingHistoryVisibility,
        'earnings_visibility': _earningsVisibility,
        'profile_visibility_level': _profileVisibilityLevel,
        'searchable': _searchable,
        'show_completion_badge': _showCompletionBadge,
        'show_activity_feed': _showActivityFeed,
        'default_post_privacy': _defaultPostPrivacy,
        'show_created_elections': _showCreatedElections,
        'allow_comments': _allowComments,
        'allow_sharing': _allowSharing,
        'message_privacy': _messagePrivacy,
        'friend_request_privacy': _friendRequestPrivacy,
        'email_visibility': _emailVisibility,
        'phone_visibility': _phoneVisibility,
        'push_notifications_enabled': _pushNotificationsEnabled,
        'email_notifications_enabled': _emailNotificationsEnabled,
        'analytics_consent': _analyticsConsent,
        'marketing_consent': _marketingConsent,
        'partner_data_sharing': _partnerDataSharing,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy settings saved successfully')),
        );
      }

      // Reload to get updated privacy score
      await _loadPrivacySettings();
    } catch (e) {
      debugPrint('Error saving privacy settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _applyPreset(String preset) {
    HapticFeedback.mediumImpact();

    setState(() {
      if (preset == 'maximum') {
        // Maximum Privacy
        _onlineStatusVisibility = 'nobody';
        _lastSeenVisibility = 'nobody';
        _votingHistoryVisibility = 'nobody';
        _earningsVisibility = 'hide_all';
        _profileVisibilityLevel = 'private';
        _searchable = false;
        _showCompletionBadge = false;
        _showActivityFeed = false;
        _defaultPostPrivacy = 'private';
        _showCreatedElections = false;
        _allowComments = false;
        _allowSharing = false;
        _messagePrivacy = 'friends_only';
        _friendRequestPrivacy = 'nobody';
        _emailVisibility = false;
        _phoneVisibility = false;
        _analyticsConsent = false;
        _marketingConsent = false;
        _partnerDataSharing = false;
      } else if (preset == 'balanced') {
        // Balanced Privacy
        _onlineStatusVisibility = 'friends_only';
        _lastSeenVisibility = 'friends_only';
        _votingHistoryVisibility = 'friends_only';
        _earningsVisibility = 'show_tier';
        _profileVisibilityLevel = 'public';
        _searchable = true;
        _showCompletionBadge = true;
        _showActivityFeed = true;
        _defaultPostPrivacy = 'friends_only';
        _showCreatedElections = true;
        _allowComments = true;
        _allowSharing = true;
        _messagePrivacy = 'friends_only';
        _friendRequestPrivacy = 'everyone';
        _emailVisibility = false;
        _phoneVisibility = false;
        _analyticsConsent = true;
        _marketingConsent = false;
        _partnerDataSharing = false;
      } else if (preset == 'public') {
        // Public Profile
        _onlineStatusVisibility = 'everyone';
        _lastSeenVisibility = 'everyone';
        _votingHistoryVisibility = 'everyone';
        _earningsVisibility = 'show_all';
        _profileVisibilityLevel = 'public';
        _searchable = true;
        _showCompletionBadge = true;
        _showActivityFeed = true;
        _defaultPostPrivacy = 'public';
        _showCreatedElections = true;
        _allowComments = true;
        _allowSharing = true;
        _messagePrivacy = 'everyone';
        _friendRequestPrivacy = 'everyone';
        _emailVisibility = true;
        _phoneVisibility = false;
        _analyticsConsent = true;
        _marketingConsent = true;
        _partnerDataSharing = true;
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preset Applied'),
        content: Text(
          'Applied ${preset == 'maximum'
              ? 'Maximum Privacy'
              : preset == 'balanced'
              ? 'Balanced Privacy'
              : 'Public Profile'} preset. Don\'t forget to save your changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Controls'),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSaving ? null : _savePrivacySettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrivacyScoreCard(),
                  SizedBox(height: 3.h),
                  _buildPrivacyPresets(),
                  SizedBox(height: 3.h),
                  _buildActivityPrivacySection(),
                  SizedBox(height: 3.h),
                  _buildProfileVisibilitySection(),
                  SizedBox(height: 3.h),
                  _buildContentPrivacySection(),
                  SizedBox(height: 3.h),
                  _buildCommunicationPrivacySection(),
                  SizedBox(height: 3.h),
                  _buildDataSharingSection(),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
    );
  }

  Widget _buildPrivacyScoreCard() {
    Color scoreColor;
    String scoreLabel;

    if (_privacyScore >= 90) {
      scoreColor = Colors.green;
      scoreLabel = 'Highly Private';
    } else if (_privacyScore >= 50) {
      scoreColor = Colors.orange;
      scoreLabel = 'Moderate';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Public';
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withAlpha(26), scoreColor.withAlpha(13)],
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: scoreColor.withAlpha(77)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: scoreColor.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, color: scoreColor, size: 32),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Score',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Text(
                          '$_privacyScore',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          ' / 100',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Presets',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Text(
          'Apply preset configurations with one tap',
          style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildPresetButton(
                'Maximum Privacy',
                Icons.lock_outline,
                Colors.green,
                () => _applyPreset('maximum'),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildPresetButton(
                'Balanced',
                Icons.balance_outlined,
                Colors.orange,
                () => _applyPreset('balanced'),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildPresetButton(
                'Public Profile',
                Icons.public_outlined,
                Colors.blue,
                () => _applyPreset('public'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 0.5.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPrivacySection() {
    return _buildSection('Activity Privacy', Icons.visibility_outlined, [
      _buildDropdownSetting(
        'Online Status Visibility',
        'Who can see when you\'re online',
        _onlineStatusVisibility,
        ['everyone', 'friends_only', 'nobody'],
        (value) => setState(() => _onlineStatusVisibility = value!),
      ),
      _buildDropdownSetting(
        'Last Seen',
        'Who can see your last active time',
        _lastSeenVisibility,
        ['everyone', 'friends_only', 'nobody'],
        (value) => setState(() => _lastSeenVisibility = value!),
      ),
      _buildDropdownSetting(
        'Voting History',
        'Who can see your voting activity',
        _votingHistoryVisibility,
        ['everyone', 'friends_only', 'nobody'],
        (value) => setState(() => _votingHistoryVisibility = value!),
      ),
      _buildDropdownSetting(
        'Earnings Display',
        'Control earnings visibility on profile',
        _earningsVisibility,
        ['show_all', 'show_tier', 'hide_all'],
        (value) => setState(() => _earningsVisibility = value!),
        customLabels: {
          'show_all': 'Show All',
          'show_tier': 'Show Tier Only',
          'hide_all': 'Hide All',
        },
      ),
    ]);
  }

  Widget _buildProfileVisibilitySection() {
    return _buildSection('Profile Visibility', Icons.person_outline, [
      _buildDropdownSetting(
        'Profile Access Level',
        'Who can view your profile',
        _profileVisibilityLevel,
        ['public', 'friends_only', 'private'],
        (value) => setState(() => _profileVisibilityLevel = value!),
        customLabels: {
          'public': 'Public',
          'friends_only': 'Friends Only',
          'private': 'Private',
        },
      ),
      _buildSwitchSetting(
        'Search Visibility',
        'Allow profile in search results',
        _searchable,
        (value) => setState(() => _searchable = value),
      ),
      _buildSwitchSetting(
        'Profile Completion Badge',
        'Show profile completion progress',
        _showCompletionBadge,
        (value) => setState(() => _showCompletionBadge = value),
      ),
      _buildSwitchSetting(
        'Activity Feed',
        'Show recent activity on profile',
        _showActivityFeed,
        (value) => setState(() => _showActivityFeed = value),
      ),
    ]);
  }

  Widget _buildContentPrivacySection() {
    return _buildSection('Content Privacy', Icons.article_outlined, [
      _buildDropdownSetting(
        'Default Post Privacy',
        'Default visibility for new posts',
        _defaultPostPrivacy,
        ['public', 'friends_only', 'private'],
        (value) => setState(() => _defaultPostPrivacy = value!),
        customLabels: {
          'public': 'Public',
          'friends_only': 'Friends Only',
          'private': 'Private',
        },
      ),
      _buildSwitchSetting(
        'Show Created Elections',
        'Display elections you\'ve created on profile',
        _showCreatedElections,
        (value) => setState(() => _showCreatedElections = value),
      ),
      _buildSwitchSetting(
        'Allow Comments',
        'Let others comment on your posts',
        _allowComments,
        (value) => setState(() => _allowComments = value),
      ),
      _buildSwitchSetting(
        'Allow Sharing',
        'Let others share your content',
        _allowSharing,
        (value) => setState(() => _allowSharing = value),
      ),
    ]);
  }

  Widget _buildCommunicationPrivacySection() {
    return _buildSection('Communication Privacy', Icons.message_outlined, [
      _buildDropdownSetting(
        'Who Can Message Me',
        'Control who can send you messages',
        _messagePrivacy,
        ['everyone', 'friends_only', 'nobody'],
        (value) => setState(() => _messagePrivacy = value!),
        customLabels: {
          'everyone': 'Everyone',
          'friends_only': 'Friends Only',
          'nobody': 'Nobody',
        },
      ),
      _buildDropdownSetting(
        'Friend Requests',
        'Who can send you friend requests',
        _friendRequestPrivacy,
        ['everyone', 'friends_only', 'nobody'],
        (value) => setState(() => _friendRequestPrivacy = value!),
        customLabels: {
          'everyone': 'Everyone',
          'friends_only': 'Friends of Friends',
          'nobody': 'Nobody',
        },
      ),
      _buildSwitchSetting(
        'Email Visibility',
        'Show email address on profile',
        _emailVisibility,
        (value) => setState(() => _emailVisibility = value),
      ),
      _buildSwitchSetting(
        'Phone Visibility',
        'Show phone number on profile',
        _phoneVisibility,
        (value) => setState(() => _phoneVisibility = value),
      ),
      _buildSwitchSetting(
        'Push Notifications',
        'Receive push notifications',
        _pushNotificationsEnabled,
        (value) => setState(() => _pushNotificationsEnabled = value),
      ),
      _buildSwitchSetting(
        'Email Notifications',
        'Receive email notifications',
        _emailNotificationsEnabled,
        (value) => setState(() => _emailNotificationsEnabled = value),
      ),
    ]);
  }

  Widget _buildDataSharingSection() {
    return _buildSection('Data Sharing', Icons.share_outlined, [
      _buildSwitchSetting(
        'Analytics Tracking',
        'Help improve the platform with usage data',
        _analyticsConsent,
        (value) => setState(() => _analyticsConsent = value),
      ),
      _buildSwitchSetting(
        'Marketing Emails',
        'Receive promotional emails and updates',
        _marketingConsent,
        (value) => setState(() => _marketingConsent = value),
      ),
      _buildSwitchSetting(
        'Partner Data Sharing',
        'Share data with trusted partners',
        _partnerDataSharing,
        (value) => setState(() => _partnerDataSharing = value),
      ),
      SizedBox(height: 2.h),
      _buildDataExportButton(),
    ]);
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                SizedBox(width: 2.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String subtitle,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    Map<String, String>? customLabels,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: options.map((option) {
          final label =
              customLabels?[option] ??
              option
                  .split('_')
                  .map((word) {
                    return word[0].toUpperCase() + word.substring(1);
                  })
                  .join(' ');

          return DropdownMenuItem(
            value: option,
            child: Text(label, style: TextStyle(fontSize: 13.sp)),
          );
        }).toList(),
        underline: const SizedBox(),
      ),
    );
  }

  Widget _buildDataExportButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Export My Data'),
                  content: const Text(
                    'Request a copy of all your data. You\'ll receive an email with a download link within 48 hours.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Data export requested. Check your email in 48 hours.',
                            ),
                          ),
                        );
                      },
                      child: const Text('Request Export'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export My Data (GDPR)'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
            ),
          ),
        ],
      ),
    );
  }
}