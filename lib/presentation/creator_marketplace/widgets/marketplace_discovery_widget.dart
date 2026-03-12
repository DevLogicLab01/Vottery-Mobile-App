import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Marketplace Discovery Widget
/// Browse and search available services from all creators
class MarketplaceDiscoveryWidget extends StatefulWidget {
  final List<Map<String, dynamic>> services;
  final VoidCallback onRefresh;

  const MarketplaceDiscoveryWidget({
    super.key,
    required this.services,
    required this.onRefresh,
  });

  @override
  State<MarketplaceDiscoveryWidget> createState() =>
      _MarketplaceDiscoveryWidgetState();
}

class _MarketplaceDiscoveryWidgetState
    extends State<MarketplaceDiscoveryWidget> {
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredServices = widget.services.where((service) {
      final matchesCategory =
          _selectedCategory == null || service['category'] == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          service['title'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryFilter(),
        Expanded(
          child: filteredServices.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: filteredServices.length,
                  itemBuilder: (context, index) {
                    return _buildServiceCard(filteredServices[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search services...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      'All',
      'Consultation',
      'Content',
      'Promotion',
      'Collaboration',
    ];

    return SizedBox(
      height: 5.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected =
              (_selectedCategory == null && category == 'All') ||
              _selectedCategory == category.toLowerCase();

          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category == 'All'
                      ? null
                      : category.toLowerCase();
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final title = service['title'] ?? 'Untitled Service';
    final description = service['description'] ?? '';
    final priceTiers = service['price_tiers'] as List? ?? [];
    final minPrice = priceTiers.isNotEmpty ? priceTiers.first['price'] : 0;
    final creatorName =
        service['user_profiles']?['full_name'] ?? 'Unknown Creator';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 5.w,
                    child: Text(creatorName[0].toUpperCase()),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'by $creatorName',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'From \$$minPrice',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(fontSize: 12.sp),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 15.w,
            color: AppTheme.textSecondaryLight,
          ),
          SizedBox(height: 2.h),
          Text(
            'No services found',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
