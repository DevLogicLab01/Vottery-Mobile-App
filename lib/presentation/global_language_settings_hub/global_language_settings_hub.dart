import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/language_service.dart';
import '../../widgets/error_boundary_wrapper.dart';

class GlobalLanguageSettingsHub extends StatefulWidget {
  const GlobalLanguageSettingsHub({super.key});

  @override
  State<GlobalLanguageSettingsHub> createState() =>
      _GlobalLanguageSettingsHubState();
}

class _GlobalLanguageSettingsHubState extends State<GlobalLanguageSettingsHub> {
  final LanguageService _languageService = LanguageService.instance;

  String _selectedLanguage = 'en';
  bool _autoDetect = true;
  bool _rtlEnabled = false;
  String _dateFormat = 'MM/DD/YYYY';
  String _timeFormat = '12h';
  String _numberFormat = 'comma';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _allLanguages = [];
  List<Map<String, dynamic>> _filteredLanguages = [];
  final List<String> _favoriteLanguages = ['en', 'es', 'fr', 'de', 'zh-CN'];

  @override
  void initState() {
    super.initState();
    _loadLanguagePreferences();
    _allLanguages = _languageService.getSupportedLanguages();
    _filteredLanguages = _allLanguages;
  }

  Future<void> _loadLanguagePreferences() async {
    setState(() => _isLoading = true);

    final prefs = await _languageService.getUserLanguagePreference();
    if (prefs != null) {
      setState(() {
        _selectedLanguage = prefs['language_code'] ?? 'en';
        _autoDetect = prefs['auto_detect'] ?? true;
        _rtlEnabled = prefs['rtl_enabled'] ?? false;
        _dateFormat = prefs['date_format'] ?? 'MM/DD/YYYY';
        _timeFormat = prefs['time_format'] ?? '12h';
        _numberFormat = prefs['number_format'] ?? 'comma';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveLanguagePreference() async {
    setState(() => _isSaving = true);

    final success = await _languageService.saveLanguagePreference(
      languageCode: _selectedLanguage,
      autoDetect: _autoDetect,
      rtlEnabled: _rtlEnabled,
      dateFormat: _dateFormat,
      timeFormat: _timeFormat,
      numberFormat: _numberFormat,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Language preferences saved successfully'),
        ),
      );
    }
  }

  void _filterLanguages(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredLanguages = _allLanguages;
      } else {
        _filteredLanguages = _allLanguages.where((lang) {
          final name = lang['name'].toString().toLowerCase();
          final nativeName = lang['nativeName'].toString().toLowerCase();
          final code = lang['code'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) ||
              nativeName.contains(searchLower) ||
              code.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLangData = _allLanguages.firstWhere(
      (lang) => lang['code'] == _selectedLanguage,
      orElse: () => _allLanguages.first,
    );

    return ErrorBoundaryWrapper(
      screenName: 'GlobalLanguageSettingsHub',
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          title: Text(
            'Language Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveLanguagePreference,
                tooltip: 'Save preferences',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Language Status Header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            selectedLangData['flag'],
                            style: TextStyle(fontSize: 48.sp),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            selectedLangData['nativeName'],
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            selectedLangData['name'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              selectedLangData['rtl']
                                  ? 'RTL Layout'
                                  : 'LTR Layout',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Auto-detect toggle
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Card(
                        child: SwitchListTile(
                          title: const Text('Auto-detect language'),
                          subtitle: const Text(
                            'Use device locale automatically',
                          ),
                          value: _autoDetect,
                          onChanged: (value) {
                            setState(() => _autoDetect = value);
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Favorite Languages
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Favorite Languages',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    SizedBox(
                      height: 10.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        itemCount: _favoriteLanguages.length,
                        itemBuilder: (context, index) {
                          final langCode = _favoriteLanguages[index];
                          final lang = _allLanguages.firstWhere(
                            (l) => l['code'] == langCode,
                            orElse: () => _allLanguages.first,
                          );
                          final isSelected = _selectedLanguage == langCode;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLanguage = langCode;
                                _rtlEnabled = lang['rtl'];
                              });
                            },
                            child: Container(
                              width: 20.w,
                              margin: EdgeInsets.only(right: 2.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    lang['flag'],
                                    style: TextStyle(fontSize: 24.sp),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    lang['code'],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Search bar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: TextField(
                        onChanged: _filterLanguages,
                        decoration: InputDecoration(
                          hintText: 'Search languages...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Language list
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'All Languages (${_filteredLanguages.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredLanguages.length,
                      itemBuilder: (context, index) {
                        final lang = _filteredLanguages[index];
                        final isSelected = _selectedLanguage == lang['code'];

                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 0.5.h,
                          ),
                          child: ListTile(
                            leading: Text(
                              lang['flag'],
                              style: TextStyle(fontSize: 24.sp),
                            ),
                            title: Text(
                              lang['nativeName'],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(lang['name']),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedLanguage = lang['code'];
                                _rtlEnabled = lang['rtl'];
                              });
                            },
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 2.h),

                    // Regional Settings
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Regional Settings',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),

                    // Date format
                    Card(
                      margin: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 0.5.h,
                      ),
                      child: ListTile(
                        title: const Text('Date Format'),
                        subtitle: Text(_dateFormat),
                        trailing: DropdownButton<String>(
                          value: _dateFormat,
                          items: ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD']
                              .map(
                                (format) => DropdownMenuItem(
                                  value: format,
                                  child: Text(format),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _dateFormat = value);
                            }
                          },
                        ),
                      ),
                    ),

                    // Time format
                    Card(
                      margin: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 0.5.h,
                      ),
                      child: ListTile(
                        title: const Text('Time Format'),
                        subtitle: Text(
                          _timeFormat == '12h' ? '12-hour' : '24-hour',
                        ),
                        trailing: DropdownButton<String>(
                          value: _timeFormat,
                          items: ['12h', '24h']
                              .map(
                                (format) => DropdownMenuItem(
                                  value: format,
                                  child: Text(
                                    format == '12h' ? '12-hour' : '24-hour',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _timeFormat = value);
                            }
                          },
                        ),
                      ),
                    ),

                    // Number format
                    Card(
                      margin: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 0.5.h,
                      ),
                      child: ListTile(
                        title: const Text('Number Format'),
                        subtitle: Text(
                          _numberFormat == 'comma'
                              ? '1,234.56 (comma)'
                              : '1.234,56 (period)',
                        ),
                        trailing: DropdownButton<String>(
                          value: _numberFormat,
                          items: ['comma', 'period']
                              .map(
                                (format) => DropdownMenuItem(
                                  value: format,
                                  child: Text(
                                    format == 'comma' ? 'Comma' : 'Period',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _numberFormat = value);
                            }
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
      ),
    );
  }
}
