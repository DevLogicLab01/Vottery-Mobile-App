import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/language_service.dart';
import '../../../services/supabase_service.dart';

class AutoDetectionSystemWidget extends StatefulWidget {
  const AutoDetectionSystemWidget({super.key});

  @override
  State<AutoDetectionSystemWidget> createState() =>
      _AutoDetectionSystemWidgetState();
}

class _AutoDetectionSystemWidgetState extends State<AutoDetectionSystemWidget> {
  final LanguageService _languageService = LanguageService.instance;
  final _client = SupabaseService.instance.client;

  bool _autoDetectionEnabled = true;
  String _detectedLanguage = 'en';
  String _manualOverride = '';
  Map<String, dynamic> _learningStats = {};

  @override
  void initState() {
    super.initState();
    _loadAutoDetectionSettings();
    _detectDeviceLanguage();
  }

  Future<void> _loadAutoDetectionSettings() async {
    try {
      final preference = await _languageService.getUserLanguagePreference();

      if (preference != null && mounted) {
        setState(() {
          _autoDetectionEnabled = preference['auto_detect'] ?? true;
          _manualOverride = preference['language_code'] ?? '';
        });
      }

      // Load learning statistics
      final stats = await _client.rpc('get_language_learning_stats');

      if (mounted) {
        setState(() => _learningStats = stats ?? {});
      }
    } catch (e) {
      debugPrint('Load auto-detection settings error: $e');
    }
  }

  void _detectDeviceLanguage() {
    // Get device locale
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    setState(() => _detectedLanguage = locale.languageCode);
  }

  Future<void> _toggleAutoDetection(bool enabled) async {
    try {
      await _languageService.saveLanguagePreference(
        languageCode: _manualOverride.isEmpty
            ? _detectedLanguage
            : _manualOverride,
        autoDetect: enabled,
      );

      setState(() => _autoDetectionEnabled = enabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled ? '✓ Auto-detection enabled' : 'Auto-detection disabled',
            ),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Toggle auto-detection error: $e');
    }
  }

  Future<void> _setManualOverride(String languageCode) async {
    try {
      await _languageService.saveLanguagePreference(
        languageCode: languageCode,
        autoDetect: false,
      );

      setState(() {
        _manualOverride = languageCode;
        _autoDetectionEnabled = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Language preference saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Set manual override error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languages = _languageService.getSupportedLanguages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auto-Detection System',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3.w),
            border: Border.all(color: theme.colorScheme.outline.withAlpha(51)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Automatic Language Detection',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Detect user language from device locale',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoDetectionEnabled,
                    onChanged: _toggleAutoDetection,
                  ),
                ],
              ),
              if (_autoDetectionEnabled) ...[
                SizedBox(height: 2.h),
                Divider(height: 1.h),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
                    SizedBox(width: 2.w),
                    Text(
                      'Detected Language:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      _getLanguageName(_detectedLanguage),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'Manual Override',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        DropdownButtonFormField<String>(
          initialValue: _manualOverride.isEmpty ? null : _manualOverride,
          decoration: InputDecoration(
            labelText: 'Select Language',
            hintText: 'Choose a language manually',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.w),
            ),
          ),
          items: languages.map((lang) {
            return DropdownMenuItem<String>(
              value: lang['code'] as String?,
              child: Text('${lang['flag']} ${lang['name']}'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _setManualOverride(value);
            }
          },
        ),
        SizedBox(height: 3.h),
        Text(
          'Preference Learning',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(26),
            borderRadius: BorderRadius.circular(3.w),
            border: Border.all(color: Colors.blue.withAlpha(51), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: Colors.blue, size: 24.sp),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'AI learns from your language preferences to improve auto-detection accuracy over time.',
                      style: TextStyle(fontSize: 12.sp, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: _buildLearningStatItem(
                      label: 'Accuracy',
                      value:
                          '${(_learningStats['accuracy'] ?? 0.0 * 100).toStringAsFixed(0)}%',
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: _buildLearningStatItem(
                      label: 'Predictions',
                      value: '${_learningStats['total_predictions'] ?? 0}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLearningStatItem({
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    final languages = _languageService.getSupportedLanguages();
    final language = languages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {'name': 'Unknown'},
    );
    return language['name'];
  }
}
