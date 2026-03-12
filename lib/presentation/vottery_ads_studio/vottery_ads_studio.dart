import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../constants/vottery_ads_constants.dart';
import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/vottery_ads_service.dart';
import '../../theme/app_theme.dart';

class VotteryAdsStudio extends StatefulWidget {
  const VotteryAdsStudio({super.key});

  @override
  State<VotteryAdsStudio> createState() => _VotteryAdsStudioState();
}

class _VotteryAdsStudioState extends State<VotteryAdsStudio> {
  final _campaignNameController = TextEditingController();
  String _objective = VotteryAdsConstants.campaignObjectiveReach;

  final _adGroupNameController = TextEditingController();
  List<int> _targetZones = List<int>.from(VotteryAdsConstants.zoneValues);
  List<String> _targetCountries = [];
  List<_RegionRow> _regions = [];
  String _placementMode = 'automatic';
  List<String> _placementSlots = [];
  int? _dailyBudgetCents = VotteryAdsConstants.defaultMinDailyBudgetCents;
  int? _lifetimeBudgetCents;

  final _adNameController = TextEditingController();
  String _adType = VotteryAdsConstants.adTypeDisplay;
  final _headlineController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  String? _electionId;
  bool _enableGamification = false;
  int? _prizePoolCents;
  String? _sparkPostId;
  String _sparkSourceType = 'moment';
  final _ctaLabelController = TextEditingController(text: 'Learn more');
  final _ctaUrlController = TextEditingController();
  int _bidAmountCents = 500;
  String _pricingModel = VotteryAdsConstants.pricingModelCpm;

  int _currentStep = 0;
  bool _isSubmitting = false;
  Map<String, dynamic> _adminConfig = {};

  @override
  void initState() {
    super.initState();
    _loadAdminConfig();
  }

  Future<void> _loadAdminConfig() async {
    try {
      final config = await VotteryAdsService.instance.getAdminConfig();
      if (!mounted) return;
      setState(() {
        _adminConfig = config;
      });
    } catch (e) {
      debugPrint('Load admin config error: $e');
    }
  }

  @override
  void dispose() {
    _campaignNameController.dispose();
    _adGroupNameController.dispose();
    _adNameController.dispose();
    _headlineController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _ctaLabelController.dispose();
    _ctaUrlController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_campaignNameController.text.trim().isEmpty) {
        _showError('Please enter a campaign name.');
        return false;
      }
    } else if (step == 1) {
      if (_adGroupNameController.text.trim().isEmpty) {
        _showError('Please enter an ad group name.');
        return false;
      }
      final minDaily = (_adminConfig['min_daily_budget_cents'] ??
              VotteryAdsConstants.defaultMinDailyBudgetCents)
          as Object;
      final minDailyInt = int.tryParse(minDaily.toString()) ??
          VotteryAdsConstants.defaultMinDailyBudgetCents;
      if (_dailyBudgetCents != null &&
          _dailyBudgetCents! < minDailyInt) {
        _showError(
          'Daily budget must be at least \$${(minDailyInt / 100).toStringAsFixed(2)}.',
        );
        return false;
      }
    } else if (step == 2) {
      if (_adNameController.text.trim().isEmpty) {
        _showError('Please enter an ad name.');
        return false;
      }
      if (_adType == VotteryAdsConstants.adTypeParticipatory &&
          _electionId == null) {
        _showError('Please select an election for participatory ad.');
        return false;
      }
      if (_adType == VotteryAdsConstants.adTypeSpark &&
          _sparkPostId == null) {
        _showError('Please select a post to boost for Spark ad.');
        return false;
      }
    }
    return true;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_validateStep(_currentStep)) return;

    setState(() => _isSubmitting = true);
    try {
      final auth = AuthService.instance;
      if (!auth.isAuthenticated) {
        throw Exception('You must be signed in to create campaigns.');
      }

      final campaign = await VotteryAdsService.instance.createCampaign(
        name: _campaignNameController.text.trim(),
        objective: _objective,
      );

      final adGroup = await VotteryAdsService.instance.createAdGroup(
        campaignId: campaign['id'] as String,
        name: _adGroupNameController.text.trim(),
        targetZones: _targetZones,
        targetCountries: _targetCountries,
        placementMode: _placementMode,
        placementSlots: _placementSlots,
        dailyBudgetCents: _dailyBudgetCents,
        lifetimeBudgetCents: _lifetimeBudgetCents,
      );

      if (_regions.isNotEmpty) {
        await VotteryAdsService.instance.setTargetingGeo(
          adGroupId: adGroup['id'] as String,
          regions: _regions
              .map((r) => {
                    'country_iso': r.countryIso,
                    'region_code': r.regionCode,
                    'region_name': r.regionName,
                  })
              .toList(),
        );
      }

      final creative = <String, dynamic>{
        'headline': _headlineController.text.trim(),
        'body': _bodyController.text.trim(),
        'image_url': _imageUrlController.text.trim(),
        'video_url': _videoUrlController.text.trim(),
        'cta_label': _ctaLabelController.text.trim(),
        'cta_url': _ctaUrlController.text.trim(),
      };

      final ad = await VotteryAdsService.instance.createAd(
        adGroupId: adGroup['id'] as String,
        name: _adNameController.text.trim(),
        adType: _adType,
        creative: creative,
        electionId: _adType == VotteryAdsConstants.adTypeParticipatory
            ? _electionId
            : null,
        enableGamification:
            _adType == VotteryAdsConstants.adTypeParticipatory &&
                _enableGamification,
        prizePoolCents: _prizePoolCents,
        sourcePostId:
            _adType == VotteryAdsConstants.adTypeSpark ? _sparkPostId : null,
        bidAmountCents: _bidAmountCents,
        pricingModel: _pricingModel,
      );

      if (_adType == VotteryAdsConstants.adTypeSpark && _sparkPostId != null) {
        await VotteryAdsService.instance.upsertSparkReference(
          adId: ad['id'] as String,
          sourcePostId: _sparkPostId!,
          sourceType: _sparkSourceType,
          ctaLabel: _ctaLabelController.text.trim(),
          ctaDestinationUrl: _ctaUrlController.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vottery ad campaign created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('VotteryAdsStudio submit error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create campaign: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Vottery Ads Studio'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepHeader(),
            Expanded(child: _buildStepBody()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    final steps = ['Campaign', 'Targeting', 'Ad'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isDone = index < _currentStep;
          return Column(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isDone
                    ? Colors.green
                    : isActive
                        ? AppTheme.primaryLight
                        : Colors.grey.shade300,
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : Colors.grey.shade800,
                          fontSize: 11,
                        ),
                      ),
              ),
              SizedBox(height: 0.3.h),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isActive
                      ? AppTheme.textPrimaryLight
                      : Colors.grey.shade600,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildCampaignStep();
      case 1:
        return _buildTargetingStep();
      case 2:
      default:
        return _buildAdStep();
    }
  }

  Widget _buildCampaignStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campaign basics',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _campaignNameController,
            decoration: const InputDecoration(
              labelText: 'Campaign name',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 2.h),
          DropdownButtonFormField<String>(
            value: _objective,
            decoration: const InputDecoration(
              labelText: 'Objective',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: VotteryAdsConstants.campaignObjectiveReach,
                child: Text('Reach'),
              ),
              DropdownMenuItem(
                value: VotteryAdsConstants.campaignObjectiveTraffic,
                child: Text('Traffic'),
              ),
              DropdownMenuItem(
                value: VotteryAdsConstants.campaignObjectiveAppInstalls,
                child: Text('App installs'),
              ),
              DropdownMenuItem(
                value: VotteryAdsConstants.campaignObjectiveConversions,
                child: Text('Conversions'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _objective = v);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTargetingStep() {
    final allCountries = <String>[
      'US',
      'GB',
      'CA',
      'AU',
      'DE',
      'FR',
      'IN',
      'BR',
      'NG',
      'ZA',
      'JP',
      'MX',
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Targeting & placements',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _adGroupNameController,
            decoration: const InputDecoration(
              labelText: 'Ad group name',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Zones (1–8)',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Wrap(
            spacing: 2.w,
            children: VotteryAdsConstants.zoneValues.map((z) {
              final selected = _targetZones.contains(z);
              return FilterChip(
                label: Text('Zone $z'),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _targetZones.add(z);
                    } else {
                      _targetZones.remove(z);
                    }
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),
          Text(
            'Countries (optional)',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Wrap(
            spacing: 2.w,
            children: allCountries.map((code) {
              final selected = _targetCountries.contains(code);
              return FilterChip(
                label: Text(code),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _targetCountries.add(code);
                    } else {
                      _targetCountries.remove(code);
                    }
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),
          Text(
            'Regions within a country (optional)',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          ..._regions.map((r) => _buildRegionRow(r)).toList(),
          TextButton(
            onPressed: () {
              setState(() {
                _regions.add(
                  _RegionRow(countryIso: 'US', regionCode: '', regionName: ''),
                );
              });
            },
            child: const Text('Add region'),
          ),
          SizedBox(height: 2.h),
          DropdownButtonFormField<String>(
            value: _placementMode,
            decoration: const InputDecoration(
              labelText: 'Placement mode',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'automatic',
                child: Text('Automatic placements'),
              ),
              DropdownMenuItem(
                value: 'manual',
                child: Text('Manual placements'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _placementMode = v);
              }
            },
          ),
          if (_placementMode == 'manual') ...[
            SizedBox(height: 2.h),
            Text(
              'Placement slots',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Wrap(
              spacing: 2.w,
              children: [
                ...VotteryAdsConstants.placementSlotsTiktok,
                ...VotteryAdsConstants.placementSlotsFacebook,
              ].map((slotKey) {
                final selected = _placementSlots.contains(slotKey);
                return FilterChip(
                  label: Text(
                    VotteryAdsConstants.placementSlotLabels[slotKey] ??
                        slotKey,
                  ),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _placementSlots.add(slotKey);
                      } else {
                        _placementSlots.remove(slotKey);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
          SizedBox(height: 2.h),
          Text(
            'Daily budget (cents)',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 500 for \$5.00',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(
              text: _dailyBudgetCents?.toString() ?? '',
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              setState(() => _dailyBudgetCents = parsed);
            },
          ),
          SizedBox(height: 1.h),
          Text(
            'Lifetime budget (cents, optional)',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Optional',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(
              text: _lifetimeBudgetCents?.toString() ?? '',
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              setState(() => _lifetimeBudgetCents = parsed);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegionRow(_RegionRow row) {
    final allCountries = <String>[
      'US',
      'GB',
      'CA',
      'AU',
      'DE',
      'FR',
      'IN',
      'BR',
      'NG',
      'ZA',
      'JP',
      'MX',
    ];
    return Padding(
      padding: EdgeInsets.only(top: 1.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: row.countryIso,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
              ),
              items: allCountries
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => row.countryIso = v);
                }
              },
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Region code',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: row.regionCode),
              onChanged: (v) => row.regionCode = v,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            flex: 3,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Region name',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: row.regionName),
              onChanged: (v) => row.regionName = v,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() => _regions.remove(row));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ad creative',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _adNameController,
            decoration: const InputDecoration(
              labelText: 'Ad name',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 2.h),
          DropdownButtonFormField<String>(
            value: _adType,
            decoration: const InputDecoration(
              labelText: 'Ad type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: VotteryAdsConstants.adTypeDisplay,
                child: Text('Display (normal)'),
              ),
              DropdownMenuItem(
                value: VotteryAdsConstants.adTypeVideo,
                child: Text('Video (normal)'),
              ),
              DropdownMenuItem(
                value: VotteryAdsConstants.adTypeParticipatory,
                child: Text('Participatory / gamified'),
              ),
              DropdownMenuItem(
                value: VotteryAdsConstants.adTypeSpark,
                child: Text('Spark (boost post)'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _adType = v);
              }
            },
          ),
          SizedBox(height: 2.h),
          if (_adType != VotteryAdsConstants.adTypeSpark) ...[
            TextField(
              controller: _headlineController,
              decoration: const InputDecoration(
                labelText: 'Headline',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 1.h),
            if (_adType == VotteryAdsConstants.adTypeVideo ||
                _adType == VotteryAdsConstants.adTypeParticipatory)
              TextField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL',
                  border: OutlineInputBorder(),
                ),
              ),
          ],
          if (_adType == VotteryAdsConstants.adTypeParticipatory) ...[
            SizedBox(height: 2.h),
            Text(
              'Election ID (link to election)',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter election ID (temporary manual field)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _electionId = v.trim().isEmpty ? null : v,
            ),
            SizedBox(height: 1.h),
            SwitchListTile(
              value: _enableGamification,
              title: const Text('Enable gamification (prize pool, XP)'),
              onChanged: (val) {
                setState(() => _enableGamification = val);
              },
            ),
            if (_enableGamification)
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prize pool (cents)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  setState(() => _prizePoolCents = parsed);
                },
              ),
          ],
          if (_adType == VotteryAdsConstants.adTypeSpark) ...[
            SizedBox(height: 2.h),
            Text(
              'Spark source post ID',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter Moments/Jolts post ID (temporary manual field)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  _sparkPostId = v.trim().isEmpty ? null : v,
            ),
            SizedBox(height: 1.h),
            DropdownButtonFormField<String>(
              value: _sparkSourceType,
              decoration: const InputDecoration(
                labelText: 'Source type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'moment',
                  child: Text('Moment'),
                ),
                DropdownMenuItem(
                  value: 'jolt',
                  child: Text('Jolt'),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _sparkSourceType = v);
                }
              },
            ),
          ],
          SizedBox(height: 2.h),
          TextField(
            controller: _ctaLabelController,
            decoration: const InputDecoration(
              labelText: 'CTA label',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _ctaUrlController,
            decoration: const InputDecoration(
              labelText: 'CTA URL',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Bid (cents)',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 500 for \$5.00',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(
              text: _bidAmountCents.toString(),
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              setState(() => _bidAmountCents = parsed ?? 0);
            },
          ),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            value: _pricingModel,
            decoration: const InputDecoration(
              labelText: 'Pricing model',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: VotteryAdsConstants.pricingModelCpm,
                child: Text('CPM'),
              ),
              DropdownMenuItem(
                value: VotteryAdsConstants.pricingModelCpc,
                child: Text('CPC'),
              ),
              DropdownMenuItem(
                value: VotteryAdsConstants.pricingModelOcpm,
                child: Text('oCPM'),
              ),
              DropdownMenuItem(
                value: VotteryAdsConstants.pricingModelCpv,
                child: Text('CPV'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _pricingModel = v);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _currentStep == 0 ? null : _prevStep,
              child: const Text('Back'),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_currentStep == 2 ? 'Launch' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionRow {
  _RegionRow({
    required this.countryIso,
    required this.regionCode,
    required this.regionName,
  });

  String countryIso;
  String regionCode;
  String regionName;
}

