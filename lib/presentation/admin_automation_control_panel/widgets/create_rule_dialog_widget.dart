import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/admin_automation_rules_service.dart';

class CreateAutomationRuleDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const CreateAutomationRuleDialog({super.key, required this.onCreated});

  @override
  State<CreateAutomationRuleDialog> createState() => _CreateAutomationRuleDialogState();
}

class _CreateAutomationRuleDialogState extends State<CreateAutomationRuleDialog> {
  int _currentStep = 0;
  AutomationRuleType _selectedType = AutomationRuleType.festivalMode;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _scheduleController = TextEditingController(text: '0 9 * * *');
  final Map<String, bool> _selectedActions = {};
  bool _isCreating = false;

  final Map<AutomationRuleType, List<String>> _availableActions = {
    AutomationRuleType.festivalMode: ['increase_vp_multipliers', 'enable_special_badges', 'show_festival_banner', 'activate_bonus_quests'],
    AutomationRuleType.fraudProneRegionPause: ['pause_elections_in_zones', 'increase_verification_requirements', 'send_admin_alert'],
    AutomationRuleType.retentionCampaign: ['send_push_notification', 'offer_vp_bonus', 'show_personalized_content', 'enable_discount_code'],
    AutomationRuleType.dynamicPricing: ['adjust_subscription_price', 'update_cpe_rates', 'notify_advertisers'],
    AutomationRuleType.maintenanceMode: ['pause_all_elections', 'show_maintenance_banner', 'send_user_notifications'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  Future<void> _createRule() async {
    setState(() => _isCreating = true);
    try {
      final actions = _selectedActions.entries
          .where((e) => e.value)
          .map((e) => {'action': e.key})
          .toList();
      final ok = await AdminAutomationRulesService.createRule({
        'rule_id': 'rule_${DateTime.now().millisecondsSinceEpoch}',
        'rule_type': _selectedType.name,
        'rule_name': _nameController.text.trim().isEmpty ? '${_selectedType.name} Rule' : _nameController.text.trim(),
        'conditions': {},
        'actions': actions,
        'schedule': _scheduleController.text.trim(),
        'is_enabled': false,
      });
      if (mounted && ok) {
        Navigator.pop(context);
        widget.onCreated();
      } else if (mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create automation rule'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 80.h, maxWidth: 90.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: const Color(0xFF6B4EFF), size: 18.sp),
                  SizedBox(width: 2.w),
                  Text('Create Automation Rule', style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                onStepTapped: (step) => setState(() => _currentStep = step),
                onStepContinue: () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    _createRule();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  } else {
                    Navigator.pop(context);
                  }
                },
                controlsBuilder: (context, details) => Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _isCreating ? null : details.onStepContinue,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EFF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
                        child: _isCreating && _currentStep == 3
                            ? SizedBox(width: 14.sp, height: 14.sp, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_currentStep == 3 ? 'Create' : 'Next', style: GoogleFonts.inter(fontSize: 11.sp)),
                      ),
                      SizedBox(width: 2.w),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text(_currentStep == 0 ? 'Cancel' : 'Back', style: GoogleFonts.inter(fontSize: 11.sp)),
                      ),
                    ],
                  ),
                ),
                steps: [
                  Step(
                    title: Text('Rule Type', style: GoogleFonts.inter(fontSize: 12.sp)),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    content: Column(
                      children: AutomationRuleType.values.map((type) => RadioListTile<AutomationRuleType>(
                        title: Text(_getTypeLabel(type), style: GoogleFonts.inter(fontSize: 12.sp)),
                        value: type,
                        groupValue: _selectedType,
                        onChanged: (v) => setState(() { _selectedType = v!; _selectedActions.clear(); }),
                        activeColor: const Color(0xFF6B4EFF),
                        dense: true,
                      )).toList(),
                    ),
                  ),
                  Step(
                    title: Text('Configuration', style: GoogleFonts.inter(fontSize: 12.sp)),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rule Name', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                        SizedBox(height: 0.5.h),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter rule name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                          ),
                          style: GoogleFonts.inter(fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: Text('Actions', style: GoogleFonts.inter(fontSize: 12.sp)),
                    isActive: _currentStep >= 2,
                    state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                    content: Column(
                      children: (_availableActions[_selectedType] ?? []).map((action) => CheckboxListTile(
                        title: Text(action.replaceAll('_', ' '), style: GoogleFonts.inter(fontSize: 11.sp)),
                        value: _selectedActions[action] ?? false,
                        onChanged: (v) => setState(() => _selectedActions[action] = v ?? false),
                        activeColor: const Color(0xFF6B4EFF),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      )).toList(),
                    ),
                  ),
                  Step(
                    title: Text('Schedule', style: GoogleFonts.inter(fontSize: 12.sp)),
                    isActive: _currentStep >= 3,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cron Expression', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                        SizedBox(height: 0.5.h),
                        TextField(
                          controller: _scheduleController,
                          decoration: InputDecoration(
                            hintText: '0 9 * * * (daily at 9 AM)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                          ),
                          style: GoogleFonts.inter(fontSize: 12.sp),
                        ),
                        SizedBox(height: 1.h),
                        Text('Examples:', style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600)),
                        Text('• 0 9 * * * = Daily at 9 AM', style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade600)),
                        Text('• */30 * * * * = Every 30 min', style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade600)),
                        Text('• 0 0 * * 1 = Every Monday', style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(AutomationRuleType type) {
    switch (type) {
      case AutomationRuleType.festivalMode: return 'Festival Mode';
      case AutomationRuleType.fraudProneRegionPause: return 'Fraud-Prone Region Pause';
      case AutomationRuleType.retentionCampaign: return 'Retention Campaign';
      case AutomationRuleType.dynamicPricing: return 'Dynamic Pricing';
      case AutomationRuleType.maintenanceMode: return 'Maintenance Mode';
    }
  }
}