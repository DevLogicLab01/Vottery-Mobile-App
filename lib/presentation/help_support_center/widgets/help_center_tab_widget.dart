import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Help Center tab featuring intelligent search with auto-suggestions,
/// categorized articles (Account, Voting, Technical, Privacy),
/// and step-by-step tutorials with helpfulness ratings.
class HelpCenterTabWidget extends StatefulWidget {
  const HelpCenterTabWidget({super.key});

  @override
  State<HelpCenterTabWidget> createState() => _HelpCenterTabWidgetState();
}

class _HelpCenterTabWidgetState extends State<HelpCenterTabWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'account', 'name': 'Account', 'icon': 'person', 'count': 12},
    {'id': 'voting', 'name': 'Voting', 'icon': 'how_to_vote', 'count': 18},
    {'id': 'technical', 'name': 'Technical', 'icon': 'settings', 'count': 9},
    {'id': 'privacy', 'name': 'Privacy', 'icon': 'lock', 'count': 7},
  ];

  final List<Map<String, dynamic>> _articles = [
    {
      'id': '1',
      'category': 'account',
      'title': 'How to reset your password',
      'description': 'Step-by-step guide to recover your account access',
      'views': 1234,
      'helpful': 89,
      'notHelpful': 5,
    },
    {
      'id': '2',
      'category': 'account',
      'title': 'Update your profile information',
      'description': 'Learn how to edit your personal details and preferences',
      'views': 892,
      'helpful': 76,
      'notHelpful': 3,
    },
    {
      'id': '3',
      'category': 'voting',
      'title': 'Understanding vote types',
      'description':
          'Learn about plurality, ranked choice, and approval voting',
      'views': 2145,
      'helpful': 156,
      'notHelpful': 12,
    },
    {
      'id': '4',
      'category': 'voting',
      'title': 'How to cast your vote',
      'description': 'Complete guide to participating in elections',
      'views': 3421,
      'helpful': 287,
      'notHelpful': 8,
    },
    {
      'id': '5',
      'category': 'voting',
      'title': 'Earning VP rewards',
      'description': 'Maximize your Vote Points through active participation',
      'views': 1876,
      'helpful': 134,
      'notHelpful': 15,
    },
    {
      'id': '6',
      'category': 'technical',
      'title': 'Troubleshooting app crashes',
      'description': 'Common solutions for stability issues',
      'views': 567,
      'helpful': 45,
      'notHelpful': 18,
    },
    {
      'id': '7',
      'category': 'technical',
      'title': 'Biometric authentication setup',
      'description':
          'Enable fingerprint and face recognition for secure voting',
      'views': 1123,
      'helpful': 98,
      'notHelpful': 6,
    },
    {
      'id': '8',
      'category': 'privacy',
      'title': 'Anonymous voting explained',
      'description': 'How we protect your vote privacy',
      'views': 2341,
      'helpful': 201,
      'notHelpful': 9,
    },
    {
      'id': '9',
      'category': 'privacy',
      'title': 'Data sharing settings',
      'description': 'Control what information you share',
      'views': 876,
      'helpful': 67,
      'notHelpful': 4,
    },
  ];

  List<Map<String, dynamic>> get _filteredArticles {
    var articles = _articles;

    if (_selectedCategory != null) {
      articles = articles
          .where((article) => article['category'] == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      articles = articles
          .where(
            (article) =>
                article['title'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                article['description'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return articles;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search Bar
        Container(
          padding: EdgeInsets.all(4.w),
          color: theme.colorScheme.surface,
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search help articles...',
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 1.5.h,
              ),
            ),
          ),
        ),

        // Category Filters
        Container(
          height: 12.h,
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category['id'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = isSelected
                        ? null
                        : category['id'] as String?;
                  });
                },
                child: Container(
                  width: 28.w,
                  margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
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
                      CustomIconWidget(
                        iconName: category['icon'] as String,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                        size: 24,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        category['name'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${category['count']} articles',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.8,
                                )
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Articles List
        Expanded(
          child: _filteredArticles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'search_off',
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                        size: 64,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No articles found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Try adjusting your search or filters',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _filteredArticles.length,
                  itemBuilder: (context, index) {
                    final article = _filteredArticles[index];
                    final helpfulPercentage =
                        ((article['helpful'] as int) /
                                ((article['helpful'] as int) +
                                    (article['notHelpful'] as int)) *
                                100)
                            .round();

                    return Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _showArticleDetail(context, article);
                          },
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        article['title'] as String,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  article['description'] as String,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 1.5.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.visibility,
                                      size: 16,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${article['views']} views',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      Icons.thumb_up,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '$helpfulPercentage% helpful',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showArticleDetail(BuildContext context, Map<String, dynamic> article) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 1.h, bottom: 2.h),
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      article['title'] as String,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article['description'] as String,
                      style: theme.textTheme.bodyLarge,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Step-by-step guide:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _buildStep(
                      theme,
                      1,
                      'Open the app and navigate to settings',
                    ),
                    _buildStep(
                      theme,
                      2,
                      'Select the option you want to modify',
                    ),
                    _buildStep(theme, 3, 'Follow the on-screen instructions'),
                    _buildStep(theme, 4, 'Save your changes'),
                    SizedBox(height: 3.h),
                    Text(
                      'Was this article helpful?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Thank you for your feedback!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.thumb_up),
                            label: const Text('Yes'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'We\'ll work on improving this article',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.thumb_down),
                            label: const Text('No'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme, int number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 0.5.h),
              child: Text(text, style: theme.textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}
