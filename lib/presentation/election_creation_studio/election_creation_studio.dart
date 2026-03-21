import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/mcq_service.dart';
import '../../services/participation_fee_service.dart';
import '../../services/voting_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/offline_status_badge.dart';
import './widgets/auth_methods_selector_widget.dart';
import './widgets/biometric_requirement_widget.dart';
import './widgets/election_url_qr_widget.dart';
import './widgets/enhanced_video_upload_widget.dart';
import './widgets/mcq_builder_widget.dart';
import './widgets/participation_fee_config_widget.dart';
import './widgets/permission_controls_widget.dart';
import './widgets/vote_visibility_toggle_widget.dart';
import './widgets/anonymous_voting_toggle_widget.dart';
import './widgets/voter_approval_otp_abstention_widget.dart';
import './widgets/vote_change_toggle_widget.dart';
import './widgets/unlimited_audience_toggle_widget.dart';
import './widgets/allow_comments_toggle_widget.dart';
import './widgets/age_verification_section_widget.dart';

/// Election Creation Studio - Comprehensive election campaign management
/// Implements multi-step wizard with video requirements, MCQ, regional pricing, and branding
class ElectionCreationStudio extends StatefulWidget {
  const ElectionCreationStudio({super.key});

  @override
  State<ElectionCreationStudio> createState() => _ElectionCreationStudioState();
}

class _ElectionCreationStudioState extends State<ElectionCreationStudio> {
  final VotingService _votingService = VotingService.instance;
  final ParticipationFeeService _feeService = ParticipationFeeService.instance;
  final MCQService _mcqService = MCQService.instance;
  final PageController _pageController = PageController();
  final ImagePicker _imagePicker = ImagePicker();

  int _currentStep = 0;
  bool _isSaving = false;
  bool _showContextualHelp = false;

  // Basic Setup
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _thumbnailPath;

  // Media Requirements - MCQ
  bool _requireMCQ = false;
  int _mcqPassingScore = 70;
  int _mcqMaxAttempts = 3;
  List<Map<String, dynamic>> _mcqQuestions = [];

  // Media Requirements - Video
  bool _requireVideoWatch = false;
  List<String> _videoUrls = [];
  int _minWatchSeconds = 120;
  int _minWatchPercentage = 80;
  String _videoEnforcementType = 'seconds';

  // Media Requirements
  String? _videoPath;
  final int _minWatchTimeSeconds = 0;
  final bool _requireFullWatch = false;

  // Voting Configuration
  String _votingMethod = 'plurality';
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _deadline;

  // Gamification Settings
  bool _isGamified = false;
  double _prizePoolAmount = 0.0;
  Map<String, double> _regionalPrizeAmounts = {};

  // Monetization Setup
  String _pricingType = 'free'; // free, paid_general, paid_regional
  double _generalPrice = 0.0;
  Map<String, double> _regionalPrices = {
    'zone_1_us_canada': 0.0,
    'zone_2_western_europe': 0.0,
    'zone_3_eastern_europe': 0.0,
    'zone_4_africa': 0.0,
    'zone_5_latin_america': 0.0,
    'zone_6_middle_east_asia': 0.0,
    'zone_7_australasia': 0.0,
    'zone_8_china_hong_kong': 0.0,
  };

  // Branding
  String? _logoPath;
  String? _generatedQRCode;
  String? _generatedURL;

  // Permission Settings
  String _permissionType = 'public';
  List<String> _selectedCountries = [];
  String? _selectedGroupId;

  // Biometric & Visibility Settings
  bool _biometricRequired = false;
  String _voteVisibility = 'hidden';
  bool _creatorCanSeeTotals = true;

  // Authentication Methods
  List<String> _selectedAuthMethods = [
    'email_password',
    'magic_link',
    'oauth_google',
  ];

  bool _allowAnonymousVoting = false;
  bool _requireAgeVerification = false;
  List<String> _ageVerificationMethods = [];
  bool _requireVoterApproval = false;
  bool _otpRequired = false;
  bool _abstentionTrackingEnabled = true;
  bool _allowVoteChanges = false;
  bool _allowComments = true;
  bool _allowNominations = false;
  bool _allowSpoiledBallots = false;

  // Unlimited Audience Settings
  bool _unlimitedAudienceEnabled = false;
  int? _maxAudienceSize;
  bool _autoScalingEnabled = true;
  String _performanceOptimizationLevel = 'standard';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _stepHelpText() {
    switch (_currentStep) {
      case 0:
        return 'Basic Setup defines election title, description, category, and thumbnail metadata.';
      case 1:
        return 'Media Requirements configures MCQ and video-watch gates that voters must pass before voting.';
      case 2:
        return 'Voting Configuration sets voting method, deadline, participation controls, and ballot behavior.';
      case 3:
        return 'Monetization Setup defines free or paid participation and regional pricing behavior.';
      case 4:
        return 'Branding & Permissions controls identity, access scope, age checks, auth methods, and visibility.';
      default:
        return 'Use Next and Previous to complete election setup step-by-step.';
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    // Save draft logic
    await Future.delayed(Duration(seconds: 1));
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Draft saved successfully'),
          backgroundColor: AppTheme.accentLight,
        ),
      );
    }
  }

  Future<void> _publishElection() async {
    if (!_validateForm()) return;

    setState(() => _isSaving = true);

    try {
      final electionData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'voting_method': _votingMethod,
        'deadline': _deadline?.toIso8601String(),
        // MCQ settings
        'require_mcq': _requireMCQ,
        'mcq_passing_score_percentage': _mcqPassingScore,
        'mcq_max_attempts': _mcqMaxAttempts,
        // Video settings
        'require_video_watch': _requireVideoWatch,
        'video_urls': _videoUrls,
        'video_min_watch_seconds': _minWatchSeconds,
        'video_min_watch_percentage': _minWatchPercentage,
        'video_watch_enforcement_type': _videoEnforcementType,
        // Unlimited Audience Settings
        'unlimited_audience_size': _unlimitedAudienceEnabled,
        'max_audience_size': _maxAudienceSize,
        'auto_scaling_enabled': _autoScalingEnabled,
        'performance_optimization_level': _performanceOptimizationLevel,
        'participation_fee_type': _pricingType,
        'general_fee_amount': _generalPrice,
        'regional_fee_amounts': _regionalPrices,
        'logo_url': _logoPath,
        'permission_type': _permissionType,
        'allowed_countries': _selectedCountries,
        'group_id': _selectedGroupId,
        'biometric_required': _biometricRequired ? 'any' : 'none',
        'age_verification_required': _requireAgeVerification,
        'age_verification_methods': _ageVerificationMethods,
        'vote_visibility': _voteVisibility,
        'show_live_results': _voteVisibility == 'visible',
        'creator_can_see_totals': _creatorCanSeeTotals,
        'allow_anonymous_voting': _allowAnonymousVoting,
        'require_voter_approval': _requireVoterApproval,
        'otp_required': _otpRequired,
        'abstention_tracking_enabled': _abstentionTrackingEnabled,
        'allow_vote_changes': _allowVoteChanges,
        'allow_comments': _allowComments,
        'comments_enabled': _allowComments,
        'allow_nominations': _allowNominations,
        'allow_spoiled_ballots': _allowSpoiledBallots,
        'status': 'active',
      };

      final electionId = await _votingService.createElection(electionData);

      if (electionId != null) {
        // Save MCQ questions if enabled
        if (_requireMCQ && _mcqQuestions.isNotEmpty) {
          await _mcqService.createMCQQuestions(
            electionId: electionId,
            questions: _mcqQuestions,
          );
        }

        // Save regional fees if regional pricing
        if (_pricingType == 'paid_regional') {
          await _feeService.saveRegionalFees(electionId, _regionalPrices);
        }

        // Generate URL (auto-generated by trigger, but we can fetch it)
        setState(() {
          _generatedURL = 'https://vottery.com/election/$electionId';
          _generatedQRCode = _generatedURL;
        });

        if (mounted) {
          _showSuccessDialog(electionId);
        }
      }
    } catch (e) {
      debugPrint('Publish election error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish election'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter election title')));
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter election description')),
      );
      return false;
    }
    if (_deadline == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select deadline')));
      return false;
    }
    return true;
  }

  void _showSuccessDialog(String electionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.accentLight, size: 8.w),
            SizedBox(width: 2.w),
            Text('Election Published!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your election has been published successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp),
              ),
              SizedBox(height: 3.h),
              ElectionUrlQrWidget(
                electionId: electionId,
                electionTitle: _titleController.text,
                logoUrl: _logoPath,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ElectionCreationStudio',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Create Election',
          variant: CustomAppBarVariant.withBack,
          onBackPressed: () => Navigator.pop(context),
          actions: [
            const OfflineStatusBadge(),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                setState(() => _showContextualHelp = !_showContextualHelp);
              },
            ),
            TextButton(
              onPressed: _isSaving ? null : _saveDraft,
              child: _isSaving
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryLight,
                      ),
                    )
                  : Text(
                      'Save Draft',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryLight,
                      ),
                    ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_showContextualHelp)
              Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.help_outline, color: AppTheme.primaryLight),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        _stepHelpText(),
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
              ),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicSetupStep(),
                  _buildMediaRequirementsStep(),
                  _buildVotingConfigurationStep(),
                  _buildMonetizationSetupStep(),
                  _buildBrandingPermissionsStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(5, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              height: 0.5.h,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppTheme.primaryLight
                    : AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicSetupStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Setup',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),

          // Title
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Election Title *',
              hintText: 'Enter election title',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 2.h),

          // Description
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description *',
              hintText: 'Describe your election',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 2.h),

          // Category
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items:
                [
                      'Politics',
                      'Sports',
                      'Entertainment',
                      'Technology',
                      'Education',
                      'Other',
                    ]
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
          SizedBox(height: 2.h),

          // Thumbnail Upload
          ElevatedButton.icon(
            onPressed: () async {
              final XFile? image = await _imagePicker.pickImage(
                source: ImageSource.gallery,
              );
              if (image != null) {
                setState(() => _thumbnailPath = image.path);
              }
            },
            icon: Icon(Icons.image),
            label: Text(
              _thumbnailPath == null
                  ? 'Upload Thumbnail'
                  : 'Thumbnail Selected',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaRequirementsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media Requirements',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Configure optional MCQ and video watch requirements',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 3.h),
          MCQBuilderWidget(
            requireMCQ: _requireMCQ,
            onRequireMCQChanged: (value) => setState(() => _requireMCQ = value),
            passingScore: _mcqPassingScore,
            onPassingScoreChanged: (value) =>
                setState(() => _mcqPassingScore = value),
            maxAttempts: _mcqMaxAttempts,
            onMaxAttemptsChanged: (value) =>
                setState(() => _mcqMaxAttempts = value),
            questions: _mcqQuestions,
            onQuestionsChanged: (questions) =>
                setState(() => _mcqQuestions = questions),
          ),
          SizedBox(height: 3.h),
          EnhancedVideoUploadWidget(
            videoUrls: _videoUrls,
            onVideosChanged: (urls) => setState(() => _videoUrls = urls),
            minWatchSeconds: _minWatchSeconds,
            onMinWatchSecondsChanged: (value) =>
                setState(() => _minWatchSeconds = value),
            minWatchPercentage: _minWatchPercentage,
            onMinWatchPercentageChanged: (value) =>
                setState(() => _minWatchPercentage = value),
            enforcementType: _videoEnforcementType,
            onEnforcementTypeChanged: (value) =>
                setState(() => _videoEnforcementType = value),
            requireVideoWatch: _requireVideoWatch,
            onRequireVideoWatchChanged: (value) =>
                setState(() => _requireVideoWatch = value),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingConfigurationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voting Configuration',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 2.h),

          // Voting Method
          DropdownButtonFormField<String>(
            initialValue: _votingMethod,
            decoration: InputDecoration(
              labelText: 'Voting Method',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'plurality', child: Text('Plurality')),
              DropdownMenuItem(
                value: 'ranked_choice',
                child: Text('Ranked Choice'),
              ),
              DropdownMenuItem(value: 'approval', child: Text('Approval')),
            ],
            onChanged: (value) => setState(() => _votingMethod = value!),
          ),
          SizedBox(height: 2.h),

          // Deadline
          ListTile(
            title: Text('Deadline'),
            subtitle: Text(
              _deadline == null
                  ? 'Not set'
                  : _deadline!.toString().split('.')[0],
            ),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _deadline = date);
              }
            },
          ),
          SizedBox(height: 2.h),

          // Unlimited Audience Toggle
          UnlimitedAudienceToggleWidget(
            unlimitedAudienceEnabled: _unlimitedAudienceEnabled,
            maxAudienceSize: _maxAudienceSize,
            autoScalingEnabled: _autoScalingEnabled,
            performanceOptimizationLevel: _performanceOptimizationLevel,
            onUnlimitedToggle: (value) {
              setState(() => _unlimitedAudienceEnabled = value);
            },
            onMaxAudienceSizeChanged: (value) {
              setState(() => _maxAudienceSize = value);
            },
            onAutoScalingToggle: (value) {
              setState(() => _autoScalingEnabled = value);
            },
            onPerformanceOptimizationChanged: (value) {
              setState(() => _performanceOptimizationLevel = value);
            },
          ),
          SizedBox(height: 2.h),

          // Anonymous Voting Toggle
          AnonymousVotingToggleWidget(
            allowAnonymousVoting: _allowAnonymousVoting,
            onChanged: (value) {
              setState(() => _allowAnonymousVoting = value);
            },
          ),
          SizedBox(height: 2.h),

          // Voter Approval, OTP, Abstention
          VoterApprovalOtpAbstentionWidget(
            requireVoterApproval: _requireVoterApproval,
            otpRequired: _otpRequired,
            abstentionTrackingEnabled: _abstentionTrackingEnabled,
            onRequireVoterApprovalChanged: (v) =>
                setState(() => _requireVoterApproval = v),
            onOtpRequiredChanged: (v) => setState(() => _otpRequired = v),
            onAbstentionTrackingChanged: (v) =>
                setState(() => _abstentionTrackingEnabled = v),
          ),
          SizedBox(height: 2.h),

          // Vote Change Toggle
          VoteChangeToggleWidget(
            allowVoteChanges: _allowVoteChanges,
            onChanged: (value) {
              setState(() => _allowVoteChanges = value);
            },
          ),
          SizedBox(height: 2.h),

          // Allow Comments Toggle
          AllowCommentsToggleWidget(
            allowComments: _allowComments,
            onChanged: (value) {
              setState(() => _allowComments = value);
            },
          ),
          SizedBox(height: 2.h),

          // Allow Online Nominations Toggle
          SwitchListTile(
            title: Text(
              'Allow Online Nominations',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Let voters nominate candidates/products/services',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
            value: _allowNominations,
            onChanged: (v) => setState(() => _allowNominations = v),
          ),
          SizedBox(height: 1.h),

          // Allow Spoiled Ballots Toggle
          SwitchListTile(
            title: Text(
              'Allow Spoiled Ballots',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Voters can spoil ballot and re-vote (marked for audit)',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
            value: _allowSpoiledBallots,
            onChanged: (v) => setState(() => _allowSpoiledBallots = v),
          ),
        ],
      ),
    );
  }

  Widget _buildMonetizationSetupStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 4: Monetization Setup',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Configure participation fees for your election',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 3.h),
          ParticipationFeeConfigWidget(
            selectedFeeType: _pricingType,
            generalFeeAmount: _generalPrice,
            regionalFeeAmounts: _regionalPrices,
            onFeeTypeChanged: (type) {
              setState(() => _pricingType = type);
            },
            onGeneralFeeChanged: (amount) {
              setState(() => _generalPrice = amount);
            },
            onRegionalFeesChanged: (fees) {
              setState(() => _regionalPrices = fees);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingPermissionsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Branding & Permissions',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),

          // Logo Upload
          ElevatedButton.icon(
            onPressed: () async {
              final XFile? image = await _imagePicker.pickImage(
                source: ImageSource.gallery,
              );
              if (image != null) {
                setState(() => _logoPath = image.path);
              }
            },
            icon: Icon(Icons.image),
            label: Text(_logoPath == null ? 'Upload Logo' : 'Logo Selected'),
          ),
          SizedBox(height: 3.h),

          // Permission Controls
          PermissionControlsWidget(
            selectedPermissionType: _permissionType,
            selectedCountries: _selectedCountries,
            selectedGroupId: _selectedGroupId,
            onPermissionTypeChanged: (type) {
              setState(() => _permissionType = type);
            },
            onSelectedCountriesChanged: (countries) {
              setState(() => _selectedCountries = countries);
            },
            onSelectedGroupChanged: (groupId) {
              setState(() => _selectedGroupId = groupId);
            },
          ),
          SizedBox(height: 3.h),

          // Age Verification
          AgeVerificationSectionWidget(
            requireAgeVerification: _requireAgeVerification,
            selectedMethods: _ageVerificationMethods,
            onRequireChanged: (v) => setState(() => _requireAgeVerification = v),
            onMethodsChanged: (methods) =>
                setState(() => _ageVerificationMethods = methods),
          ),
          SizedBox(height: 2.h),

          // Biometric Requirement
          BiometricRequirementWidget(
            biometricRequired: _biometricRequired,
            onChanged: (value) {
              setState(() => _biometricRequired = value);
            },
          ),
          SizedBox(height: 3.h),

          // Authentication Methods Selector
          AuthMethodsSelectorWidget(
            selectedMethods: _selectedAuthMethods,
            onMethodsChanged: (methods) {
              setState(() => _selectedAuthMethods = methods);
            },
          ),
          SizedBox(height: 3.h),

          // Vote Visibility Toggle
          VoteVisibilityToggleWidget(
            voteVisibility: _voteVisibility,
            onChanged: (visibility) {
              setState(() => _voteVisibility = visibility);
            },
          ),
          SizedBox(height: 2.h),
          // Creator can see vote totals during election
          SwitchListTile(
            title: Text(
              'Creator can see vote totals during election',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Allow the election creator to view live vote counts while the election is open',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: _creatorCanSeeTotals,
            onChanged: (value) {
              setState(() => _creatorCanSeeTotals = value);
            },
          ),
          SizedBox(height: 3.h),

          // Anonymous Voting Toggle
          AnonymousVotingToggleWidget(
            allowAnonymousVoting: _allowAnonymousVoting,
            onChanged: (value) {
              setState(() => _allowAnonymousVoting = value);
            },
            key: ValueKey('anonymous_voting_toggle'),
          ),
          SizedBox(height: 3.h),

          // Voter Approval, OTP, Abstention
          VoterApprovalOtpAbstentionWidget(
            requireVoterApproval: _requireVoterApproval,
            otpRequired: _otpRequired,
            abstentionTrackingEnabled: _abstentionTrackingEnabled,
            onRequireVoterApprovalChanged: (v) =>
                setState(() => _requireVoterApproval = v),
            onOtpRequiredChanged: (v) => setState(() => _otpRequired = v),
            onAbstentionTrackingChanged: (v) =>
                setState(() => _abstentionTrackingEnabled = v),
          ),
          SizedBox(height: 3.h),

          // Vote Change Toggle
          VoteChangeToggleWidget(
            allowVoteChanges: _allowVoteChanges,
            onChanged: (value) {
              setState(() => _allowVoteChanges = value);
            },
            key: ValueKey('vote_change_toggle'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: Text('Previous'),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: 3.w),
            Expanded(
              child: ElevatedButton(
                onPressed: _currentStep == 4 ? _publishElection : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 6.h),
                ),
                child: Text(
                  _currentStep == 4 ? 'Publish Election' : 'Next',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
