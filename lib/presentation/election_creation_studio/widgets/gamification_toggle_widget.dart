import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class GamificationToggleWidget extends StatefulWidget {
  final bool isGamified;
  final double prizePoolAmount;
  final Map<String, double> regionalPrizeAmounts;
  final Function(bool) onGamificationChanged;
  final Function(double) onPrizePoolChanged;
  final Function(Map<String, double>) onRegionalPrizesChanged;

  const GamificationToggleWidget({
    super.key,
    required this.isGamified,
    required this.prizePoolAmount,
    required this.regionalPrizeAmounts,
    required this.onGamificationChanged,
    required this.onPrizePoolChanged,
    required this.onRegionalPrizesChanged,
  });

  @override
  State<GamificationToggleWidget> createState() =>
      _GamificationToggleWidgetState();
}

class _GamificationToggleWidgetState extends State<GamificationToggleWidget> {
  late Map<String, double> _regionalPrizes;
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _prizePoolController = TextEditingController();
  String _prizeDistributionType = 'general'; // general or regional

  final Map<String, String> _zoneNames = {
    'zone_1_us_canada': 'US & Canada',
    'zone_2_western_europe': 'Western Europe',
    'zone_3_eastern_europe': 'Eastern Europe',
    'zone_4_africa': 'Africa',
    'zone_5_latin_america': 'Latin America',
    'zone_6_middle_east_asia': 'Middle East & Asia',
    'zone_7_australasia': 'Australasia',
    'zone_8_china_hong_kong': 'China & Hong Kong',
  };

  @override
  void initState() {
    super.initState();
    _regionalPrizes = Map.from(widget.regionalPrizeAmounts);
    _prizePoolController.text = widget.prizePoolAmount.toStringAsFixed(2);

    _zoneNames.forEach((key, value) {
      _controllers[key] = TextEditingController(
        text: (_regionalPrizes[key] ?? 0.0).toStringAsFixed(2),
      );
    });
  }

  @override
  void dispose() {
    _prizePoolController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gamification Settings',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildGamificationToggle(),
          if (widget.isGamified) ...[
            SizedBox(height: 2.h),
            _buildPrizeDistributionSelector(),
            SizedBox(height: 2.h),
            if (_prizeDistributionType == 'general')
              _buildGeneralPrizePool()
            else
              _buildRegionalPrizePools(),
            SizedBox(height: 2.h),
            _buildGamificationRules(),
          ],
        ],
      ),
    );
  }

  Widget _buildGamificationToggle() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: widget.isGamified
            ? AppTheme.accentLight.withAlpha(26)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: widget.isGamified
              ? AppTheme.accentLight
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.isGamified ? Icons.casino : Icons.how_to_vote,
            color: widget.isGamified ? AppTheme.accentLight : Colors.grey,
            size: 8.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isGamified ? 'Gamified Election' : 'Standard Election',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: widget.isGamified
                        ? AppTheme.accentLight
                        : AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  widget.isGamified
                      ? 'Voters can win prizes through lottery draws'
                      : 'No rewards or winning prizes for voters',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.isGamified,
            onChanged: widget.onGamificationChanged,
            activeThumbColor: AppTheme.accentLight,
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeDistributionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prize Distribution Type',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: _buildDistributionOption(
                'general',
                'General Prize Pool',
                'Single prize pool for all participants',
                Icons.emoji_events,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildDistributionOption(
                'regional',
                'Regional Prizes',
                'Different prizes for 8 zones',
                Icons.public,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistributionOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _prizeDistributionType == value;

    return InkWell(
      onTap: () => setState(() => _prizeDistributionType = value),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentLight.withAlpha(26) : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppTheme.accentLight : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentLight : Colors.grey,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.accentLight
                    : AppTheme.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 0.5.h),
            Text(
              description,
              style: TextStyle(
                fontSize: 9.sp,
                color: AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralPrizePool() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prize Pool Amount',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: _prizePoolController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Total Prize Pool (USD)',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            hintText: '0.00',
          ),
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            widget.onPrizePoolChanged(amount);
          },
        ),
      ],
    );
  }

  Widget _buildRegionalPrizePools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regional Prize Pools',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Configure different prize pools for each regional zone',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
        ),
        SizedBox(height: 2.h),
        ..._zoneNames.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: 1.5.h),
            child: TextField(
              controller: _controllers[entry.key],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: entry.value,
                prefixIcon: Icon(Icons.location_on, size: 5.w),
                suffixText: 'USD',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                _regionalPrizes[entry.key] = amount;
                widget.onRegionalPrizesChanged(_regionalPrizes);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGamificationRules() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Gamification Rules',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildRuleItem('Lottery draw occurs after election ends'),
          _buildRuleItem('All voters automatically entered'),
          _buildRuleItem('Winners selected randomly'),
          _buildRuleItem('Prizes distributed via Stripe'),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 4.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.sp, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
