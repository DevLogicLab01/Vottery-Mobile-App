import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/auth_service.dart';
import '../../services/payout_settings_service.dart';

/// Payout settings – same table (payout_settings) and intent as Web.
/// Preferred method, minimum threshold, auto payout, schedule.
class PayoutSettingsScreen extends StatefulWidget {
  const PayoutSettingsScreen({super.key});

  @override
  State<PayoutSettingsScreen> createState() => _PayoutSettingsScreenState();
}

class _PayoutSettingsScreenState extends State<PayoutSettingsScreen> {
  final PayoutSettingsService _service = PayoutSettingsService.instance;
  Map<String, dynamic>? _settings;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool _autoPayoutEnabled = false;
  double _minimumThreshold = 100.0;
  String _preferredMethod = 'bank_transfer';
  String _payoutSchedule = 'manual';
  final TextEditingController _thresholdController =
      TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!AuthService.instance.isAuthenticated) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _service.getPayoutSettings();
      setState(() {
        _settings = s;
        _autoPayoutEnabled = (s?['auto_payout_enabled'] ?? false) as bool;
        _minimumThreshold =
            (s?['minimum_payout_threshold'] ?? 100.0) is int
                ? (s!['minimum_payout_threshold'] as int).toDouble()
                : (s?['minimum_payout_threshold'] ?? 100.0) as double;
        _preferredMethod =
            s?['preferred_method']?.toString() ?? 'bank_transfer';
        _payoutSchedule = s?['payout_schedule']?.toString() ?? 'manual';
        _thresholdController.text = _minimumThreshold.toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final ok = await _service.updatePayoutSettings({
        'auto_payout_enabled': _autoPayoutEnabled,
        'minimum_payout_threshold': _minimumThreshold,
        'preferred_method': _preferredMethod,
        'payout_schedule': _payoutSchedule,
      });
      setState(() => _saving = false);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout settings saved.'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!ok) {
        setState(() => _error = 'Failed to save');
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Settings'),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red, fontSize: 12.sp),
                      ),
                    ),
                  SwitchListTile(
                    title: const Text('Enable automated payouts'),
                    subtitle: const Text(
                        'When balance reaches threshold, request payout automatically'),
                    value: _autoPayoutEnabled,
                    onChanged: (v) =>
                        setState(() => _autoPayoutEnabled = v),
                  ),
                  SizedBox(height: 1.h),
                  TextField(
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Minimum payout (\$)',
                      border: OutlineInputBorder(),
                    ),
                    controller: _thresholdController,
                    onChanged: (v) {
                      final n = double.tryParse(v);
                      if (n != null) setState(() => _minimumThreshold = n);
                    },
                  ),
                  SizedBox(height: 2.h),
                  const Text('Preferred method',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  SizedBox(height: 0.5.h),
                  DropdownButtonFormField<String>(
                    value: _preferredMethod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'bank_transfer', child: Text('Bank transfer')),
                      DropdownMenuItem(
                          value: 'gift_card', child: Text('Gift card')),
                      DropdownMenuItem(
                          value: 'stripe', child: Text('Stripe Connect')),
                    ],
                    onChanged: (v) =>
                        setState(() => _preferredMethod = v ?? 'bank_transfer'),
                  ),
                  SizedBox(height: 2.h),
                  const Text('Payout schedule',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  SizedBox(height: 0.5.h),
                  DropdownButtonFormField<String>(
                    value: _payoutSchedule,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'manual', child: Text('Manual')),
                      DropdownMenuItem(
                          value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(
                          value: 'monthly', child: Text('Monthly')),
                    ],
                    onChanged: (v) =>
                        setState(() => _payoutSchedule = v ?? 'manual'),
                  ),
                ],
              ),
            ),
    );
  }
}
