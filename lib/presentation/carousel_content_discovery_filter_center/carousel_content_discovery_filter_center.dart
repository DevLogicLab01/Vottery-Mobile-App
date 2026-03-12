import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/carousel_filter_service.dart';
import '../../services/cursor_pagination_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../theme/app_theme.dart';

/// Carousel Content Discovery Filter Center
/// Comprehensive filtering system with advanced content discovery
class CarouselContentDiscoveryFilterCenter extends StatefulWidget {
  const CarouselContentDiscoveryFilterCenter({super.key});

  @override
  State<CarouselContentDiscoveryFilterCenter> createState() =>
      _CarouselContentDiscoveryFilterCenterState();
}

class _CarouselContentDiscoveryFilterCenterState
    extends State<CarouselContentDiscoveryFilterCenter> {
  final CarouselFilterService _filterService = CarouselFilterService.instance;
  final CursorPaginationService _paginationService =
      CursorPaginationService.instance;

  final ScrollController _scrollController = ScrollController();

  FilterState _filterState = FilterState();
  List<Map<String, dynamic>> _content = [];
  String? _nextCursor;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final String _selectedContentType = 'jolts';

  final List<String> _categories = [
    'All',
    'Politics',
    'Entertainment',
    'Sports',
    'Technology',
    'Business',
  ];

  final List<String> _sortOptions = [
    'Most Recent',
    'Most Popular',
    'Highest Rated',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedFilters() async {
    final savedState = await _filterService.loadFilterState(
      contentType: _selectedContentType,
    );

    if (savedState != null && mounted) {
      setState(() => _filterState = savedState);
    }

    _loadContent();
  }

  Future<void> _loadContent({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _content = [];
        _nextCursor = null;
        _isLoading = true;
      });
    }

    try {
      PaginatedResponse<Map<String, dynamic>> response;

      switch (_selectedContentType) {
        case 'jolts':
          response = await _paginationService.fetchJolts(
            cursor: refresh ? null : _nextCursor,
          );
          break;
        case 'moments':
          response = await _paginationService.fetchMoments(
            cursor: refresh ? null : _nextCursor,
          );
          break;
        default:
          response = PaginatedResponse(data: [], hasMore: false);
      }

      if (mounted) {
        setState(() {
          if (refresh) {
            _content = response.data;
          } else {
            _content.addAll(response.data);
          }
          _nextCursor = response.nextCursor;
          _isLoading = false;
          _isLoadingMore = false;
        });

        // Track analytics
        _filterService.trackFilterUsage(
          contentType: _selectedContentType,
          filterState: _filterState,
          resultsCount: response.data.length,
        );
      }
    } catch (e) {
      debugPrint('Load content error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.7) {
      if (!_isLoadingMore && _nextCursor != null) {
        setState(() => _isLoadingMore = true);
        _loadContent();
      }
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      if (category == 'All') {
        _filterState = FilterState(
          selectedCategories: {},
          isTrendingOnly: _filterState.isTrendingOnly,
          sortBy: _filterState.sortBy,
        );
      } else {
        _filterState = FilterState(
          selectedCategories: {category.toLowerCase()},
          isTrendingOnly: _filterState.isTrendingOnly,
          sortBy: _filterState.sortBy,
        );
      }
    });

    _saveFiltersAndReload();
  }

  void _onTrendingToggled(bool value) {
    setState(() {
      _filterState = FilterState(
        selectedCategories: _filterState.selectedCategories,
        isTrendingOnly: value,
        sortBy: _filterState.sortBy,
      );
    });

    _saveFiltersAndReload();
  }

  void _onSortChanged(String? sortOption) {
    if (sortOption == null) return;

    String sortBy;
    switch (sortOption) {
      case 'Most Recent':
        sortBy = 'most_recent';
        break;
      case 'Most Popular':
        sortBy = 'most_popular';
        break;
      case 'Highest Rated':
        sortBy = 'highest_rated';
        break;
      default:
        sortBy = 'most_recent';
    }

    setState(() {
      _filterState = FilterState(
        selectedCategories: _filterState.selectedCategories,
        isTrendingOnly: _filterState.isTrendingOnly,
        sortBy: sortBy,
      );
    });

    _saveFiltersAndReload();
  }

  void _clearAllFilters() {
    setState(() {
      _filterState = FilterState();
    });

    _saveFiltersAndReload();
  }

  Future<void> _saveFiltersAndReload() async {
    await _filterService.saveFilterState(
      contentType: _selectedContentType,
      filterState: _filterState,
    );

    _loadContent(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CarouselContentDiscoveryFilterCenter',
      onRetry: () => _loadContent(refresh: true),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Content Discovery',
          actions: [
            IconButton(
              icon: Icon(Icons.filter_list_off, size: 20.sp),
              onPressed: _clearAllFilters,
              tooltip: 'Clear Filters',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilterBar(),
            if (_hasActiveFilters()) _buildActiveFiltersChips(),
            Expanded(
              child: _isLoading ? _buildSkeletonLoader() : _buildContentList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Category Filter
          SizedBox(
            height: 6.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == 'All'
                    ? _filterState.selectedCategories.isEmpty
                    : _filterState.selectedCategories.contains(
                        category.toLowerCase(),
                      );

                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _onCategorySelected(category),
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.accentLight,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                );
              },
            ),
          ),

          // Trending Toggle and Sort
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                // Trending Toggle
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: _filterState.isTrendingOnly
                          ? AppTheme.accentLight
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16.sp,
                        color: _filterState.isTrendingOnly
                            ? Colors.orange
                            : Colors.grey,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Trending',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: _filterState.isTrendingOnly
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Switch(
                        value: _filterState.isTrendingOnly,
                        onChanged: _onTrendingToggled,
                        activeThumbColor: AppTheme.accentLight,
                      ),
                    ],
                  ),
                ),
                Spacer(),

                // Sort Dropdown
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButton<String>(
                    value: _getSortLabel(_filterState.sortBy),
                    underline: SizedBox.shrink(),
                    icon: Icon(Icons.arrow_drop_down, size: 20.sp),
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.black,
                    ),
                    items: _sortOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: _onSortChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'most_recent':
        return 'Most Recent';
      case 'most_popular':
        return 'Most Popular';
      case 'highest_rated':
        return 'Highest Rated';
      default:
        return 'Most Recent';
    }
  }

  bool _hasActiveFilters() {
    return _filterState.selectedCategories.isNotEmpty ||
        _filterState.isTrendingOnly;
  }

  Widget _buildActiveFiltersChips() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      color: Colors.grey[50],
      child: Wrap(
        spacing: 2.w,
        runSpacing: 1.h,
        children: [
          ..._filterState.selectedCategories.map((category) {
            return Chip(
              label: Text(
                'Category: ${category[0].toUpperCase()}${category.substring(1)}',
                style: GoogleFonts.inter(fontSize: 11.sp),
              ),
              deleteIcon: Icon(Icons.close, size: 14.sp),
              onDeleted: () {
                setState(() {
                  _filterState = FilterState(
                    selectedCategories: _filterState.selectedCategories
                        .where((c) => c != category)
                        .toSet(),
                    isTrendingOnly: _filterState.isTrendingOnly,
                    sortBy: _filterState.sortBy,
                  );
                });
                _saveFiltersAndReload();
              },
              backgroundColor: Colors.white,
            );
          }),
          if (_filterState.isTrendingOnly)
            Chip(
              label: Text(
                'Trending',
                style: GoogleFonts.inter(fontSize: 11.sp),
              ),
              deleteIcon: Icon(Icons.close, size: 14.sp),
              onDeleted: () => _onTrendingToggled(false),
              backgroundColor: Colors.white,
            ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    if (_content.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48.sp, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No results found',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your filters',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(4.w),
      itemCount: _content.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _content.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(2.h),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final item = _content[index];
        return _buildContentCard(item);
      },
    );
  }

  Widget _buildContentCard(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'Untitled';
    final category = item['category'] as String? ?? 'General';
    final trendingScore = item['trending_score'] as int? ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trendingScore > 80)
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 20.sp,
                  ),
              ],
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: AppTheme.accentLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                category.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          child: Container(
            height: 15.h,
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70.w,
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                SizedBox(height: 1.h),
                Container(
                  width: 20.w,
                  height: 1.5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
