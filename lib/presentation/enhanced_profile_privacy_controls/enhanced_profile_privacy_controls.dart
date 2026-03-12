import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';

class EnhancedProfilePrivacyControls extends StatefulWidget {
  const EnhancedProfilePrivacyControls({super.key});

  @override
  State<EnhancedProfilePrivacyControls> createState() =>
      _EnhancedProfilePrivacyControlsState();
}

class _EnhancedProfilePrivacyControlsState
    extends State<EnhancedProfilePrivacyControls> {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  bool _isLoading = false;
  bool _isSaving = false;

  // Activity Privacy
  String _onlineStatusVisibility = 'everyone'; // everyone, friends, nobody
  String _lastSeenVisibility = 'everyone';
  bool _activityStatus = true;
  bool _readReceipts = true;
  bool _typingIndicators = true;

  // Profile Visibility
  String _profilePhotoVisibility = 'public'; // public, friends, private
  String _coverPhotoVisibility = 'public';
  String _bioVisibility = 'public';
  String _dobVisibility = 'friends';
  String _phoneVisibility = 'private';
  String _emailVisibility = 'private';
  String _locationVisibility = 'friends';

  // Contact Preferences
  String _whoCanMessage =
      'everyone'; // everyone, friends, friends_of_friends, nobody
  String _whoCanCall = 'friends';
  bool _requireApprovalForTags = true;
  String _whoCanComment = 'everyone';
  bool _allowContentSharing = true;
  bool _requireGroupApproval = true;

  // Data Sharing
  bool _shareWithAdvertisers = false;
  bool _shareWithAnalytics = true;
  bool _shareLocationData = false;
  bool _shareDeviceInfo = true;
  bool _shareContacts = false;
  bool _shareUsagePatterns = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('user_privacy_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _onlineStatusVisibility =
              response['online_status_visibility'] ?? 'everyone';
          _lastSeenVisibility = response['last_seen_visibility'] ?? 'everyone';
          _activityStatus = response['activity_status'] ?? true;
          _readReceipts = response['read_receipts'] ?? true;
          _typingIndicators = response['typing_indicators'] ?? true;
          _profilePhotoVisibility =
              response['profile_photo_visibility'] ?? 'public';
          _coverPhotoVisibility =
              response['cover_photo_visibility'] ?? 'public';
          _bioVisibility = response['bio_visibility'] ?? 'public';
          _dobVisibility = response['dob_visibility'] ?? 'friends';
          _phoneVisibility = response['phone_visibility'] ?? 'private';
          _emailVisibility = response['email_visibility'] ?? 'private';
          _locationVisibility = response['location_visibility'] ?? 'friends';
          _whoCanMessage = response['who_can_message'] ?? 'everyone';
          _whoCanCall = response['who_can_call'] ?? 'friends';
          _requireApprovalForTags =
              response['require_approval_for_tags'] ?? true;
          _whoCanComment = response['who_can_comment'] ?? 'everyone';
          _allowContentSharing = response['allow_content_sharing'] ?? true;
          _requireGroupApproval = response['require_group_approval'] ?? true;
          _shareWithAdvertisers = response['share_with_advertisers'] ?? false;
          _shareWithAnalytics = response['share_with_analytics'] ?? true;
          _shareLocationData = response['share_location_data'] ?? false;
          _shareDeviceInfo = response['share_device_info'] ?? true;
          _shareContacts = response['share_contacts'] ?? false;
          _shareUsagePatterns = response['share_usage_patterns'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Load privacy settings error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePrivacySettings() async {
    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('user_privacy_settings').upsert({
        'user_id': userId,
        'online_status_visibility': _onlineStatusVisibility,
        'last_seen_visibility': _lastSeenVisibility,
        'activity_status': _activityStatus,
        'read_receipts': _readReceipts,
        'typing_indicators': _typingIndicators,
        'profile_photo_visibility': _profilePhotoVisibility,
        'cover_photo_visibility': _coverPhotoVisibility,
        'bio_visibility': _bioVisibility,
        'dob_visibility': _dobVisibility,
        'phone_visibility': _phoneVisibility,
        'email_visibility': _emailVisibility,
        'location_visibility': _locationVisibility,
        'who_can_message': _whoCanMessage,
        'who_can_call': _whoCanCall,
        'require_approval_for_tags': _requireApprovalForTags,
        'who_can_comment': _whoCanComment,
        'allow_content_sharing': _allowContentSharing,
        'require_group_approval': _requireGroupApproval,
        'share_with_advertisers': _shareWithAdvertisers,
        'share_with_analytics': _shareWithAnalytics,
        'share_location_data': _shareLocationData,
        'share_device_info': _shareDeviceInfo,
        'share_contacts': _shareContacts,
        'share_usage_patterns': _shareUsagePatterns,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy settings saved successfully')),
        );
      }
    } catch (e) {
      debugPrint('Save privacy settings error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _applyPrivacyPreset(String preset) {
    setState(() {
      switch (preset) {
        case 'public':
          _onlineStatusVisibility = 'everyone';
          _lastSeenVisibility = 'everyone';
          _activityStatus = true;
          _readReceipts = true;
          _typingIndicators = true;
          _profilePhotoVisibility = 'public';
          _coverPhotoVisibility = 'public';
          _bioVisibility = 'public';
          _dobVisibility = 'public';
          _phoneVisibility = 'friends';
          _emailVisibility = 'friends';
          _locationVisibility = 'friends';
          _whoCanMessage = 'everyone';
          _whoCanCall = 'everyone';
          _requireApprovalForTags = false;
          _whoCanComment = 'everyone';
          _allowContentSharing = true;
          _requireGroupApproval = false;
          break;
        case 'friends_only':
          _onlineStatusVisibility = 'friends';
          _lastSeenVisibility = 'friends';
          _activityStatus = true;
          _readReceipts = true;
          _typingIndicators = true;
          _profilePhotoVisibility = 'friends';
          _coverPhotoVisibility = 'friends';
          _bioVisibility = 'friends';
          _dobVisibility = 'friends';
          _phoneVisibility = 'private';
          _emailVisibility = 'private';
          _locationVisibility = 'friends';
          _whoCanMessage = 'friends';
          _whoCanCall = 'friends';
          _requireApprovalForTags = true;
          _whoCanComment = 'friends';
          _allowContentSharing = true;
          _requireGroupApproval = true;
          break;
        case 'private':
          _onlineStatusVisibility = 'nobody';
          _lastSeenVisibility = 'nobody';
          _activityStatus = false;
          _readReceipts = false;
          _typingIndicators = false;
          _profilePhotoVisibility = 'private';
          _coverPhotoVisibility = 'private';
          _bioVisibility = 'private';
          _dobVisibility = 'private';
          _phoneVisibility = 'private';
          _emailVisibility = 'private';
          _locationVisibility = 'private';
          _whoCanMessage = 'nobody';
          _whoCanCall = 'nobody';
          _requireApprovalForTags = true;
          _whoCanComment = 'nobody';
          _allowContentSharing = false;
          _requireGroupApproval = true;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'EnhancedProfilePrivacyControls',
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Privacy Controls',
            variant: CustomAppBarVariant.standard,
            leading: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                color: theme.appBarTheme.foregroundColor!,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isSaving)
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.appBarTheme.foregroundColor!,
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'save',
                    color: theme.appBarTheme.foregroundColor!,
                    size: 24,
                  ),
                  onPressed: _savePrivacySettings,
                ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Privacy Presets
                    _buildQuickPresetsSection(theme),
                    SizedBox(height: 3.h),

                    // Activity Privacy
                    _buildSectionHeader(theme, 'Activity Privacy'),
                    _buildActivityPrivacySection(theme),
                    SizedBox(height: 3.h),

                    // Profile Visibility
                    _buildSectionHeader(theme, 'Profile Visibility'),
                    _buildProfileVisibilitySection(theme),
                    SizedBox(height: 3.h),

                    // Contact Preferences
                    _buildSectionHeader(theme, 'Contact Preferences'),
                    _buildContactPreferencesSection(theme),
                    SizedBox(height: 3.h),

                    // Data Sharing
                    _buildSectionHeader(theme, 'Data Sharing'),
                    _buildDataSharingSection(theme),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQuickPresetsSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Privacy Presets',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Apply a preset to quickly configure all privacy settings',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyPrivacyPreset('public'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Public', style: TextStyle(fontSize: 12.sp)),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyPrivacyPreset('friends_only'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Friends Only',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyPrivacyPreset('private'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Private', style: TextStyle(fontSize: 12.sp)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildActivityPrivacySection(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            _buildDropdownSetting(
              theme,
              'Online Status',
              'Control who sees when you\'re online',
              _onlineStatusVisibility,
              ['everyone', 'friends', 'nobody'],
              (value) => setState(() => _onlineStatusVisibility = value!),
            ),
            Divider(height: 3.h),
            _buildDropdownSetting(
              theme,
              'Last Seen',
              'Show timestamp of last activity',
              _lastSeenVisibility,
              ['everyone', 'friends', 'nobody'],
              (value) => setState(() => _lastSeenVisibility = value!),
            ),
            Divider(height: 3.h),
            _buildSwitchSetting(
              theme,
              'Activity Status',
              'Show "John is voting in Politics" updates',
              _activityStatus,
              (value) => setState(() => _activityStatus = value),
            ),
            Divider(height: 3.h),
            _buildSwitchSetting(
              theme,
              'Read Receipts',
              'Show blue checkmarks in messages',
              _readReceipts,
              (value) => setState(() => _readReceipts = value),
            ),
            Divider(height: 3.h),
            _buildSwitchSetting(
              theme,
              'Typing Indicators',
              'Show "typing..." in messages',
              _typingIndicators,
              (value) => setState(() => _typingIndicators = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileVisibilitySection(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            _buildDropdownSetting(
              theme,
              'Profile Photo',
              'Who can see your profile picture',
              _profilePhotoVisibility,
              ['public', 'friends', 'private'],
              (value) => setState(() => _profilePhotoVisibility = value!),
            ),
            Divider(height: 3.h),
            _buildDropdownSetting(
              theme,
              'Cover Photo',
              'Who can see your cover photo',
              _coverPhotoVisibility,
              ['public', 'friends', 'private'],
              (value) => setState(() => _coverPhotoVisibility = value!),
            ),
            Divider(height: 3.h),
            _buildDropdownSetting(
              theme,
              'Bio and About Me',
              'Who can see your bio',
              _bioVisibility,
              ['public', 'friends', 'private'],
              (value) => setState(() => _bioVisibility = value!),
            ),
            Divider(height: 3.h),
            _buildDropdownSetting(
              theme,
              'Date of Birth',
              'Who can see your birthday',
              _dobVisibility,
              ['public', 'friends', 'private'],
              (value) => setState(() => _dobVisibility = value!),
            ),
            Divider(height: 3.h),
            _buildDropdownSetting(
              theme,
              'Phone Number',
              'Who can see your phone',
              _phoneVisibility,
              ['public', 'friends', 'private'],
              (value) => setState(() => _phoneVisibility = value!),
            ),
            Divider(height: 3.h),
            _buildDropdownSetting(
              theme,
              'Email Address',
              'Who can see your email',
              _emailVisibility,
              ['public', 'friends', 'private'],
              (value) => setState(() => _emailVisibility = value!),
            ),
            Divider(height: 3.h),
            _buildDropdownSetting(
              theme,
              'Location',
              'Who can see your location',
              _locationVisibility,
              ['public', 'friends', 'private'],
              (value) => setState(() => _locationVisibility = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactPreferencesSection(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            _buildDropdownSetting(
              theme,
              'Who Can Message Me',
              'Control who can send you messages',
              _whoCanMessage,
              ['everyone', 'friends', 'friends_of_friends', 'nobody'],
              (value) => setState(() => _whoCanMessage = value!),
            ),
            Divider(height: 3.h),
            _buildDropdownSetting(
              theme,
              'Who Can Call Me',
              'Control who can call you',
              _whoCanCall,
              ['everyone', 'friends', 'friends_of_friends', 'nobody'],
              (value) => setState(() => _whoCanCall = value!),
            ),
            Divider(height: 3.h),
            _buildSwitchSetting(
              theme,
              'Require Approval for Tags',
              'Approve before tag appears',
              _requireApprovalForTags,
              (value) => setState(() => _requireApprovalForTags = value),
            ),
            Divider(height: 3.h),
            _buildDropdownSetting(
              theme,
              'Who Can Comment',
              'Control who can comment on your posts',
              _whoCanComment,
              ['everyone', 'friends', 'friends_of_friends', 'nobody'],
              (value) => setState(() => _whoCanComment = value!),
            ),
            Divider(height: 3.h),
            _buildSwitchSetting(
              theme,
              'Allow Content Sharing',
              'Let others share your content',
              _allowContentSharing,
              (value) => setState(() => _allowContentSharing = value),
            ),
            Divider(height: 3.h),
            _buildSwitchSetting(
              theme,
              'Require Group Approval',
              'Approve before joining groups',
              _requireGroupApproval,
              (value) => setState(() => _requireGroupApproval = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSharingSection(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            _buildSwitchSetting(
              theme,
              'Share with Advertisers',
              'Use engagement data for targeted ads',
              _shareWithAdvertisers,
              (value) => setState(() => _shareWithAdvertisers = value),
            ),
            Divider(height: 3.h),
            _buildSwitchSetting(
              theme,
              'Share with Analytics',
              'Platform usage statistics',
              _shareWithAnalytics,
              (value) => setState(() => _shareWithAnalytics = value),
            ),
            Divider(height: 3.h),
            _buildSwitchSetting(
              theme,
              'Share Location Data',
              'GPS data for features',
              _shareLocationData,
              (value) => setState(() => _shareLocationData = value),
            ),
            Divider(height: 3.h),
            _buildSwitchSetting(
              theme,
              'Share Device Information',
              'Hardware data for optimization',
              _shareDeviceInfo,
              (value) => setState(() => _shareDeviceInfo = value),
            ),
            Divider(height: 3.h),
            _buildSwitchSetting(
              theme,
              'Share Contacts',
              'Sync contact list for friend suggestions',
              _shareContacts,
              (value) => setState(() => _shareContacts = value),
            ),
            Divider(height: 3.h),
            _buildSwitchSetting(
              theme,
              'Share Usage Patterns',
              'Behavioral data for AI personalization',
              _shareUsagePatterns,
              (value) => setState(() => _shareUsagePatterns = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(
    ThemeData theme,
    String title,
    String subtitle,
    String currentValue,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.h,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(fontSize: 12.sp),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    ThemeData theme,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: theme.colorScheme.primary,
        ),
      ],
    );
  }
}
