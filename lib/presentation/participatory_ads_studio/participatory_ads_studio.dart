import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../services/sponsored_elections_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/ad_format_selection_step.dart';
import './widgets/audience_targeting_step.dart';
import './widgets/budget_configuration_step.dart';
import './widgets/review_submit_step.dart';

/// Participatory Ads Studio
/// Complete campaign builder with 8-zone audience targeting, budget allocation,
/// and Stripe integration for sponsored elections
class ParticipatoryAdsStudio extends StatefulWidget {
  const ParticipatoryAdsStudio({super.key});

  @override
  State<ParticipatoryAdsStudio> createState() => _ParticipatoryAdsStudioState();
}

class _ParticipatoryAdsStudioState extends State<ParticipatoryAdsStudio>
    with SingleTickerProviderStateMixin {
  final SponsoredElectionsService _sponsoredService =
      SponsoredElectionsService.instance;
  final PaymentService _paymentService = PaymentService.instance;
  final AuthService _authService = AuthService.instance;

  late TabController _tabController;
  final PageController _pageController = PageController();

  // Campaign Builder State
  int _currentStep = 0;
  bool _isSaving = false;
  bool _isLoading = false;

  // Step 1: Campaign Details
  final TextEditingController _campaignNameController = TextEditingController();
  final TextEditingController _campaignDescriptionController =
      TextEditingController();
  String? _selectedElectionId;
  List<Map<String, dynamic>> _availableElections = [];

  // Step 2: Ad Format
  AdFormatType? _selectedAdFormat;

  // Step 3: Audience Targeting (zone integers 1-8)
  List<int> _targetZoneInts = [];
  List<String> _audienceTags = [];

  // Step 4: Budget by zone
  Map<int, Map<String, double>> _budgetByZoneMap = {};

  // Step 5: Campaign Settings
  final DateTime _campaignStart = DateTime.now();
  final DateTime _campaignEnd = DateTime.now().add(const Duration(days: 30));
  final bool _doubleXpEnabled = true;
  final int _targetParticipants = 1000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAvailableElections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _campaignNameController.dispose();
    _campaignDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableElections() async {
    setState(() => _isLoading = true);

    try {
      // Load user's elections that can be sponsored
      final elections = await _sponsoredService.getActiveSponsoredElections();
      if (mounted) {
        setState(() {
          _availableElections = elections;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load elections error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitCampaign();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitCampaign() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSaving = true);

    try {
      final campaignData = {
        'campaign_name': _campaignNameController.text,
        'description': _campaignDescriptionController.text,
        'image_url': '',
        'ad_format_type':
            _selectedAdFormat?.toString().split('.').last ?? 'market_research',
        'target_zones': _targetZoneInts,
        'budget_config': _budgetByZoneMap.map(
          (k, v) => MapEntry(k.toString(), v),
        ),
        'status': 'draft',
        'created_at': DateTime.now().toIso8601String(),
        'election_id': _selectedElectionId,
      };

      final supabase = SupabaseService.instance.client;
      await supabase.from('sponsored_elections').insert(campaignData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Submit campaign error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Campaign submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_campaignNameController.text.isEmpty) {
          _showError('Please enter campaign name');
          return false;
        }
        return true;
      case 1:
        if (_selectedAdFormat == null) {
          _showError('Please select an ad format');
          return false;
        }
        return true;
      case 2:
        if (_targetZoneInts.isEmpty) {
          _showError('Please select at least one target zone');
          return false;
        }
        return true;
      case 3:
        if (_budgetByZoneMap.isEmpty) {
          _showError('Please configure budget for selected zones');
          return false;
        }
        return true;
      case 4:
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  int get _estimatedReach {
    final selectedZones = _targetZoneInts.length;
    final totalBudget = _budgetByZoneMap.values.fold<double>(
      0.0,
      (sum, zoneConfig) => sum + (zoneConfig['amount'] ?? 0.0),
    );
    return (selectedZones * 500 * (totalBudget / 100)).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ParticipatoryAdsStudio',
      onRetry: _loadAvailableElections,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Participatory Ads Studio',
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildProgressIndicator(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildCampaignDetailsStep(),
                        AdFormatSelectionStep(
                          selectedFormat: _selectedAdFormat,
                          onFormatSelected: (format) {
                            setState(() => _selectedAdFormat = format);
                          },
                        ),
                        AudienceTargetingStep(
                          targetZones: _targetZoneInts,
                          tags: _audienceTags,
                          onZonesChanged: (zones) {
                            setState(() => _targetZoneInts = zones);
                          },
                          onTagsChanged: (tags) {
                            setState(() => _audienceTags = tags);
                          },
                        ),
                        BudgetConfigurationStep(
                          targetZones: _targetZoneInts,
                          budgetByZone: _budgetByZoneMap,
                          onBudgetChanged: (budget) {
                            setState(() => _budgetByZoneMap = budget);
                          },
                        ),
                        ReviewSubmitStep(
                          campaignName: _campaignNameController.text,
                          description: _campaignDescriptionController.text,
                          imageUrl: '',
                          selectedFormat: _selectedAdFormat,
                          targetZones: _targetZoneInts,
                          tags: _audienceTags,
                          budgetByZone: _budgetByZoneMap,
                          onSubmit: _submitCampaign,
                          isSubmitting: _isSaving,
                          onEditStep: (step) {
                            setState(() => _currentStep = step);
                            _pageController.animateToPage(
                              step,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
                if (index < 4) SizedBox(width: 2.w),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCampaignDetailsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campaign Details',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 1.h),
          Text(
            'Set up your campaign name and select the election to sponsor',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          SizedBox(height: 3.h),
          TextField(
            controller: _campaignNameController,
            decoration: InputDecoration(
              labelText: 'Campaign Name',
              hintText: 'Enter campaign name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              prefixIcon: Icon(Icons.campaign, size: 20.sp),
            ),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _campaignDescriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Campaign Description',
              hintText: 'Describe your campaign objectives',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedElectionId,
            decoration: InputDecoration(
              labelText: 'Select Election to Sponsor',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              prefixIcon: Icon(Icons.how_to_vote, size: 20.sp),
            ),
            items: _availableElections.map((election) {
              return DropdownMenuItem<String>(
                value: election['id'] as String,
                child: Text(
                  election['title'] as String? ?? 'Untitled',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedElectionId = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 4.w),
          if (_currentStep < 4)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 2.h,
                        width: 2.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Next'),
              ),
            ),
        ],
      ),
    );
  }
}