import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/carousel_template_marketplace_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_image_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Carousel Template Marketplace enabling creator template sales and purchases
class CarouselTemplateMarketplace extends StatefulWidget {
  const CarouselTemplateMarketplace({super.key});

  @override
  State<CarouselTemplateMarketplace> createState() =>
      _CarouselTemplateMarketplaceState();
}

class _CarouselTemplateMarketplaceState
    extends State<CarouselTemplateMarketplace>
    with SingleTickerProviderStateMixin {
  final CarouselTemplateMarketplaceService _marketplaceService =
      CarouselTemplateMarketplaceService.instance;

  late TabController _tabController;

  List<Map<String, dynamic>> _allTemplates = [];
  List<Map<String, dynamic>> _myTemplates = [];
  Map<String, dynamic> _revenueAnalytics = {};
  bool _isLoading = true;

  String? _selectedCategory;
  String _sortBy = 'newest';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Engagement',
    'Conversion',
    'Revenue',
    'Viral',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait<dynamic>([
      _marketplaceService.getMarketplaceTemplates(),
      _marketplaceService.getMyTemplates(),
      _marketplaceService.getCreatorRevenue(),
    ]);

    if (mounted) {
      setState(() {
        _allTemplates = results[0] as List<Map<String, dynamic>>;
        _myTemplates = results[1] as List<Map<String, dynamic>>;
        _revenueAnalytics = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchTemplates() async {
    setState(() => _isLoading = true);

    final templates = await _marketplaceService.getMarketplaceTemplates(
      category: _selectedCategory,
      searchQuery: _searchController.text,
      sortBy: _sortBy,
    );

    if (mounted) {
      setState(() {
        _allTemplates = templates;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CarouselTemplateMarketplace',
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Template Marketplace',
          variant: CustomAppBarVariant.withBack,
        ),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Browse'),
                Tab(text: 'My Templates'),
                Tab(text: 'Revenue'),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBrowseTab(),
                        _buildMyTemplatesTab(),
                        _buildRevenueTab(),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateTemplateDialog,
          icon: Icon(Icons.add),
          label: Text('Create Template'),
        ),
      ),
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      children: [
        _buildSearchFilters(),
        Expanded(
          child: _allTemplates.isEmpty
              ? Center(
                  child: Text(
                    'No templates found',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(3.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 2.w,
                    mainAxisSpacing: 2.h,
                  ),
                  itemCount: _allTemplates.length,
                  itemBuilder: (context, index) =>
                      _buildTemplateCard(_allTemplates[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchFilters() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onSubmitted: (_) => _searchTemplates(),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text('All')),
                    ..._categories.map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                    _searchTemplates();
                  },
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    DropdownMenuItem(value: 'newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'popular', child: Text('Popular')),
                    DropdownMenuItem(value: 'rating', child: Text('Rating')),
                    DropdownMenuItem(
                      value: 'price_low',
                      child: Text('Price: Low'),
                    ),
                    DropdownMenuItem(
                      value: 'price_high',
                      child: Text('Price: High'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortBy = value);
                      _searchTemplates();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final templateName = template['template_name'] as String? ?? '';
    final price = (template['price'] as num?)?.toDouble() ?? 0.0;
    final salesCount = template['sales_count'] as int? ?? 0;
    final averageRating =
        (template['average_rating'] as num?)?.toDouble() ?? 0.0;
    final previewImages = template['preview_images'] as List? ?? [];
    final category = template['category'] as String? ?? '';

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () => _showTemplateDetail(template),
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                child: previewImages.isNotEmpty
                    ? CustomImageWidget(
                        imageUrl: previewImages.first.toString(),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 30.sp),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    templateName,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 14.sp),
                      SizedBox(width: 1.w),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '($salesCount sales)',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Chip(
                        label: Text(category, style: TextStyle(fontSize: 9.sp)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTemplatesTab() {
    return _myTemplates.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 40.sp,
                  color: Colors.grey,
                ),
                SizedBox(height: 2.h),
                Text(
                  'No templates created yet',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
                SizedBox(height: 2.h),
                ElevatedButton(
                  onPressed: _showCreateTemplateDialog,
                  child: Text('Create Your First Template'),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(3.w),
            itemCount: _myTemplates.length,
            itemBuilder: (context, index) =>
                _buildMyTemplateCard(_myTemplates[index]),
          );
  }

  Widget _buildMyTemplateCard(Map<String, dynamic> template) {
    final templateName = template['template_name'] as String? ?? '';
    final price = (template['price'] as num?)?.toDouble() ?? 0.0;
    final salesCount = template['sales_count'] as int? ?? 0;
    final status = template['status'] as String? ?? 'pending';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        title: Text(templateName),
        subtitle: Text(
          'Price: \$${price.toStringAsFixed(2)} • $salesCount sales',
        ),
        trailing: Chip(
          label: Text(status.toUpperCase()),
          backgroundColor: status == 'approved'
              ? Colors.green
              : status == 'rejected'
              ? Colors.red
              : Colors.orange,
          labelStyle: TextStyle(color: Colors.white),
        ),
        onTap: () => _showTemplateDetail(template),
      ),
    );
  }

  Widget _buildRevenueTab() {
    final totalSales = _revenueAnalytics['total_sales'] as int? ?? 0;
    final totalRevenue =
        (_revenueAnalytics['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final pendingEarnings =
        (_revenueAnalytics['pending_earnings'] as num?)?.toDouble() ?? 0.0;
    final paidEarnings =
        (_revenueAnalytics['paid_earnings'] as num?)?.toDouble() ?? 0.0;

    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Text(
          'Revenue Analytics',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        _buildRevenueCard(
          'Total Sales',
          totalSales.toString(),
          Icons.shopping_cart,
          Colors.blue,
        ),
        _buildRevenueCard(
          'Total Revenue (70%)',
          '\$${totalRevenue.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildRevenueCard(
          'Pending Earnings',
          '\$${pendingEarnings.toStringAsFixed(2)}',
          Icons.pending,
          Colors.orange,
        ),
        _buildRevenueCard(
          'Paid Earnings',
          '\$${paidEarnings.toStringAsFixed(2)}',
          Icons.check_circle,
          Colors.green,
        ),
        SizedBox(height: 2.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue Split',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '70% to Creator • 30% Platform Fee',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateDetail(Map<String, dynamic> template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(3.w),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                template['template_name'] as String? ?? '',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              Text(
                template['template_description'] as String? ?? '',
                style: TextStyle(fontSize: 13.sp),
              ),
              SizedBox(height: 2.h),
              Text(
                'Price: \$${(template["price"] as num?)?.toDouble().toStringAsFixed(2) ?? "0.00"}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _purchaseTemplate(template);
                },
                child: Text('Purchase Template'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTemplateDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = _categories.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Template'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Template Name'),
              ),
              SizedBox(height: 1.h),
              TextField(
                controller: descController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              SizedBox(height: 1.h),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(labelText: 'Category'),
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) selectedCategory = value;
                },
              ),
              SizedBox(height: 1.h),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Price (\$5-\$500)',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text) ?? 0.0;
              if (price < 5 || price > 500) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Price must be between \$5 and \$500'),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final templateId = await _marketplaceService.createTemplate(
                templateName: nameController.text,
                templateDescription: descController.text,
                category: selectedCategory,
                price: price,
                templateData: {'sample': 'data'},
              );

              if (templateId != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Template created successfully')),
                );
                _loadData();
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _purchaseTemplate(Map<String, dynamic> template) {
    final price = (template['price'] as num?)?.toDouble() ?? 0.0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Stripe payment integration required to purchase for \$${price.toStringAsFixed(2)}',
        ),
      ),
    );
  }
}
