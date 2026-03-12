import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/participation_fee_controls_service.dart';

/// Admin: Participation fee global + country-wise controls (Web parity: ParticipationFeeControls).
class ParticipationFeeControlsScreen extends StatefulWidget {
  const ParticipationFeeControlsScreen({super.key});

  @override
  State<ParticipationFeeControlsScreen> createState() =>
      _ParticipationFeeControlsScreenState();
}

class _ParticipationFeeControlsScreenState
    extends State<ParticipationFeeControlsScreen> {
  final ParticipationFeeControlsService _service =
      ParticipationFeeControlsService.instance;

  bool _loading = true;
  bool _saving = false;
  bool _globalEnabled = false;
  List<String> _disabledCountries = [];
  String _searchQuery = '';
  String? _message;
  bool _messageSuccess = true;

  static const List<Map<String, String>> _allCountries = [
    {'code': 'US', 'name': 'United States', 'region': 'Region 1'},
    {'code': 'CA', 'name': 'Canada', 'region': 'Region 1'},
    {'code': 'GB', 'name': 'United Kingdom', 'region': 'Region 2'},
    {'code': 'FR', 'name': 'France', 'region': 'Region 2'},
    {'code': 'DE', 'name': 'Germany', 'region': 'Region 2'},
    {'code': 'IT', 'name': 'Italy', 'region': 'Region 2'},
    {'code': 'ES', 'name': 'Spain', 'region': 'Region 2'},
    {'code': 'NL', 'name': 'Netherlands', 'region': 'Region 2'},
    {'code': 'BE', 'name': 'Belgium', 'region': 'Region 2'},
    {'code': 'CH', 'name': 'Switzerland', 'region': 'Region 2'},
    {'code': 'AT', 'name': 'Austria', 'region': 'Region 2'},
    {'code': 'SE', 'name': 'Sweden', 'region': 'Region 2'},
    {'code': 'NO', 'name': 'Norway', 'region': 'Region 2'},
    {'code': 'DK', 'name': 'Denmark', 'region': 'Region 2'},
    {'code': 'FI', 'name': 'Finland', 'region': 'Region 2'},
    {'code': 'RU', 'name': 'Russia', 'region': 'Region 3'},
    {'code': 'PL', 'name': 'Poland', 'region': 'Region 3'},
    {'code': 'UA', 'name': 'Ukraine', 'region': 'Region 3'},
    {'code': 'CZ', 'name': 'Czech Republic', 'region': 'Region 3'},
    {'code': 'RO', 'name': 'Romania', 'region': 'Region 3'},
    {'code': 'HU', 'name': 'Hungary', 'region': 'Region 3'},
    {'code': 'BG', 'name': 'Bulgaria', 'region': 'Region 3'},
    {'code': 'ZA', 'name': 'South Africa', 'region': 'Region 4'},
    {'code': 'NG', 'name': 'Nigeria', 'region': 'Region 4'},
    {'code': 'EG', 'name': 'Egypt', 'region': 'Region 4'},
    {'code': 'KE', 'name': 'Kenya', 'region': 'Region 4'},
    {'code': 'GH', 'name': 'Ghana', 'region': 'Region 4'},
    {'code': 'ET', 'name': 'Ethiopia', 'region': 'Region 4'},
    {'code': 'TZ', 'name': 'Tanzania', 'region': 'Region 4'},
    {'code': 'UG', 'name': 'Uganda', 'region': 'Region 4'},
    {'code': 'BR', 'name': 'Brazil', 'region': 'Region 5'},
    {'code': 'MX', 'name': 'Mexico', 'region': 'Region 5'},
    {'code': 'AR', 'name': 'Argentina', 'region': 'Region 5'},
    {'code': 'CO', 'name': 'Colombia', 'region': 'Region 5'},
    {'code': 'CL', 'name': 'Chile', 'region': 'Region 5'},
    {'code': 'PE', 'name': 'Peru', 'region': 'Region 5'},
    {'code': 'VE', 'name': 'Venezuela', 'region': 'Region 5'},
    {'code': 'CU', 'name': 'Cuba', 'region': 'Region 5'},
    {'code': 'IN', 'name': 'India', 'region': 'Region 6'},
    {'code': 'PK', 'name': 'Pakistan', 'region': 'Region 6'},
    {'code': 'BD', 'name': 'Bangladesh', 'region': 'Region 6'},
    {'code': 'ID', 'name': 'Indonesia', 'region': 'Region 6'},
    {'code': 'PH', 'name': 'Philippines', 'region': 'Region 6'},
    {'code': 'VN', 'name': 'Vietnam', 'region': 'Region 6'},
    {'code': 'TH', 'name': 'Thailand', 'region': 'Region 6'},
    {'code': 'MY', 'name': 'Malaysia', 'region': 'Region 6'},
    {'code': 'SA', 'name': 'Saudi Arabia', 'region': 'Region 6'},
    {'code': 'AE', 'name': 'United Arab Emirates', 'region': 'Region 6'},
    {'code': 'TR', 'name': 'Turkey', 'region': 'Region 6'},
    {'code': 'IR', 'name': 'Iran', 'region': 'Region 6'},
    {'code': 'IQ', 'name': 'Iraq', 'region': 'Region 6'},
    {'code': 'IL', 'name': 'Israel', 'region': 'Region 6'},
    {'code': 'AU', 'name': 'Australia', 'region': 'Region 7'},
    {'code': 'NZ', 'name': 'New Zealand', 'region': 'Region 7'},
    {'code': 'TW', 'name': 'Taiwan', 'region': 'Region 7'},
    {'code': 'KR', 'name': 'South Korea', 'region': 'Region 7'},
    {'code': 'JP', 'name': 'Japan', 'region': 'Region 7'},
    {'code': 'SG', 'name': 'Singapore', 'region': 'Region 7'},
    {'code': 'CN', 'name': 'China', 'region': 'Region 8'},
    {'code': 'HK', 'name': 'Hong Kong', 'region': 'Region 8'},
    {'code': 'MO', 'name': 'Macau', 'region': 'Region 8'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final state = await _service.getControls();
    if (mounted) {
      setState(() {
        _globalEnabled = state.globallyEnabled;
        _disabledCountries = List.from(state.disabledCountries);
        _loading = false;
      });
    }
  }

  Future<void> _toggleGlobal() async {
    setState(() => _saving = true);
    final err = await _service.setGlobalEnabled(!_globalEnabled);
    if (mounted) {
      setState(() {
        _saving = false;
        if (err != null) {
          _message = err;
          _messageSuccess = false;
        } else {
          _globalEnabled = !_globalEnabled;
          _message = 'Participation fees ${_globalEnabled ? 'enabled' : 'disabled'} globally';
          _messageSuccess = true;
        }
      });
      if (_message != null) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _message = null);
        });
      }
    }
  }

  Future<void> _toggleCountry(String code) async {
    setState(() => _saving = true);
    final err = await _service.toggleCountry(code);
    if (mounted) {
      setState(() {
        _saving = false;
        if (err != null) {
          _message = err;
          _messageSuccess = false;
        } else {
          if (_disabledCountries.contains(code)) {
            _disabledCountries.remove(code);
          } else {
            _disabledCountries.add(code);
          }
          _message = 'Country settings updated';
          _messageSuccess = true;
        }
      });
      if (_message != null) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _message = null);
        });
      }
    }
  }

  List<Map<String, String>> get _filteredCountries {
    if (_searchQuery.trim().isEmpty) return _allCountries;
    final q = _searchQuery.toLowerCase();
    return _allCountries
        .where((c) =>
            (c['name'] ?? '').toLowerCase().contains(q) ||
            (c['code'] ?? '').toLowerCase().contains(q) ||
            (c['region'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  Map<String, List<Map<String, String>>> get _grouped {
    final Map<String, List<Map<String, String>>> out = {};
    for (final c in _filteredCountries) {
      final r = c['region'] ?? '';
      out.putIfAbsent(r, () => []).add(c);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Participation Fee Controls'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Global participation fee',
                              style: theme.textTheme.titleMedium,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'When disabled, all elections are free to participate.',
                              style: theme.textTheme.bodySmall,
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Status: ${_globalEnabled ? 'Enabled' : 'Disabled'}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Switch(
                                  value: _globalEnabled,
                                  onChanged: _saving ? null : (_) => _toggleGlobal(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_message != null) ...[
                      SizedBox(height: 2.h),
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: _messageSuccess
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _messageSuccess
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 3.h),
                    Text(
                      'Country-wise controls',
                      style: theme.textTheme.titleMedium,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Disable participation fees for specific countries.',
                      style: theme.textTheme.bodySmall,
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by name, code, or region',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    SizedBox(height: 2.h),
                    ..._grouped.entries.map((e) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          ...e.value.map((c) {
                            final code = c['code']!;
                            final isDisabled =
                                _disabledCountries.contains(code);
                            return Card(
                              margin: EdgeInsets.only(bottom: 1.h),
                              child: ListTile(
                                title: Text(c['name'] ?? code),
                                subtitle: Text(code),
                                trailing: Switch(
                                  value: !isDisabled,
                                  onChanged: _saving
                                      ? null
                                      : (_) => _toggleCountry(code),
                                ),
                              ),
                            );
                          }),
                          SizedBox(height: 2.h),
                        ],
                      );
                    }),
                    SizedBox(height: 2.h),
                    Card(
                      color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3),
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 20.sp,
                                    color: theme.colorScheme.primary),
                                SizedBox(width: 2.w),
                                Text(
                                  'Notes',
                                  style: theme.textTheme.titleSmall,
                                ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Global disable overrides country settings. Disabled countries cannot create or participate in paid elections. Changes apply to new elections.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
