import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/content_distribution_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

/// Content Distribution Control Center – election vs social vs ad ratios.
/// Admin-only; aligns with Web content-distribution-control-center.
class ContentDistributionControlCenterScreen extends StatefulWidget {
  const ContentDistributionControlCenterScreen({super.key});

  @override
  State<ContentDistributionControlCenterScreen> createState() =>
      _ContentDistributionControlCenterScreenState();
}

class _ContentDistributionControlCenterScreenState
    extends State<ContentDistributionControlCenterScreen> {
  final ContentDistributionService _service =
      ContentDistributionService.instance;

  Map<String, dynamic>? _settings;
  bool _loading = true;
  bool _saving = false;
  double _electionPercent = 50;
  double _socialPercent = 50;
  bool _isEnabled = true;
  bool _emergencyFreeze = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await _service.getDistributionSettings();
      if (s != null) {
        _electionPercent = (s['election_content_percentage'] as num?)?.toDouble() ?? 50;
        _socialPercent = (s['social_media_percentage'] as num?)?.toDouble() ?? 50;
        _isEnabled = s['is_enabled'] as bool? ?? true;
        _emergencyFreeze = s['emergency_freeze'] as bool? ?? false;
      }
      setState(() {
        _settings = s;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePercentages() async {
    if ((_electionPercent + _socialPercent).round() != 100) return;
    setState(() => _saving = true);
    try {
      final ok = await _service.updateDistributionPercentages(
        electionPercentage: _electionPercent,
        socialMediaPercentage: _socialPercent,
      );
      if (ok) await _load();
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _toggleEnabled(bool v) async {
    setState(() => _saving = true);
    try {
      final ok = await _service.toggleDistributionSystem(v);
      if (ok) setState(() => _isEnabled = v);
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _toggleFreeze(bool v) async {
    setState(() => _saving = true);
    try {
      final ok = await _service.toggleEmergencyFreeze(v);
      if (ok) setState(() => _emergencyFreeze = v);
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: 'Content Distribution',
          variant: CustomAppBarVariant.standard,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.appBarTheme.foregroundColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Election vs social content ratios',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    SwitchListTile(
                      title: Text(
                        'Distribution system enabled',
                        style: GoogleFonts.inter(fontSize: 14.sp),
                      ),
                      subtitle: Text(
                        _isEnabled
                            ? 'Content mix is controlled by these settings'
                            : 'Content follows default algorithm',
                        style: GoogleFonts.inter(fontSize: 12.sp),
                      ),
                      value: _isEnabled,
                      onChanged: _saving ? null : _toggleEnabled,
                    ),
                    SwitchListTile(
                      title: Text(
                        'Emergency freeze',
                        style: GoogleFonts.inter(fontSize: 14.sp),
                      ),
                      subtitle: Text(
                        _emergencyFreeze
                            ? 'All distribution locked at current ratios'
                            : 'Freeze ratios during critical events',
                        style: GoogleFonts.inter(fontSize: 12.sp),
                      ),
                      value: _emergencyFreeze,
                      onChanged: _saving ? null : _toggleFreeze,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Election content: ${_electionPercent.round()}%',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _electionPercent,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '${_electionPercent.round()}%',
                      onChanged: (v) {
                        setState(() {
                          _electionPercent = v;
                          _socialPercent = 100 - v;
                        });
                      },
                    ),
                    Text(
                      'Social content: ${_socialPercent.round()}%',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _socialPercent,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '${_socialPercent.round()}%',
                      onChanged: (v) {
                        setState(() {
                          _socialPercent = v;
                          _electionPercent = 100 - v;
                        });
                      },
                    ),
                    SizedBox(height: 2.h),
                    FilledButton.icon(
                      onPressed: _saving || (_electionPercent + _socialPercent).round() != 100
                          ? null
                          : _savePercentages,
                      icon: _saving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save ratios'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
