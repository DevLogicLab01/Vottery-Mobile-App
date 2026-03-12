import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/carousel_filter_service.dart' as filter_service;
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class AdvancedCarouselFilterControlCenter extends StatefulWidget {
  final String carouselType;
  final Function(filter_service.FilterState)? onFiltersApplied;

  const AdvancedCarouselFilterControlCenter({
    super.key,
    required this.carouselType,
    this.onFiltersApplied,
  });

  @override
  State<AdvancedCarouselFilterControlCenter> createState() =>
      _AdvancedCarouselFilterControlCenterState();
}

class _AdvancedCarouselFilterControlCenterState
    extends State<AdvancedCarouselFilterControlCenter> {
  final filter_service.CarouselFilterService _filterService =
      filter_service.CarouselFilterService.instance;

  Set<String> _selectedCategories = {};
  bool _trendingOnly = false;
  filter_service.RangeValues _priceRange = filter_service.RangeValues(0, 500);
  double? _minRating;
  filter_service.DateTimeRange? _dateRange;
  String _sortBy = 'most_recent';

  final List<String> _availableCategories = [
    'Entertainment',
    'Politics',
    'Sports',
    'Technology',
    'Business',
    'Health',
    'Science',
    'Education',
  ];

  final List<Map<String, dynamic>> _quickFilters = [
    {'label': 'Most Popular', 'icon': Icons.trending_up, 'config': 'popular'},
    {'label': 'Recent', 'icon': Icons.access_time, 'config': 'recent'},
    {'label': 'High Rated', 'icon': Icons.star, 'config': 'high_rated'},
  ];

  bool _isLoading = true;
  final int _resultCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
  }

  Future<void> _loadSavedFilters() async {
    setState(() => _isLoading = true);

    try {
      final savedFilters = await _filterService.loadFilterState(
        contentType: widget.carouselType,
      );

      if (savedFilters != null) {
        setState(() {
          _selectedCategories = savedFilters.selectedCategories;
          _trendingOnly = savedFilters.isTrendingOnly;
          _priceRange =
              savedFilters.priceRange ?? filter_service.RangeValues(0, 500);
          _minRating = savedFilters.minRating;
          _dateRange = savedFilters.dateRange;
          _sortBy = savedFilters.sortBy;
        });
      }
    } catch (e) {
      debugPrint('Failed to load saved filters: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyFilters() async {
    final filterState = filter_service.FilterState(
      selectedCategories: _selectedCategories,
      isTrendingOnly: _trendingOnly,
      priceRange: _priceRange,
      minRating: _minRating,
      dateRange: _dateRange,
      sortBy: _sortBy,
    );

    // Save filters
    await _filterService.saveFilterState(
      contentType: widget.carouselType,
      filterState: filterState,
    );

    // Track usage
    await _filterService.trackFilterUsage(
      contentType: widget.carouselType,
      filterState: filterState,
      resultsCount: _resultCount,
    );

    // Notify parent
    widget.onFiltersApplied?.call(filterState);

    if (mounted) {
      Navigator.pop(context, filterState);
    }
  }

  Future<void> _clearAllFilters() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Filters?'),
        content: Text('This will reset all filter settings to default.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _selectedCategories.clear();
        _trendingOnly = false;
        _priceRange = filter_service.RangeValues(0, 500);
        _minRating = null;
        _dateRange = null;
        _sortBy = 'most_recent';
      });
    }
  }

  void _applyQuickFilter(String config) {
    setState(() {
      if (config == 'popular') {
        _trendingOnly = true;
        _sortBy = 'trending';
      } else if (config == 'recent') {
        _sortBy = 'most_recent';
        _trendingOnly = false;
      } else if (config == 'high_rated') {
        _minRating = 4.0;
        _sortBy = 'rating';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Filters',
          variant: CustomAppBarVariant.withBack,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Advanced Filters',
        variant: CustomAppBarVariant.withBack,
        actions: [
          TextButton(
            onPressed: _clearAllFilters,
            child: Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Filters
                  Text(
                    'Quick Filters',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: _quickFilters.map((filter) {
                      return ActionChip(
                        avatar: Icon(
                          filter['icon'],
                          size: 16.sp,
                          color: AppTheme.primaryColor,
                        ),
                        label: Text(filter['label']),
                        onPressed: () => _applyQuickFilter(filter['config']),
                        backgroundColor: Colors.grey[100],
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 3.h),

                  // Category Filter
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: _availableCategories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                        selectedColor: AppTheme.primaryColor.withAlpha(51),
                        checkmarkColor: AppTheme.primaryColor,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 3.h),

                  // Trending Filter
                  SwitchListTile(
                    title: Text(
                      'Show Only Trending',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    subtitle: Text(
                      'Filter by trending score threshold',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                    value: _trendingOnly,
                    onChanged: (value) {
                      setState(() => _trendingOnly = value);
                    },
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                  SizedBox(height: 2.h),

                  // Price Range Filter
                  Text(
                    'Price Range',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${_priceRange.start.toInt()} - \$${_priceRange.end.toInt()}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                  RangeSlider(
                    values: RangeValues(_priceRange.start, _priceRange.end),
                    min: 0,
                    max: 500,
                    divisions: 50,
                    labels: RangeLabels(
                      '\$${_priceRange.start.toInt()}',
                      '\$${_priceRange.end.toInt()}',
                    ),
                    onChanged: (values) {
                      setState(
                        () => _priceRange = filter_service.RangeValues(
                          values.start,
                          values.end,
                        ),
                      );
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  SizedBox(height: 2.h),

                  // Rating Filter
                  Text(
                    'Minimum Rating',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    children: [1.0, 2.0, 3.0, 4.0, 5.0].map((rating) {
                      final isSelected = _minRating == rating;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14.sp,
                              color: isSelected ? Colors.white : Colors.amber,
                            ),
                            SizedBox(width: 1.w),
                            Text('${rating.toInt()}+'),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _minRating = selected ? rating : null;
                          });
                        },
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 3.h),

                  // Date Range Filter
                  Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: [
                      ActionChip(
                        label: Text('Active Now'),
                        onPressed: () {
                          setState(() {
                            _dateRange = filter_service.DateTimeRange(
                              start: DateTime.now(),
                              end: DateTime.now().add(Duration(days: 7)),
                            );
                          });
                        },
                      ),
                      ActionChip(
                        label: Text('Ending Soon'),
                        onPressed: () {
                          setState(() {
                            _dateRange = filter_service.DateTimeRange(
                              start: DateTime.now(),
                              end: DateTime.now().add(Duration(days: 3)),
                            );
                          });
                        },
                      ),
                      ActionChip(
                        label: Text('Upcoming'),
                        onPressed: () {
                          setState(() {
                            _dateRange = filter_service.DateTimeRange(
                              start: DateTime.now().add(Duration(days: 1)),
                              end: DateTime.now().add(Duration(days: 30)),
                            );
                          });
                        },
                      ),
                      ActionChip(
                        label: Text('Custom Range'),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(
                              () => _dateRange = filter_service.DateTimeRange(
                                start: picked.start,
                                end: picked.end,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  if (_dateRange != null) ...[
                    SizedBox(height: 1.h),
                    Chip(
                      label: Text(
                        '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}',
                      ),
                      deleteIcon: Icon(Icons.close, size: 16.sp),
                      onDeleted: () {
                        setState(() => _dateRange = null);
                      },
                    ),
                  ],
                  SizedBox(height: 3.h),

                  // Active Filters Summary
                  if (_selectedCategories.isNotEmpty ||
                      _trendingOnly ||
                      _minRating != null ||
                      _dateRange != null) ...[
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Filters',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Wrap(
                            spacing: 1.w,
                            runSpacing: 0.5.h,
                            children: [
                              ..._selectedCategories.map(
                                (cat) => Chip(
                                  label: Text(
                                    cat,
                                    style: TextStyle(fontSize: 10.sp),
                                  ),
                                  deleteIcon: Icon(Icons.close, size: 14.sp),
                                  onDeleted: () {
                                    setState(
                                      () => _selectedCategories.remove(cat),
                                    );
                                  },
                                ),
                              ),
                              if (_trendingOnly)
                                Chip(
                                  label: Text(
                                    'Trending',
                                    style: TextStyle(fontSize: 10.sp),
                                  ),
                                  deleteIcon: Icon(Icons.close, size: 14.sp),
                                  onDeleted: () {
                                    setState(() => _trendingOnly = false);
                                  },
                                ),
                              if (_minRating != null)
                                Chip(
                                  label: Text(
                                    '${_minRating!.toInt()}+ Stars',
                                    style: TextStyle(fontSize: 10.sp),
                                  ),
                                  deleteIcon: Icon(Icons.close, size: 14.sp),
                                  onDeleted: () {
                                    setState(() => _minRating = null);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}