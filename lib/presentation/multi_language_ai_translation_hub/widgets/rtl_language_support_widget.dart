import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RtlLanguageSupportWidget extends StatefulWidget {
  const RtlLanguageSupportWidget({super.key});

  @override
  State<RtlLanguageSupportWidget> createState() =>
      _RtlLanguageSupportWidgetState();
}

class _RtlLanguageSupportWidgetState extends State<RtlLanguageSupportWidget> {
  final List<Map<String, dynamic>> _rtlLanguages = [
    {
      'code': 'ar',
      'name': 'Arabic',
      'nativeName': 'العربية',
      'flag': '🇸🇦',
      'users': 1250,
      'enabled': true,
    },
    {
      'code': 'he',
      'name': 'Hebrew',
      'nativeName': 'עברית',
      'flag': '🇮🇱',
      'users': 450,
      'enabled': true,
    },
    {
      'code': 'fa',
      'name': 'Persian',
      'nativeName': 'فارسی',
      'flag': '🇮🇷',
      'users': 320,
      'enabled': true,
    },
    {
      'code': 'ur',
      'name': 'Urdu',
      'nativeName': 'اردو',
      'flag': '🇵🇰',
      'users': 280,
      'enabled': true,
    },
  ];

  String _selectedLanguage = 'ar';
  String _sampleText = 'مرحبا بك في منصة التصويت';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RTL Language Support',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.purple.withAlpha(26),
            borderRadius: BorderRadius.circular(3.w),
            border: Border.all(color: Colors.purple.withAlpha(51), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.purple, size: 24.sp),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'RTL (Right-to-Left) languages require special layout adaptation for proper text rendering and UI alignment.',
                  style: TextStyle(fontSize: 12.sp, color: Colors.purple),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'Supported RTL Languages',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _rtlLanguages.length,
          itemBuilder: (context, index) {
            final language = _rtlLanguages[index];
            final isSelected = _selectedLanguage == language['code'];

            return Card(
              margin: EdgeInsets.only(bottom: 2.h),
              color: isSelected
                  ? theme.colorScheme.primary.withAlpha(26)
                  : null,
              child: ListTile(
                leading: Text(
                  language['flag'],
                  style: TextStyle(fontSize: 24.sp),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language['name'],
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            language['nativeName'],
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(26),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Text(
                        'RTL',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '${language['users']} active users',
                  style: TextStyle(fontSize: 11.sp),
                ),
                trailing: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  setState(() {
                    _selectedLanguage = language['code'];
                    _updateSampleText(language['code']);
                  });
                },
              ),
            );
          },
        ),
        SizedBox(height: 3.h),
        Text(
          'RTL Preview',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.preview,
                    color: theme.colorScheme.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Text Direction: Right-to-Left',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2.w),
                  border: Border.all(color: Colors.grey.withAlpha(51)),
                ),
                child: Text(
                  _sampleText,
                  style: TextStyle(fontSize: 16.sp, height: 1.5),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'Layout Adaptation Features',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        _buildFeatureItem(
          icon: Icons.format_align_right,
          title: 'Automatic Text Alignment',
          description:
              'Text automatically aligns to the right for RTL languages',
        ),
        _buildFeatureItem(
          icon: Icons.swap_horiz,
          title: 'Mirrored UI Elements',
          description: 'Icons and navigation elements flip horizontally',
        ),
        _buildFeatureItem(
          icon: Icons.text_fields,
          title: 'Bidirectional Text Support',
          description: 'Handles mixed LTR and RTL content seamlessly',
        ),
        _buildFeatureItem(
          icon: Icons.format_textdirection_r_to_l,
          title: 'Direction Controls',
          description: 'Manual override options for text direction',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateSampleText(String languageCode) {
    final samples = {
      'ar': 'مرحبا بك في منصة التصويت',
      'he': 'ברוכים הבאים לפלטפורמת ההצבעה',
      'fa': 'به پلتفرم رای گیری خوش آمدید',
      'ur': 'ووٹنگ پلیٹ فارم میں خوش آمدید',
    };

    _sampleText = samples[languageCode] ?? samples['ar']!;
  }
}
