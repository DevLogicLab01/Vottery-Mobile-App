import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/campaign_template_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/template_card_widget.dart';
import './widgets/template_filter_widget.dart';
import './widgets/template_preview_modal_widget.dart';
import './widgets/template_search_widget.dart';

class CampaignTemplateGallery extends StatefulWidget {
  const CampaignTemplateGallery({super.key});

  @override
  State<CampaignTemplateGallery> createState() =>
      _CampaignTemplateGalleryState();
}

class _CampaignTemplateGalleryState extends State<CampaignTemplateGallery> {
  final CampaignTemplateService _templateService =
      CampaignTemplateService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _filteredTemplates = [];
  List<Map<String, dynamic>> _featuredTemplates = [];
  String _selectedCategory = 'all';
  String _selectedIndustry = 'all';
  String _searchQuery = '';
  Timer? _searchDebounce;

  final List<String> _categories = [
    'all',
    'market_research',
    'hype_prediction',
    'csr_vote',
    'product_feedback',
    'brand_awareness',
  ];

  final List<String> _industries = [
    'all',
    'tech',
    'healthcare',
    'finance',
    'retail',
    'entertainment',
    'education',
    'nonprofit',
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _loadFeaturedTemplates();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    try {
      final templates = await _templateService.getAllTemplates();
      setState(() {
        _templates = templates;
        _filteredTemplates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFeaturedTemplates() async {
    try {
      final featured = await _templateService.getFeaturedTemplates();
      setState(() => _featuredTemplates = featured);
    } catch (e) {
      debugPrint('Load featured templates error: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTemplates = _templates.where((template) {
        final categoryMatch =
            _selectedCategory == 'all' ||
            template['category'] == _selectedCategory;

        final industryMatch =
            _selectedIndustry == 'all' ||
            (template['industry_tags'] as List).contains(_selectedIndustry);

        final searchMatch =
            _searchQuery.isEmpty ||
            (template['name'] as String).toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (template['description'] as String).toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        return categoryMatch && industryMatch && searchMatch;
      }).toList();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() => _selectedCategory = category);
    _applyFilters();
  }

  void _onIndustryChanged(String industry) {
    setState(() => _selectedIndustry = industry);
    _applyFilters();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _applyFilters();
    });
  }

  void _showTemplatePreview(Map<String, dynamic> template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TemplatePreviewModalWidget(
        template: template,
        onApply: () => _applyTemplate(template),
      ),
    );
  }

  Future<void> _applyTemplate(Map<String, dynamic> template) async {
    Navigator.pop(context); // Close preview modal

    // Navigate to Participatory Ads Studio with template data
    Navigator.pushNamed(
      context,
      AppRoutes.electionCreationStudio,
      arguments: {'template_id': template['id'], 'template_data': template},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template "${template['name']}" applied'),
        backgroundColor: AppTheme.accentLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CampaignTemplateGallery',
      onRetry: _loadTemplates,
      child: Scaffold(
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
          title: 'Campaign Template Gallery',
          actions: [
            IconButton(
              icon: Icon(Icons.favorite_border, size: 6.w),
              onPressed: () {
                // Navigate to favorites
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadTemplates,
          child: CustomScrollView(
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: TemplateSearchWidget(
                    onSearchChanged: _onSearchChanged,
                  ),
                ),
              ),

              // Category Filter
              SliverToBoxAdapter(
                child: TemplateFilterWidget(
                  title: 'Campaign Type',
                  options: _categories,
                  selectedOption: _selectedCategory,
                  onOptionSelected: _onCategoryChanged,
                ),
              ),

              // Industry Filter
              SliverToBoxAdapter(
                child: TemplateFilterWidget(
                  title: 'Industry',
                  options: _industries,
                  selectedOption: _selectedIndustry,
                  onOptionSelected: _onIndustryChanged,
                ),
              ),

              // Featured Templates Section
              if (_featuredTemplates.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 5.w),
                        SizedBox(width: 2.w),
                        Text(
                          'Featured Templates',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 30.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      itemCount: _featuredTemplates.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(right: 3.w),
                          child: SizedBox(
                            width: 70.w,
                            child: TemplateCardWidget(
                              template: _featuredTemplates[index],
                              onTap: () => _showTemplatePreview(
                                _featuredTemplates[index],
                              ),
                              isFeatured: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // All Templates Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                  child: Text(
                    'All Templates (${_filteredTemplates.length})',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Templates Grid
              _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _filteredTemplates.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 3.w,
                          crossAxisSpacing: 3.w,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return TemplateCardWidget(
                            template: _filteredTemplates[index],
                            onTap: () =>
                                _showTemplatePreview(_filteredTemplates[index]),
                          );
                        }, childCount: _filteredTemplates.length),
                      ),
                    ),

              SliverToBoxAdapter(child: SizedBox(height: 2.h)),
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
          Icon(Icons.search_off, size: 80.sp, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'No templates found',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}