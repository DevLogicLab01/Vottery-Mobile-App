import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../constants/vottery_ads_constants.dart';
import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
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

  bool _routeArgsConsumed = false;
  String? _pendingElectionIdFromRoute;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAvailableElections();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _consumeRouteArgumentsOnce();
  }

  void _consumeRouteArgumentsOnce() {
    if (_routeArgsConsumed) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null) {
      _routeArgsConsumed = true;
      return;
    }
    if (args is! Map) {
      _routeArgsConsumed = true;
      return;
    }
    final raw = Map<String, dynamic>.from(args);

    final template = raw['template'] ?? raw['template_data'];
    if (template is Map) {
      _applyTemplatePrefill(Map<String, dynamic>.from(template));
      _routeArgsConsumed = true;
      return;
    }

    _applySponsoredElectionPrefill(raw);
    _routeArgsConsumed = true;
  }

  void _applyTemplatePrefill(Map<String, dynamic> template) {
    final name = template['name']?.toString();
    if (name != null && name.isNotEmpty) {
      _campaignNameController.text = name;
    }
    var desc = template['description']?.toString() ?? '';
    final rawQuestions =
        template['preWrittenQuestions'] ?? template['pre_written_questions'];
    if (rawQuestions is List && rawQuestions.isNotEmpty) {
      final lines = rawQuestions.map((q) => '• ${q.toString()}').join('\n');
      desc = desc.isEmpty
          ? 'Suggested questions:\n$lines'
          : '$desc\n\nSuggested questions:\n$lines';
    }
    if (desc.isNotEmpty) {
      _campaignDescriptionController.text = desc;
    }
    if (mounted) setState(() {});
  }

  void _applySponsoredElectionPrefill(Map<String, dynamic> row) {
    final name = row['campaign_name'] ?? row['title'];
    if (name != null) {
      _campaignNameController.text = name.toString();
    }
    final desc = row['description'];
    if (desc != null) {
      _campaignDescriptionController.text = desc.toString();
    }
    final nested = row['election'];
    String? eid = row['election_id']?.toString();
    if (eid == null && nested is Map) {
      eid = nested['id']?.toString();
    }
    if (eid != null && eid.isNotEmpty) {
      _pendingElectionIdFromRoute = eid;
      if (_availableElections.isNotEmpty) {
        final exists = _availableElections.any(
          (e) => (e['id']?.toString()) == eid,
        );
        if (exists) {
          _selectedElectionId = eid;
          _pendingElectionIdFromRoute = null;
        }
      }
    }
    if (mounted) setState(() {});
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
          final pending = _pendingElectionIdFromRoute;
          if (pending != null) {
            final exists = elections.any(
              (e) => (e['id']?.toString()) == pending,
            );
            if (exists) {
              _selectedElectionId = pending;
              _pendingElectionIdFromRoute = null;
            }
          }
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
    if (VotteryAdsConstants.internalAdsBatch1Disabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Participatory Ads Studio')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  VotteryAdsConstants.batch1ParticipatoryAdsDisabledTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                Text(
                  VotteryAdsConstants.batch1ParticipatoryAdsDisabledBody,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          actions: [
            IconButton(
              icon: const Icon(Icons.trending_up),
              tooltip: 'Dynamic CPE engine',
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.dynamicCpePricingEngineDashboardWebCanonical,
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildUnifiedStudioBanner(),
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

  Widget _buildUnifiedStudioBanner() {
    return Material(
      color: AppTheme.primaryLight.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.votteryAdsStudioWebCanonical,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
          child: Row(
            children: [
              Icon(Icons.campaign_outlined,
                  size: 20, color: AppTheme.primaryLight),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Unified ads: display, video, participatory & Spark — open Vottery Ads Studio',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimaryLight,
                      ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textSecondaryLight),
            ],
          ),
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