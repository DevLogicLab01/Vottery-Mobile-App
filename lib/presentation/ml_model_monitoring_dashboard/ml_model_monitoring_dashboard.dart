import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/ml_model_monitoring_service.dart';
import '../../theme/app_theme.dart';

class MlModelMonitoringDashboard extends StatefulWidget {
  const MlModelMonitoringDashboard({super.key});

  @override
  State<MlModelMonitoringDashboard> createState() =>
      _MlModelMonitoringDashboardState();
}

class _MlModelMonitoringDashboardState extends State<MlModelMonitoringDashboard>
    with SingleTickerProviderStateMixin {
  final MLModelMonitoringService _monitoringService =
      MLModelMonitoringService();
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic> _modelOverview = {};
  String _selectedModel = 'openai';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final overview = await _monitoringService.getModelOverview();
      setState(() {
        _modelOverview = overview;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ML Model Monitoring',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryLight,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Accuracy'),
            Tab(text: 'Latency'),
            Tab(text: 'Costs'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  _buildModelSelector(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildAccuracyTab(),
                        _buildLatencyTab(),
                        _buildCostsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildModelSelector() {
    final models = ['openai', 'anthropic', 'perplexity', 'gemini'];

    return Container(
      padding: EdgeInsets.all(2.w),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: models.map((model) {
            final isSelected = _selectedModel == model;
            return Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: ChoiceChip(
                label: Text(
                  model[0].toUpperCase() + model.substring(1),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.primaryLight,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedModel = model);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Model Performance Overview',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          ...(_modelOverview.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: _buildModelOverviewCard(
                entry.key,
                entry.value as Map<String, dynamic>,
              ),
            );
          })),
          SizedBox(height: 2.h),
          _buildModelHealthWidget(),
        ],
      ),
    );
  }

  Widget _buildModelOverviewCard(String modelName, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              modelName.toUpperCase(),
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text('Stats: ${stats.toString()}'),
          ],
        ),
      ),
    );
  }

  Widget _buildModelHealthWidget() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model Health',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text('Health monitoring data will appear here'),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyTab() {
    return Center(child: Text('Accuracy metrics for $_selectedModel'));
  }

  Widget _buildLatencyTab() {
    return Center(child: Text('Latency trends for $_selectedModel'));
  }

  Widget _buildCostsTab() {
    return Center(child: Text('Cost analytics for $_selectedModel'));
  }
}
