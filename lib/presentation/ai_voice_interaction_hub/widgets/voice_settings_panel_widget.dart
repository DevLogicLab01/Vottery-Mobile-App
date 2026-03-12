import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/ai_voice_service.dart';

/// Voice Settings Panel Widget
/// Language preferences, speech rate, and voice selection
class VoiceSettingsPanelWidget extends StatefulWidget {
  const VoiceSettingsPanelWidget({super.key});

  @override
  State<VoiceSettingsPanelWidget> createState() =>
      _VoiceSettingsPanelWidgetState();
}

class _VoiceSettingsPanelWidgetState extends State<VoiceSettingsPanelWidget> {
  double _speechRate = 0.5;
  double _pitch = 1.0;
  String _selectedLanguage = 'en-US';
  List<String> _availableLanguages = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableLanguages();
  }

  Future<void> _loadAvailableLanguages() async {
    final languages = await AIVoiceService.getAvailableLanguages();
    if (mounted) {
      setState(() {
        _availableLanguages = languages;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      padding: EdgeInsets.all(5.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.sp,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Voice Settings',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 3.h),
          _buildLanguageSelector(),
          SizedBox(height: 2.h),
          _buildSpeechRateSlider(),
          SizedBox(height: 2.h),
          _buildPitchSlider(),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Done',
                style: TextStyle(fontSize: 14.sp, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: DropdownButton<String>(
            value: _selectedLanguage,
            isExpanded: true,
            underline: const SizedBox(),
            items: _availableLanguages.isEmpty
                ? [
                    const DropdownMenuItem(
                      value: 'en-US',
                      child: Text('English (US)'),
                    ),
                  ]
                : _availableLanguages
                      .map(
                        (lang) =>
                            DropdownMenuItem(value: lang, child: Text(lang)),
                      )
                      .toList(),
            onChanged: (value) async {
              if (value != null) {
                setState(() => _selectedLanguage = value);
                await AIVoiceService.setLanguage(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpeechRateSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Speech Rate',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            Text(
              '${(_speechRate * 100).round()}%',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        Slider(
          value: _speechRate,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: (value) async {
            setState(() => _speechRate = value);
            await AIVoiceService.setSpeechRate(value);
          },
        ),
      ],
    );
  }

  Widget _buildPitchSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pitch',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            Text(
              _pitch.toStringAsFixed(1),
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        Slider(
          value: _pitch,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          onChanged: (value) async {
            setState(() => _pitch = value);
            await AIVoiceService.setPitch(value);
          },
        ),
      ],
    );
  }
}
