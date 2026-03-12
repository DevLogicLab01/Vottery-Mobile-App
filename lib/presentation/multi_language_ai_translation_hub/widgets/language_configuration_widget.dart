import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/language_service.dart';
import '../../../services/supabase_service.dart';

class LanguageConfigurationWidget extends StatefulWidget {
  final VoidCallback onLanguageToggled;

  const LanguageConfigurationWidget({
    super.key,
    required this.onLanguageToggled,
  });

  @override
  State<LanguageConfigurationWidget> createState() =>
      _LanguageConfigurationWidgetState();
}

class _LanguageConfigurationWidgetState
    extends State<LanguageConfigurationWidget> {
  final LanguageService _languageService = LanguageService.instance;
  final _client = SupabaseService.instance.client;

  List<Map<String, dynamic>> _languages = [];
  Map<String, bool> _enabledLanguages = {};
  Map<String, double> _qualityScores = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    setState(() => _isLoading = true);

    try {
      final supportedLanguages = _languageService.getSupportedLanguages();

      // Load enabled status from database
      final response = await _client
          .from('active_translation_languages')
          .select();

      final enabledMap = <String, bool>{};
      final qualityMap = <String, double>{};

      for (var lang in response) {
        enabledMap[lang['language_code']] = lang['is_enabled'] ?? false;
        qualityMap[lang['language_code']] = (lang['quality_score'] ?? 0.0)
            .toDouble();
      }

      if (mounted) {
        setState(() {
          _languages = supportedLanguages;
          _enabledLanguages = enabledMap;
          _qualityScores = qualityMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load languages error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLanguage(String languageCode, bool enabled) async {
    try {
      await _client.from('active_translation_languages').upsert({
        'language_code': languageCode,
        'is_enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _enabledLanguages[languageCode] = enabled;
      });

      widget.onLanguageToggled();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Language enabled successfully'
                  : 'Language disabled successfully',
            ),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Toggle language error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update language status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredLanguages {
    if (_searchQuery.isEmpty) return _languages;

    return _languages.where((lang) {
      final name = lang['name'].toString().toLowerCase();
      final nativeName = lang['nativeName'].toString().toLowerCase();
      final code = lang['code'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          nativeName.contains(query) ||
          code.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language Configuration',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search languages...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.w),
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        SizedBox(height: 2.h),
        Text(
          '${_filteredLanguages.length} languages available',
          style: TextStyle(
            fontSize: 12.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredLanguages.length,
          itemBuilder: (context, index) {
            final language = _filteredLanguages[index];
            final code = language['code'];
            final isEnabled = _enabledLanguages[code] ?? false;
            final qualityScore = _qualityScores[code] ?? 0.0;

            return Card(
              margin: EdgeInsets.only(bottom: 2.h),
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
                          ),
                        ],
                      ),
                    ),
                    if (language['rtl'] == true)
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
                subtitle: qualityScore > 0
                    ? Row(
                        children: [
                          Icon(Icons.star, size: 14.sp, color: Colors.amber),
                          SizedBox(width: 1.w),
                          Text(
                            '${(qualityScore * 100).toStringAsFixed(0)}% quality',
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ],
                      )
                    : null,
                trailing: Switch(
                  value: isEnabled,
                  onChanged: (value) => _toggleLanguage(code, value),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
