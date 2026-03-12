import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/template_library_widget.dart';
import './widgets/template_editor_dialog_widget.dart';
import './widgets/variable_management_widget.dart';
import './widgets/template_testing_dialog_widget.dart';
import './widgets/template_analytics_widget.dart';

/// SMS Alert Template Management Center
/// Comprehensive alert template creation with variable insertion and category organization
class SmsAlertTemplateManagementCenter extends StatefulWidget {
  const SmsAlertTemplateManagementCenter({super.key});

  @override
  State<SmsAlertTemplateManagementCenter> createState() =>
      _SmsAlertTemplateManagementCenterState();
}

class _SmsAlertTemplateManagementCenterState
    extends State<SmsAlertTemplateManagementCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = SupabaseService.instance.client;

  List<Map<String, dynamic>> _templates = [];
  Map<String, int> _categoryStats = {};
  Map<String, dynamic> _usageStats = {};
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _loadTemplates(),
        _loadCategoryStats(),
        _loadUsageStats(),
      ]);

      if (mounted) {
        setState(() {
          _templates = results[0] as List<Map<String, dynamic>>;
          _categoryStats = results[1] as Map<String, int>;
          _usageStats = results[2] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadTemplates() async {
    try {
      var query = _supabase.from('sms_alert_templates').select();

      if (_selectedCategory != 'all') {
        query = query.eq('category', _selectedCategory);
      }

      final response = await query.order('usage_count', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading templates: $e');
      return [];
    }
  }

  Future<Map<String, int>> _loadCategoryStats() async {
    try {
      final response = await _supabase
          .from('sms_alert_templates')
          .select('category')
          .eq('is_active', true);

      final templates = List<Map<String, dynamic>>.from(response);
      final stats = <String, int>{};

      for (final template in templates) {
        final category = template['category'] as String? ?? 'unknown';
        stats[category] = (stats[category] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error loading category stats: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadUsageStats() async {
    try {
      final response = await _supabase
          .from('sms_alerts_sent')
          .select('template_id, delivery_status')
          .gte(
            'sent_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          );

      final alerts = List<Map<String, dynamic>>.from(response);

      final totalSent = alerts.length;
      final delivered = alerts
          .where((a) => a['delivery_status'] == 'delivered')
          .length;

      return {
        'total_sent': totalSent,
        'delivered': delivered,
        'delivery_rate': totalSent > 0
            ? (delivered / totalSent * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      debugPrint('Error loading usage stats: $e');
      return {};
    }
  }

  void _showTemplateEditor({Map<String, dynamic>? template}) {
    showDialog(
      context: context,
      builder: (context) => TemplateEditorDialogWidget(
        template: template,
        onSave: (templateData) async {
          try {
            if (template == null) {
              // Create new template
              await _supabase.from('sms_alert_templates').insert({
                ...templateData,
                'created_by': _supabase.auth.currentUser?.id,
              });
            } else {
              // Update existing template
              await _supabase
                  .from('sms_alert_templates')
                  .update({
                    ...templateData,
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('template_id', template['template_id']);
            }

            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    template == null ? 'Template created' : 'Template updated',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              _loadData();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving template: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showTemplateTest(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (context) => TemplateTestingDialogWidget(template: template),
    );
  }

  Future<void> _toggleTemplateStatus(String templateId, bool isActive) async {
    try {
      await _supabase
          .from('sms_alert_templates')
          .update({
            'is_active': !isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('template_id', templateId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive ? 'Template deactivated' : 'Template activated',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'SmsAlertTemplateManagementCenter',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'SMS Alert Templates',
            variant: CustomAppBarVariant.withBack,
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showTemplateEditor(),
          icon: const Icon(Icons.add),
          label: const Text('New Template'),
          backgroundColor: theme.colorScheme.primary,
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  // Header with stats
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Templates',
                            _templates.length.toString(),
                            Icons.description,
                            Colors.blue,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: _buildStatCard(
                            'Sent (30d)',
                            _usageStats['total_sent']?.toString() ?? '0',
                            Icons.send,
                            Colors.green,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: _buildStatCard(
                            'Delivery Rate',
                            '${_usageStats['delivery_rate'] ?? '0'}%',
                            Icons.check_circle,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category filter
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('all', 'All'),
                          _buildCategoryChip('fraud', 'Fraud'),
                          _buildCategoryChip('system_outage', 'System Outage'),
                          _buildCategoryChip(
                            'performance_degradation',
                            'Performance',
                          ),
                          _buildCategoryChip('anomaly_detection', 'Anomaly'),
                          _buildCategoryChip('security', 'Security'),
                          _buildCategoryChip('operational', 'Operational'),
                        ],
                      ),
                    ),
                  ),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(
                      153,
                    ),
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Templates'),
                      Tab(text: 'Variables'),
                      Tab(text: 'Analytics'),
                    ],
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        TemplateLibraryWidget(
                          templates: _templates,
                          onEdit: (template) => _showTemplateEditor(template: template),
                          onTest: _showTemplateTest,
                          onToggleStatus: _toggleTemplateStatus,
                        ),
                        const VariableManagementWidget(),
                        TemplateAnalyticsWidget(stats: _usageStats),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
          _loadData();
        },
        selectedColor: theme.colorScheme.primary.withAlpha(51),
        checkmarkColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          fontSize: 11.sp,
          color: isSelected ? theme.colorScheme.primary : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}