import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Terms & Policies tab providing formatted legal documents with search functionality
/// and version history tracking.
class TermsPoliciesTabWidget extends StatefulWidget {
  const TermsPoliciesTabWidget({super.key});

  @override
  State<TermsPoliciesTabWidget> createState() => _TermsPoliciesTabWidgetState();
}

class _TermsPoliciesTabWidgetState extends State<TermsPoliciesTabWidget> {
  final List<Map<String, dynamic>> _documents = [
    {
      'id': 'terms',
      'title': 'Terms of Service',
      'icon': 'description',
      'lastUpdated': 'January 15, 2024',
      'version': '2.1',
      'description': 'Legal agreement between you and Vottery',
    },
    {
      'id': 'privacy',
      'title': 'Privacy Policy',
      'icon': 'privacy_tip',
      'lastUpdated': 'January 10, 2024',
      'version': '2.0',
      'description': 'How we collect, use, and protect your data',
    },
    {
      'id': 'community',
      'title': 'Community Guidelines',
      'icon': 'groups',
      'lastUpdated': 'December 20, 2023',
      'version': '1.5',
      'description': 'Rules for respectful community participation',
    },
    {
      'id': 'cookie',
      'title': 'Cookie Policy',
      'icon': 'cookie',
      'lastUpdated': 'November 5, 2023',
      'version': '1.2',
      'description': 'Information about cookies and tracking',
    },
    {
      'id': 'copyright',
      'title': 'Copyright Policy',
      'icon': 'copyright',
      'lastUpdated': 'October 15, 2023',
      'version': '1.0',
      'description': 'Intellectual property and content rights',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _showDocumentDetail(context, document);
              },
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: document['icon'] as String,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document['title'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            document['description'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 1.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'v${document['version']}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Updated ${document['lastUpdated']}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDocumentDetail(
    BuildContext context,
    Map<String, dynamic> document,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 85.h,
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
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: document['icon'] as String,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document['title'] as String,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Version ${document['version']} • ${document['lastUpdated']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
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
                    _buildSection(
                      theme,
                      '1. Introduction',
                      'Welcome to Vottery. By using our service, you agree to these terms. Please read them carefully.',
                    ),
                    _buildSection(
                      theme,
                      '2. User Accounts',
                      'You are responsible for maintaining the security of your account and password. Vottery cannot and will not be liable for any loss or damage from your failure to comply with this security obligation.',
                    ),
                    _buildSection(
                      theme,
                      '3. Acceptable Use',
                      'You agree not to misuse the Vottery services. For example, you must not interfere with the services or try to access them using a method other than the interface and instructions we provide.',
                    ),
                    _buildSection(
                      theme,
                      '4. Privacy',
                      'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your personal information.',
                    ),
                    _buildSection(
                      theme,
                      '5. Content',
                      'You retain ownership of any intellectual property rights that you hold in content you submit to Vottery. When you upload or submit content, you give Vottery a worldwide license to use, host, store, reproduce, and distribute such content.',
                    ),
                    _buildSection(
                      theme,
                      '6. Termination',
                      'We may suspend or terminate your access to the services at any time for any reason, including if we reasonably believe you have violated these Terms.',
                    ),
                    _buildSection(
                      theme,
                      '7. Changes to Terms',
                      'We may modify these terms from time to time. We will notify you of any changes by posting the new Terms on this page and updating the "Last Updated" date.',
                    ),
                    _buildSection(
                      theme,
                      '8. Contact Us',
                      'If you have any questions about these Terms, please contact us at support@vottery.com',
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Download feature coming soon'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                        minimumSize: Size(0, 5.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Share feature coming soon'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                        minimumSize: Size(0, 5.h),
                      ),
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

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
