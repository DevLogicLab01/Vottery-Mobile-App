import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';

class EnhancedPrivacySettingsHub extends StatefulWidget {
  const EnhancedPrivacySettingsHub({super.key});

  @override
  State<EnhancedPrivacySettingsHub> createState() =>
      _EnhancedPrivacySettingsHubState();
}

class _EnhancedPrivacySettingsHubState
    extends State<EnhancedPrivacySettingsHub> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = true;

  // Activity Privacy
  String _onlineStatusVisibility = 'Everyone';
  String _lastSeenVisibility = 'Everyone';
  bool _showActivityStatus = true;
  bool _sendReadReceipts = true;
  bool _showTypingIndicators = true;

  // Profile Visibility
  String _profilePhotoVisibility = 'Public';
  String _coverPhotoVisibility = 'Public';
  String _bioVisibility = 'Public';
  String _dateOfBirthVisibility = 'Friends';
  String _phoneVisibility = 'Private';
  String _emailVisibility = 'Private';
  String _locationVisibility = 'Friends';

  // Contact Preferences
  String _whoCanMessage = 'Everyone';
  String _whoCanCall = 'Friends';
  String _whoCanTag = 'Friends';
  String _whoCanComment = 'Everyone';
  String _whoCanShare = 'Everyone';
  String _whoCanAddToGroups = 'Friends';

  // Data Sharing
  bool _shareWithAdvertisers = false;
  bool _shareWithAnalytics = true;
  bool _shareLocationData = false;
  bool _shareDeviceInfo = true;
  bool _shareContacts = false;
  bool _shareUsagePatterns = true;

  // Location Privacy
  bool _locationServicesEnabled = false;
  String _locationAccuracy = 'Approximate';
  String _locationHistoryRetention = '1 month';
  bool _allowLocationSharing = false;
  bool _attachLocationToPosts = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabaseService.client
          .from('user_privacy_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _onlineStatusVisibility =
              response['online_status_visibility'] ?? 'Everyone';
          _lastSeenVisibility = response['last_seen_visibility'] ?? 'Everyone';
          _showActivityStatus = response['show_activity_status'] ?? true;
          _sendReadReceipts = response['send_read_receipts'] ?? true;
          _showTypingIndicators = response['show_typing_indicators'] ?? true;
          _profilePhotoVisibility =
              response['profile_photo_visibility'] ?? 'Public';
          _coverPhotoVisibility =
              response['cover_photo_visibility'] ?? 'Public';
          _bioVisibility = response['bio_visibility'] ?? 'Public';
          _dateOfBirthVisibility = response['dob_visibility'] ?? 'Friends';
          _phoneVisibility = response['phone_visibility'] ?? 'Private';
          _emailVisibility = response['email_visibility'] ?? 'Private';
          _locationVisibility = response['location_visibility'] ?? 'Friends';
          _whoCanMessage = response['who_can_message'] ?? 'Everyone';
          _whoCanCall = response['who_can_call'] ?? 'Friends';
          _whoCanTag = response['who_can_tag'] ?? 'Friends';
          _whoCanComment = response['who_can_comment'] ?? 'Everyone';
          _whoCanShare = response['who_can_share'] ?? 'Everyone';
          _whoCanAddToGroups = response['who_can_add_to_groups'] ?? 'Friends';
          _shareWithAdvertisers = response['share_with_advertisers'] ?? false;
          _shareWithAnalytics = response['share_with_analytics'] ?? true;
          _shareLocationData = response['share_location_data'] ?? false;
          _shareDeviceInfo = response['share_device_info'] ?? true;
          _shareContacts = response['share_contacts'] ?? false;
          _shareUsagePatterns = response['share_usage_patterns'] ?? true;
          _locationServicesEnabled =
              response['location_services_enabled'] ?? false;
          _locationAccuracy = response['location_accuracy'] ?? 'Approximate';
          _locationHistoryRetention =
              response['location_history_retention'] ?? '1 month';
          _allowLocationSharing = response['allow_location_sharing'] ?? false;
          _attachLocationToPosts =
              response['attach_location_to_posts'] ?? false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading privacy settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrivacySettings() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client.from('user_privacy_settings').upsert({
        'user_id': userId,
        'online_status_visibility': _onlineStatusVisibility,
        'last_seen_visibility': _lastSeenVisibility,
        'show_activity_status': _showActivityStatus,
        'send_read_receipts': _sendReadReceipts,
        'show_typing_indicators': _showTypingIndicators,
        'profile_photo_visibility': _profilePhotoVisibility,
        'cover_photo_visibility': _coverPhotoVisibility,
        'bio_visibility': _bioVisibility,
        'dob_visibility': _dateOfBirthVisibility,
        'phone_visibility': _phoneVisibility,
        'email_visibility': _emailVisibility,
        'location_visibility': _locationVisibility,
        'who_can_message': _whoCanMessage,
        'who_can_call': _whoCanCall,
        'who_can_tag': _whoCanTag,
        'who_can_comment': _whoCanComment,
        'who_can_share': _whoCanShare,
        'who_can_add_to_groups': _whoCanAddToGroups,
        'share_with_advertisers': _shareWithAdvertisers,
        'share_with_analytics': _shareWithAnalytics,
        'share_location_data': _shareLocationData,
        'share_device_info': _shareDeviceInfo,
        'share_contacts': _shareContacts,
        'share_usage_patterns': _shareUsagePatterns,
        'location_services_enabled': _locationServicesEnabled,
        'location_accuracy': _locationAccuracy,
        'location_history_retention': _locationHistoryRetention,
        'allow_location_sharing': _allowLocationSharing,
        'attach_location_to_posts': _attachLocationToPosts,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving privacy settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Privacy Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePrivacySettings,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          _buildActivityPrivacySection(),
          SizedBox(height: 2.h),
          _buildProfileVisibilitySection(),
          SizedBox(height: 2.h),
          _buildContactPreferencesSection(),
          SizedBox(height: 2.h),
          _buildDataSharingSection(),
          SizedBox(height: 2.h),
          _buildLocationPrivacySection(),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }

  Widget _buildActivityPrivacySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Privacy',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildDropdownSetting(
              'Online Status',
              _onlineStatusVisibility,
              ['Everyone', 'Friends Only', 'Nobody'],
              (value) => setState(() => _onlineStatusVisibility = value!),
            ),
            _buildDropdownSetting(
              'Last Seen',
              _lastSeenVisibility,
              ['Everyone', 'Friends Only', 'Nobody'],
              (value) => setState(() => _lastSeenVisibility = value!),
            ),
            _buildSwitchSetting(
              'Activity Status',
              'Show what you\'re doing',
              _showActivityStatus,
              (value) => setState(() => _showActivityStatus = value),
            ),
            _buildSwitchSetting(
              'Read Receipts',
              'Let others see when you\'ve read messages',
              _sendReadReceipts,
              (value) => setState(() => _sendReadReceipts = value),
            ),
            _buildSwitchSetting(
              'Typing Indicators',
              'Show when you\'re typing',
              _showTypingIndicators,
              (value) => setState(() => _showTypingIndicators = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileVisibilitySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Visibility',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildDropdownSetting(
              'Profile Photo',
              _profilePhotoVisibility,
              ['Public', 'Friends', 'Private'],
              (value) => setState(() => _profilePhotoVisibility = value!),
            ),
            _buildDropdownSetting(
              'Cover Photo',
              _coverPhotoVisibility,
              ['Public', 'Friends', 'Private'],
              (value) => setState(() => _coverPhotoVisibility = value!),
            ),
            _buildDropdownSetting(
              'Bio',
              _bioVisibility,
              ['Public', 'Friends', 'Private'],
              (value) => setState(() => _bioVisibility = value!),
            ),
            _buildDropdownSetting(
              'Date of Birth',
              _dateOfBirthVisibility,
              ['Public', 'Friends', 'Private'],
              (value) => setState(() => _dateOfBirthVisibility = value!),
            ),
            _buildDropdownSetting(
              'Phone Number',
              _phoneVisibility,
              ['Public', 'Friends', 'Private'],
              (value) => setState(() => _phoneVisibility = value!),
            ),
            _buildDropdownSetting(
              'Email Address',
              _emailVisibility,
              ['Public', 'Friends', 'Private'],
              (value) => setState(() => _emailVisibility = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactPreferencesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Preferences',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildDropdownSetting(
              'Who Can Message Me',
              _whoCanMessage,
              ['Everyone', 'Friends', 'Nobody'],
              (value) => setState(() => _whoCanMessage = value!),
            ),
            _buildDropdownSetting(
              'Who Can Call Me',
              _whoCanCall,
              ['Everyone', 'Friends', 'Nobody'],
              (value) => setState(() => _whoCanCall = value!),
            ),
            _buildDropdownSetting(
              'Who Can Tag Me',
              _whoCanTag,
              ['Everyone', 'Friends', 'Nobody'],
              (value) => setState(() => _whoCanTag = value!),
            ),
            _buildDropdownSetting(
              'Who Can Comment',
              _whoCanComment,
              ['Everyone', 'Friends', 'Nobody'],
              (value) => setState(() => _whoCanComment = value!),
            ),
            _buildDropdownSetting(
              'Who Can Add Me to Groups',
              _whoCanAddToGroups,
              ['Everyone', 'Friends', 'Nobody'],
              (value) => setState(() => _whoCanAddToGroups = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSharingSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Sharing',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildSwitchSetting(
              'Share with Advertisers',
              'Use your activity for targeted ads',
              _shareWithAdvertisers,
              (value) => setState(() => _shareWithAdvertisers = value),
            ),
            _buildSwitchSetting(
              'Share with Analytics',
              'Help improve the platform',
              _shareWithAnalytics,
              (value) => setState(() => _shareWithAnalytics = value),
            ),
            _buildSwitchSetting(
              'Share Location Data',
              'Allow location-based features',
              _shareLocationData,
              (value) => setState(() => _shareLocationData = value),
            ),
            _buildSwitchSetting(
              'Share Device Information',
              'For optimization and support',
              _shareDeviceInfo,
              (value) => setState(() => _shareDeviceInfo = value),
            ),
            _buildSwitchSetting(
              'Share Contacts',
              'For friend suggestions',
              _shareContacts,
              (value) => setState(() => _shareContacts = value),
            ),
            _buildSwitchSetting(
              'Share Usage Patterns',
              'For AI personalization',
              _shareUsagePatterns,
              (value) => setState(() => _shareUsagePatterns = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPrivacySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Privacy',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildSwitchSetting(
              'Location Services',
              'Enable location features',
              _locationServicesEnabled,
              (value) => setState(() => _locationServicesEnabled = value),
            ),
            _buildDropdownSetting(
              'Location Accuracy',
              _locationAccuracy,
              ['Precise', 'Approximate'],
              (value) => setState(() => _locationAccuracy = value!),
            ),
            _buildDropdownSetting(
              'Location History',
              _locationHistoryRetention,
              ['Never', '1 month', '3 months', '6 months'],
              (value) => setState(() => _locationHistoryRetention = value!),
            ),
            _buildSwitchSetting(
              'Real-time Location Sharing',
              'Allow sharing your current location',
              _allowLocationSharing,
              (value) => setState(() => _allowLocationSharing = value),
            ),
            _buildSwitchSetting(
              'Attach Location to Posts',
              'Add location to your posts',
              _attachLocationToPosts,
              (value) => setState(() => _attachLocationToPosts = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 14.sp)),
          ),
          DropdownButton<String>(
            value: value,
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option, style: TextStyle(fontSize: 14.sp)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
