import 'package:flutter/material.dart';

import '../../services/ip_geolocation_service.dart';
import './widgets/access_statistics_widget.dart';
import './widgets/bulk_action_panel_widget.dart';
import './widgets/country_card_widget.dart';

class AdminCountryAccessControlPanel extends StatefulWidget {
  const AdminCountryAccessControlPanel({super.key});

  @override
  State<AdminCountryAccessControlPanel> createState() =>
      _AdminCountryAccessControlPanelState();
}

class _AdminCountryAccessControlPanelState
    extends State<AdminCountryAccessControlPanel> {
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _filteredCountries = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, enabled, disabled
  Set<String> _selectedCountries = {};
  bool _selectAllMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final countries = await IPGeolocationService.getCountryRestrictions();
    final stats = await IPGeolocationService.getAccessStatistics();

    setState(() {
      _countries = countries;
      _filteredCountries = countries;
      _statistics = stats;
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredCountries = _countries.where((country) {
        // Search filter
        final matchesSearch =
            _searchQuery.isEmpty ||
            country['country_name'].toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            country['country_code'].toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        // Status filter
        final matchesStatus =
            _filterStatus == 'all' ||
            (_filterStatus == 'enabled' && country['is_enabled'] == true) ||
            (_filterStatus == 'disabled' && country['is_enabled'] == false);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _toggleCountryStatus(String countryCode, bool newStatus) async {
    final success = await IPGeolocationService.updateCountryRestriction(
      countryCode: countryCode,
      isEnabled: newStatus,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Country access enabled successfully'
                : 'Country access disabled successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update country status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bulkUpdateCountries(bool isEnabled) async {
    if (_selectedCountries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one country'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await IPGeolocationService.bulkUpdateCountryRestrictions(
      countryCodes: _selectedCountries.toList(),
      isEnabled: isEnabled,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedCountries.length} countries updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _selectedCountries.clear();
        _selectAllMode = false;
      });
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update countries'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAllMode) {
        _selectedCountries.clear();
      } else {
        _selectedCountries = _filteredCountries
            .map((c) => c['country_code'] as String)
            .toSet();
      }
      _selectAllMode = !_selectAllMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Country Access Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(_selectAllMode ? Icons.deselect : Icons.select_all),
            onPressed: _toggleSelectAll,
            tooltip: _selectAllMode ? 'Deselect All' : 'Select All',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Header
                AccessStatisticsWidget(statistics: _statistics),

                // Search and Filter Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search countries...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _applyFilters();
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'all',
                                  label: Text('All'),
                                  icon: Icon(Icons.public),
                                ),
                                ButtonSegment(
                                  value: 'enabled',
                                  label: Text('Enabled'),
                                  icon: Icon(Icons.check_circle),
                                ),
                                ButtonSegment(
                                  value: 'disabled',
                                  label: Text('Disabled'),
                                  icon: Icon(Icons.block),
                                ),
                              ],
                              selected: {_filterStatus},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  _filterStatus = newSelection.first;
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bulk Action Panel
                if (_selectedCountries.isNotEmpty)
                  BulkActionPanelWidget(
                    selectedCount: _selectedCountries.length,
                    onEnableAll: () => _bulkUpdateCountries(true),
                    onDisableAll: () => _bulkUpdateCountries(false),
                    onClearSelection: () {
                      setState(() {
                        _selectedCountries.clear();
                        _selectAllMode = false;
                      });
                    },
                  ),

                // Countries List
                Expanded(
                  child: _filteredCountries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No countries found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredCountries.length,
                          itemBuilder: (context, index) {
                            final country = _filteredCountries[index];
                            final countryCode =
                                country['country_code'] as String;
                            final isSelected = _selectedCountries.contains(
                              countryCode,
                            );

                            return CountryCardWidget(
                              country: country,
                              statistics: _statistics[countryCode],
                              isSelected: isSelected,
                              onToggle: (newStatus) =>
                                  _toggleCountryStatus(countryCode, newStatus),
                              onSelect: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCountries.add(countryCode);
                                  } else {
                                    _selectedCountries.remove(countryCode);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
