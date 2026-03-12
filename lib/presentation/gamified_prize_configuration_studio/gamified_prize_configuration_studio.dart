import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/monetary_prize_form_widget.dart';
import './widgets/multiple_winners_panel_widget.dart';
import './widgets/non_monetary_prize_form_widget.dart';
import './widgets/prize_preview_widget.dart';
import './widgets/prize_type_selector_widget.dart';
import './widgets/revenue_share_form_widget.dart';
import './widgets/sequential_reveal_settings_widget.dart';

class GamifiedPrizeConfigurationStudio extends StatefulWidget {
  final String? electionId;
  final Function(Map<String, dynamic>)? onConfigSaved;

  const GamifiedPrizeConfigurationStudio({
    super.key,
    this.electionId,
    this.onConfigSaved,
  });

  @override
  State<GamifiedPrizeConfigurationStudio> createState() =>
      _GamifiedPrizeConfigurationStudioState();
}

class _GamifiedPrizeConfigurationStudioState
    extends State<GamifiedPrizeConfigurationStudio> {
  final GamificationService _gamificationService = GamificationService.instance;

  String _selectedPrizeType = 'monetary';
  bool _multipleWinnersEnabled = false;
  bool _sequentialRevealEnabled = true;
  int _revealDelaySeconds = 5;
  String _animationStyle = 'dramatic';

  // Monetary prize data
  double _monetaryAmount = 0.0;
  String _currency = 'USD';
  bool _regionalPricingEnabled = false;
  Map<String, double> _regionalAmounts = {};

  // Non-monetary prize data
  String _prizeTitle = '';
  String _prizeDescription = '';
  double _prizeValue = 0.0;
  List<String> _prizeImageUrls = [];

  // Revenue sharing data
  double _projectedRevenue = 0.0;
  double _sharePercentage = 50.0;

  // Multiple winners data
  List<Map<String, dynamic>> _winnerSlots = [];

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.electionId != null) {
      _loadExistingConfig();
    }
  }

  Future<void> _loadExistingConfig() async {
    // Load existing prize configuration if editing
    // Implementation depends on your service
  }

  void _onPrizeTypeChanged(String prizeType) {
    setState(() {
      _selectedPrizeType = prizeType;
      _errorMessage = null;
    });
  }

  void _onMonetaryDataChanged(Map<String, dynamic> data) {
    setState(() {
      _monetaryAmount = data['amount'] ?? 0.0;
      _currency = data['currency'] ?? 'USD';
      _regionalPricingEnabled = data['regionalPricingEnabled'] ?? false;
      _regionalAmounts = Map<String, double>.from(
        data['regionalAmounts'] ?? {},
      );
    });
  }

  void _onNonMonetaryDataChanged(Map<String, dynamic> data) {
    setState(() {
      _prizeTitle = data['title'] ?? '';
      _prizeDescription = data['description'] ?? '';
      _prizeValue = data['value'] ?? 0.0;
      _prizeImageUrls = List<String>.from(data['imageUrls'] ?? []);
    });
  }

  void _onRevenueShareDataChanged(Map<String, dynamic> data) {
    setState(() {
      _projectedRevenue = data['projectedRevenue'] ?? 0.0;
      _sharePercentage = data['sharePercentage'] ?? 50.0;
    });
  }

  void _onMultipleWinnersChanged(
    bool enabled,
    List<Map<String, dynamic>> slots,
  ) {
    setState(() {
      _multipleWinnersEnabled = enabled;
      _winnerSlots = slots;
      _errorMessage = _validateWinnerSlots();
    });
  }

  void _onSequentialRevealChanged(
    bool enabled,
    int delaySeconds,
    String style,
  ) {
    setState(() {
      _sequentialRevealEnabled = enabled;
      _revealDelaySeconds = delaySeconds;
      _animationStyle = style;
    });
  }

  String? _validateWinnerSlots() {
    if (!_multipleWinnersEnabled) return null;

    if (_winnerSlots.isEmpty) {
      return 'At least one winner slot is required';
    }

    double totalPercentage = 0.0;
    for (var slot in _winnerSlots) {
      totalPercentage += (slot['percentage'] as double? ?? 0.0);
    }

    if (totalPercentage > 100.0) {
      return 'Total percentage exceeds 100% (Current: ${totalPercentage.toStringAsFixed(1)}%)';
    }

    if (totalPercentage < 100.0) {
      return 'Total percentage must equal 100% (Current: ${totalPercentage.toStringAsFixed(1)}%)';
    }

    return null;
  }

  Future<void> _saveConfiguration() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Validate
      final validationError = _validateConfiguration();
      if (validationError != null) {
        setState(() {
          _errorMessage = validationError;
          _isSaving = false;
        });
        return;
      }

      // Build configuration
      final config = _buildConfiguration();

      // Save via service
      final success = await _gamificationService.savePrizeConfiguration(
        electionId: widget.electionId!,
        config: config,
      );

      if (success) {
        widget.onConfigSaved?.call(config);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Prize configuration saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to save configuration';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String? _validateConfiguration() {
    if (_selectedPrizeType == 'monetary' && _monetaryAmount <= 0) {
      return 'Prize amount must be greater than 0';
    }

    if (_selectedPrizeType == 'non_monetary' && _prizeTitle.isEmpty) {
      return 'Prize title is required';
    }

    if (_selectedPrizeType == 'revenue_sharing' && _projectedRevenue <= 0) {
      return 'Projected revenue must be greater than 0';
    }

    if (_multipleWinnersEnabled) {
      return _validateWinnerSlots();
    }

    return null;
  }

  Map<String, dynamic> _buildConfiguration() {
    Map<String, dynamic>? monetaryConfig;
    Map<String, dynamic>? nonMonetaryConfig;
    Map<String, dynamic>? revenueShareConfig;

    if (_selectedPrizeType == 'monetary') {
      monetaryConfig = {
        'amount': _monetaryAmount,
        'currency': _currency,
        'regional_pricing': _regionalPricingEnabled ? _regionalAmounts : null,
      };
    } else if (_selectedPrizeType == 'non_monetary') {
      nonMonetaryConfig = {
        'title': _prizeTitle,
        'description': _prizeDescription,
        'value': _prizeValue,
        'image_urls': _prizeImageUrls,
      };
    } else if (_selectedPrizeType == 'revenue_sharing') {
      revenueShareConfig = {
        'projected_revenue': _projectedRevenue,
        'share_percentage': _sharePercentage,
      };
    }

    return {
      'prize_type': _selectedPrizeType,
      'monetary_config': monetaryConfig,
      'non_monetary_config': nonMonetaryConfig,
      'revenue_share_config': revenueShareConfig,
      'multiple_winners_enabled': _multipleWinnersEnabled,
      'winner_count': _multipleWinnersEnabled ? _winnerSlots.length : 1,
      'winner_slots': _multipleWinnersEnabled ? _winnerSlots : null,
      'sequential_reveal_enabled': _sequentialRevealEnabled,
      'reveal_delay_seconds': _revealDelaySeconds,
      'animation_style': _animationStyle,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Prize Configuration',
        variant: CustomAppBarVariant.withBack,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Configure Prize Settings',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'Set up prize type, amounts, and winner configuration',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 3.h),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: EdgeInsets.all(2.w),
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20.sp),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Prize Type Selector
            PrizeTypeSelectorWidget(
              selectedType: _selectedPrizeType,
              onTypeChanged: _onPrizeTypeChanged,
            ),
            SizedBox(height: 3.h),

            // Prize Form based on type
            if (_selectedPrizeType == 'monetary')
              MonetaryPrizeFormWidget(
                amount: _monetaryAmount,
                currency: _currency,
                regionalPricingEnabled: _regionalPricingEnabled,
                regionalAmounts: _regionalAmounts,
                onDataChanged: _onMonetaryDataChanged,
              ),

            if (_selectedPrizeType == 'non_monetary')
              NonMonetaryPrizeFormWidget(
                title: _prizeTitle,
                description: _prizeDescription,
                value: _prizeValue,
                imageUrls: _prizeImageUrls,
                onDataChanged: _onNonMonetaryDataChanged,
              ),

            if (_selectedPrizeType == 'revenue_sharing')
              RevenueShareFormWidget(
                projectedRevenue: _projectedRevenue,
                sharePercentage: _sharePercentage,
                onDataChanged: _onRevenueShareDataChanged,
              ),

            SizedBox(height: 3.h),

            // Multiple Winners Panel
            MultipleWinnersPanelWidget(
              enabled: _multipleWinnersEnabled,
              winnerSlots: _winnerSlots,
              prizeType: _selectedPrizeType,
              totalPrizeAmount: _selectedPrizeType == 'monetary'
                  ? _monetaryAmount
                  : _selectedPrizeType == 'revenue_sharing'
                  ? _projectedRevenue
                  : _prizeValue,
              onChanged: _onMultipleWinnersChanged,
            ),
            SizedBox(height: 3.h),

            // Sequential Reveal Settings
            if (_multipleWinnersEnabled)
              SequentialRevealSettingsWidget(
                enabled: _sequentialRevealEnabled,
                delaySeconds: _revealDelaySeconds,
                animationStyle: _animationStyle,
                onChanged: _onSequentialRevealChanged,
              ),

            SizedBox(height: 3.h),

            // Prize Preview
            PrizePreviewWidget(
              prizeType: _selectedPrizeType,
              config: _buildConfiguration(),
            ),
            SizedBox(height: 3.h),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveConfiguration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20.sp,
                        width: 20.sp,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Save Configuration',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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