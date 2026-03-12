import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/marketplace_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/escrow_system_widget.dart';
import './widgets/service_detail_modal_widget.dart';
import './widgets/service_listing_card_widget.dart';
import './widgets/transaction_management_widget.dart';

/// Creator Marketplace Store Screen
/// Comprehensive service marketplace with listings, pricing, calendar, and escrow
class CreatorMarketplaceStore extends StatefulWidget {
  const CreatorMarketplaceStore({super.key});

  @override
  State<CreatorMarketplaceStore> createState() =>
      _CreatorMarketplaceStoreState();
}

class _CreatorMarketplaceStoreState extends State<CreatorMarketplaceStore> {
  final MarketplaceService _marketplaceService = MarketplaceService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _selectedService;
  String _selectedCategory = 'All';
  String _sortBy = 'Most Popular';
  RangeValues _priceRange = RangeValues(0, 500);
  int _maxDeliveryDays = 30;
  double _minRating = 0.0;

  final List<String> _categories = [
    'All',
    'Design',
    'Content',
    'Strategy',
    'Management',
  ];
  final List<String> _sortOptions = [
    'Most Popular',
    'Highest Rated',
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
  ];

  @override
  void initState() {
    super.initState();
    _loadMarketplaceData();
  }

  Future<void> _loadMarketplaceData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _marketplaceService.getMarketplaceServices(),
        _marketplaceService.getTransactions(asBuyer: true),
      ]);

      if (mounted) {
        setState(() {
          _services = results[0];
          _transactions = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load marketplace data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    var filtered = _services.where((service) {
      // Category filter
      if (_selectedCategory != 'All' &&
          service['category'] != _selectedCategory) {
        return false;
      }

      // Price filter
      final basePrice = (service['price_tiers'] as List).first['price'] as num;
      if (basePrice < _priceRange.start || basePrice > _priceRange.end) {
        return false;
      }

      // Delivery time filter
      final deliveryDays = service['delivery_time_days'] as int;
      if (deliveryDays > _maxDeliveryDays) {
        return false;
      }

      // Rating filter
      final rating = (service['rating'] ?? 0.0) as num;
      if (rating < _minRating) {
        return false;
      }

      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'Highest Rated':
        filtered.sort(
          (a, b) => ((b['rating'] ?? 0.0) as num).compareTo(
            (a['rating'] ?? 0.0) as num,
          ),
        );
        break;
      case 'Newest':
        filtered.sort(
          (a, b) =>
              (b['created_at'] as String).compareTo(a['created_at'] as String),
        );
        break;
      case 'Price: Low to High':
        filtered.sort((a, b) {
          final aPrice = (a['price_tiers'] as List).first['price'] as num;
          final bPrice = (b['price_tiers'] as List).first['price'] as num;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) {
          final aPrice = (a['price_tiers'] as List).first['price'] as num;
          final bPrice = (b['price_tiers'] as List).first['price'] as num;
          return bPrice.compareTo(aPrice);
        });
        break;
      default: // Most Popular
        filtered.sort(
          (a, b) => ((b['total_orders'] ?? 0) as int).compareTo(
            (a['total_orders'] ?? 0) as int,
          ),
        );
    }

    return filtered;
  }

  void _showServiceDetail(Map<String, dynamic> service) {
    setState(() => _selectedService = service);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceDetailModalWidget(
        service: service,
        onClose: () {
          Navigator.pop(context);
          setState(() => _selectedService = null);
        },
        onPurchase: (tier) => _handlePurchase(service, tier),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Services', style: TextStyle(fontSize: 16.sp)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price Range',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              RangeSlider(
                values: RangeValues(_priceRange.start, _priceRange.end),
                min: 0,
                max: 500,
                divisions: 10,
                labels: RangeLabels(
                  '\$${_priceRange.start.round()}',
                  '\$${_priceRange.end.round()}',
                ),
                onChanged: (values) {
                  setState(() => _priceRange = RangeValues(values.start, values.end));
                },
              ),
              SizedBox(height: 2.h),
              Text(
                'Max Delivery Time',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _maxDeliveryDays.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                label: '$_maxDeliveryDays days',
                onChanged: (value) {
                  setState(() => _maxDeliveryDays = value.round());
                },
              ),
              SizedBox(height: 2.h),
              Text(
                'Minimum Rating',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _minRating,
                min: 0,
                max: 5,
                divisions: 10,
                label: _minRating.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => _minRating = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _priceRange = RangeValues(0, 500);
                _maxDeliveryDays = 30;
                _minRating = 0.0;
              });
              Navigator.pop(context);
            },
            child: Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(
    Map<String, dynamic> service,
    Map<String, dynamic> tier,
  ) async {
    // Show escrow payment flow
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => EscrowSystemWidget(
        service: service,
        tier: tier,
        onConfirm: () async {
          final transactionId = await _marketplaceService.purchaseService(
            serviceId: service['id'] as String,
            tierSelected: tier['name'] as String,
            amountPaid: (tier['price'] as num).toDouble(),
            countryCode: 'US',
          );
          return transactionId != null;
        },
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service purchased! Funds held in escrow.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadMarketplaceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: IconButton(
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: 'Creator Marketplace',
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'filter_list',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'shopping_cart',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => TransactionManagementWidget(
                  transactions: _transactions,
                  onRefresh: _loadMarketplaceData,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : Column(
              children: [
                _buildCategoryFilter(),
                _buildSortBar(),
                Expanded(
                  child: _filteredServices.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadMarketplaceData,
                          child: GridView.builder(
                            padding: EdgeInsets.all(4.w),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 3.w,
                                  mainAxisSpacing: 2.h,
                                ),
                            itemCount: _filteredServices.length,
                            itemBuilder: (context, index) {
                              final service = _filteredServices[index];
                              return ServiceListingCardWidget(
                                service: service,
                                onTap: () => _showServiceDetail(service),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 6.h,
      color: AppTheme.surfaceLight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryLight
                      : AppTheme.textSecondaryLight,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondaryLight,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      color: AppTheme.surfaceLight,
      child: Row(
        children: [
          Text(
            'Sort by:',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: DropdownButton<String>(
              value: _sortBy,
              isExpanded: true,
              underline: SizedBox(),
              items: _sortOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option, style: TextStyle(fontSize: 12.sp)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortBy = value);
                }
              },
            ),
          ),
          Text(
            '${_filteredServices.length} services',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => ShimmerSkeletonLoader(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12.0),
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
          CustomIconWidget(
            iconName: 'search_off',
            size: 20.w,
            color: AppTheme.textSecondaryLight,
          ),
          SizedBox(height: 2.h),
          Text(
            'No services found',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}