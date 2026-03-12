import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/support_ticket_service.dart';

class FAQSectionWidget extends StatefulWidget {
  const FAQSectionWidget({super.key});

  @override
  State<FAQSectionWidget> createState() => _FAQSectionWidgetState();
}

class _FAQSectionWidgetState extends State<FAQSectionWidget> {
  final SupportTicketService _service = SupportTicketService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _faqs = [];
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFAQs() async {
    setState(() => _isLoading = true);

    final faqs = await _service.getFAQArticles(
      category: _selectedCategory,
      searchQuery: _searchController.text,
    );

    setState(() {
      _faqs = faqs;
      _isLoading = false;
    });
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
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search FAQs...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                ),
                onChanged: (value) => _loadFAQs(),
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  const DropdownMenuItem(
                    value: 'technical',
                    child: Text('Technical'),
                  ),
                  const DropdownMenuItem(
                    value: 'billing',
                    child: Text('Billing'),
                  ),
                  const DropdownMenuItem(
                    value: 'election',
                    child: Text('Election'),
                  ),
                  const DropdownMenuItem(value: 'fraud', child: Text('Fraud')),
                  const DropdownMenuItem(
                    value: 'account',
                    child: Text('Account'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                  _loadFAQs();
                },
              ),
            ],
          ),
        ),

        // FAQ List
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
              : _faqs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 20.w,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No FAQs found',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _faqs.length,
                  itemBuilder: (context, index) {
                    final faq = _faqs[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 2.h),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.all(4.w),
                        childrenPadding: EdgeInsets.all(4.w),
                        title: Text(
                          faq['title'] ?? 'No title',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 0.5.h),
                          child: Text(
                            faq['category'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        children: [
                          Text(
                            faq['content'] ?? 'No content',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 4.w,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '${faq['view_count'] ?? 0} views',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.thumb_up,
                                size: 4.w,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '${faq['helpful_count'] ?? 0} helpful',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
