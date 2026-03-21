import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/carousel_ab_testing_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Carousel A/B Testing Framework Dashboard
/// Comprehensive experiment management with statistical analysis
class CarouselABTestingFrameworkDashboard extends StatefulWidget {
  const CarouselABTestingFrameworkDashboard({super.key});

  @override
  State<CarouselABTestingFrameworkDashboard> createState() =>
      _CarouselABTestingFrameworkDashboardState();
}

class _CarouselABTestingFrameworkDashboardState
    extends State<CarouselABTestingFrameworkDashboard>
    with SingleTickerProviderStateMixin {
  final CarouselABTestingService _testingService =
      CarouselABTestingService.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _activeExperiments = [];
  List<Map<String, dynamic>> _historicalExperiments = [];
  bool _isLoading = true;

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

    final active = await _testingService.getExperiments(status: 'running');
    final historical =
        await _testingService.getExperiments(status: 'concluded');

    if (mounted) {
      setState(() {
        _activeExperiments = active;
        _historicalExperiments = historical;
        _isLoading = false;
      });
    }
  }

  void _showCreateExperimentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExperimentCreationWizard(
        onExperimentCreated: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CarouselABTestingFrameworkDashboard',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: CustomAppBar(
          title: 'Carousel A/B Testing',
          actions: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: AppThemeColors.electricGold),
              onPressed: _showCreateExperimentDialog,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: Column(
                  children: [
                    _buildStatusOverview(),
                    Container(
                      color: AppTheme.surfaceDark,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppThemeColors.electricGold,
                        unselectedLabelColor: AppTheme.textSecondaryDark,
                        indicatorColor: AppThemeColors.electricGold,
                        tabs: const [
                          Tab(text: 'Active Experiments'),
                          Tab(text: 'Results Analysis'),
                          Tab(text: 'Historical'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildActiveExperimentsTab(),
                          _buildResultsAnalysisTab(),
                          _buildHistoricalTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateExperimentDialog,
          backgroundColor: AppThemeColors.electricGold,
          icon: const Icon(Icons.science, color: Colors.black),
          label: const Text('New Test', style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }

  Widget _buildStatusOverview() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeColors.electricGold.withAlpha(51),
            AppTheme.surfaceDark,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Active Tests',
              _activeExperiments.length.toString(),
              Icons.science,
              AppThemeColors.neonMint,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildStatCard(
              'Completed',
              _historicalExperiments.length.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildStatCard(
              'Avg Confidence',
              '95.2%',
              Icons.trending_up,
              AppThemeColors.electricGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveExperimentsTab() {
    if (_activeExperiments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined,
                size: 64, color: AppTheme.textSecondaryDark),
            SizedBox(height: 2.h),
            Text(
              'No active experiments',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textSecondaryDark,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _activeExperiments.length,
      itemBuilder: (context, index) {
        final experiment = _activeExperiments[index];
        return _buildExperimentCard(experiment);
      },
    );
  }

  Widget _buildExperimentCard(Map<String, dynamic> experiment) {
    final variants = List<Map<String, dynamic>>.from(experiment['variants']);

    return Card(
      color: AppTheme.surfaceDark,
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    experiment['experiment_name'],
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: AppThemeColors.neonMint.withAlpha(51),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    experiment['status'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppThemeColors.neonMint,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              experiment['experiment_description'] ?? '',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              'Variants (${variants.length})',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            SizedBox(height: 1.h),
            ...variants.map((variant) => Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppThemeColors.electricGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          variant['variant_name'],
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                      ),
                      Text(
                        '${variant['traffic_percentage']}%',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppThemeColors.electricGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _viewExperimentDetails(experiment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeColors.electricGold,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                SizedBox(width: 2.w),
                IconButton(
                  icon: Icon(Icons.pause_circle,
                      color: AppTheme.textSecondaryDark),
                  onPressed: () => _pauseExperiment(experiment['experiment_id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsAnalysisTab() {
    if (_historicalExperiments.isEmpty) {
      return Center(
        child: Text(
          'No completed experiments to analyze yet',
          style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondaryDark),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _historicalExperiments.length,
      itemBuilder: (context, index) {
        final experiment = _historicalExperiments[index];
        return Card(
          color: AppTheme.surfaceDark,
          margin: EdgeInsets.only(bottom: 2.h),
          child: ListTile(
            title: Text(
              experiment['experiment_name']?.toString() ?? 'Experiment',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            subtitle: Text(
              'Tap for full analysis',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryDark,
              ),
            ),
            trailing: Icon(Icons.analytics, color: AppThemeColors.electricGold),
            onTap: () => _viewExperimentDetails(experiment),
          ),
        );
      },
    );
  }

  Widget _buildHistoricalTab() {
    if (_historicalExperiments.isEmpty) {
      return Center(
        child: Text(
          'No historical experiments',
          style:
              TextStyle(fontSize: 14.sp, color: AppTheme.textSecondaryDark),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _historicalExperiments.length,
      itemBuilder: (context, index) {
        final experiment = _historicalExperiments[index];
        return _buildHistoricalExperimentCard(experiment);
      },
    );
  }

  Widget _buildHistoricalExperimentCard(Map<String, dynamic> experiment) {
    return Card(
      color: AppTheme.surfaceDark,
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        title: Text(
          experiment['experiment_name'],
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        subtitle: Text(
          'Winner: ${experiment['winning_variant_id'] ?? 'N/A'}',
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryDark),
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.textSecondaryDark),
        onTap: () => _viewExperimentDetails(experiment),
      ),
    );
  }

  void _viewExperimentDetails(Map<String, dynamic> experiment) {
    showDialog(
      context: context,
      builder: (context) {
        final confidence = experiment['confidence_score'];
        final winner = experiment['winning_variant_id'] ?? 'N/A';
        final status = experiment['status'] ?? 'unknown';
        final start = experiment['start_time']?.toString() ?? 'N/A';
        final end = experiment['end_time']?.toString() ?? 'N/A';
        return AlertDialog(
          title: Text(experiment['experiment_name']?.toString() ?? 'Experiment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: $status'),
              SizedBox(height: 0.8.h),
              Text('Winner: $winner'),
              SizedBox(height: 0.8.h),
              Text(
                'Confidence: ${confidence == null ? 'N/A' : '${(confidence as num).toStringAsFixed(2)}'}',
              ),
              SizedBox(height: 0.8.h),
              Text('Start: $start'),
              SizedBox(height: 0.8.h),
              Text('End: $end'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pauseExperiment(String experimentId) async {
    await _testingService.pauseExperiment(experimentId);
    _loadData();
  }
}

// ============================================
// EXPERIMENT CREATION WIZARD
// ============================================

class _ExperimentCreationWizard extends StatefulWidget {
  final VoidCallback onExperimentCreated;

  const _ExperimentCreationWizard({required this.onExperimentCreated});

  @override
  State<_ExperimentCreationWizard> createState() =>
      _ExperimentCreationWizardState();
}

class _ExperimentCreationWizardState extends State<_ExperimentCreationWizard> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Form data
  String _experimentName = '';
  String _experimentDescription = '';
  String _testType = 'sequencing_strategy';
  final List<Map<String, dynamic>> _variants = [];
  final List<String> _successMetrics = [];
  final String _primaryMetric = 'engagement_rate';
  int _durationDays = 14;
  int _minimumSampleSize = 1000;
  final double _significanceThreshold = 0.95;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Create Experiment',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.textSecondaryDark),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _onStepCancel,
              controlsBuilder: (context, details) {
                return Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeColors.electricGold,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(_currentStep == 4 ? 'Launch' : 'Continue'),
                    ),
                    if (_currentStep > 0) ...[
                      SizedBox(width: 2.w),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ],
                  ],
                );
              },
              steps: [
                Step(
                  title: const Text('Experiment Setup'),
                  content: _buildStep1(),
                  isActive: _currentStep >= 0,
                ),
                Step(
                  title: const Text('Variant Configuration'),
                  content: _buildStep2(),
                  isActive: _currentStep >= 1,
                ),
                Step(
                  title: const Text('Success Metrics'),
                  content: _buildStep3(),
                  isActive: _currentStep >= 2,
                ),
                Step(
                  title: const Text('Experiment Parameters'),
                  content: _buildStep4(),
                  isActive: _currentStep >= 3,
                ),
                Step(
                  title: const Text('Review & Launch'),
                  content: _buildStep5(),
                  isActive: _currentStep >= 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: 'Experiment Name'),
          onChanged: (value) => _experimentName = value,
        ),
        SizedBox(height: 2.h),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Description'),
          maxLines: 3,
          onChanged: (value) => _experimentDescription = value,
        ),
        SizedBox(height: 2.h),
        DropdownButtonFormField<String>(
          initialValue: _testType,
          decoration: const InputDecoration(labelText: 'Test Type'),
          items: const [
            DropdownMenuItem(
                value: 'sequencing_strategy',
                child: Text('Sequencing Strategy')),
            DropdownMenuItem(
                value: 'content_ordering', child: Text('Content Ordering')),
            DropdownMenuItem(
                value: 'carousel_rotation', child: Text('Carousel Rotation')),
          ],
          onChanged: (value) => setState(() => _testType = value!),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Text('Add at least 2 variants',
            style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryDark)),
        SizedBox(height: 2.h),
        ElevatedButton.icon(
          onPressed: _addVariant,
          icon: const Icon(Icons.add),
          label: const Text('Add Variant'),
        ),
        SizedBox(height: 2.h),
        ..._variants.map((variant) => Card(
              child: ListTile(
                title: Text(variant['variant_name']),
                subtitle: Text('Traffic: ${variant['traffic_percentage']}%'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => setState(() => _variants.remove(variant)),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Engagement Rate'),
          value: _successMetrics.contains('engagement_rate'),
          onChanged: (value) {
            setState(() {
              if (value!) {
                _successMetrics.add('engagement_rate');
              } else {
                _successMetrics.remove('engagement_rate');
              }
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Conversion Rate'),
          value: _successMetrics.contains('conversion_rate'),
          onChanged: (value) {
            setState(() {
              if (value!) {
                _successMetrics.add('conversion_rate');
              } else {
                _successMetrics.remove('conversion_rate');
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: 'Duration (days)'),
          keyboardType: TextInputType.number,
          initialValue: _durationDays.toString(),
          onChanged: (value) => _durationDays = int.tryParse(value) ?? 14,
        ),
        SizedBox(height: 2.h),
        TextFormField(
          decoration:
              const InputDecoration(labelText: 'Minimum Sample Size per Variant'),
          keyboardType: TextInputType.number,
          initialValue: _minimumSampleSize.toString(),
          onChanged: (value) => _minimumSampleSize = int.tryParse(value) ?? 1000,
        ),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Experiment Name: $_experimentName',
            style: TextStyle(fontSize: 14.sp)),
        SizedBox(height: 1.h),
        Text('Test Type: $_testType', style: TextStyle(fontSize: 14.sp)),
        SizedBox(height: 1.h),
        Text('Variants: ${_variants.length}', style: TextStyle(fontSize: 14.sp)),
        SizedBox(height: 1.h),
        Text('Duration: $_durationDays days', style: TextStyle(fontSize: 14.sp)),
      ],
    );
  }

  void _addVariant() {
    setState(() {
      _variants.add({
        'variant_id': 'variant_${_variants.length + 1}',
        'variant_name': 'Variant ${_variants.length + 1}',
        'traffic_percentage': 50,
        'configuration_json': {},
      });
    });
  }

  void _onStepContinue() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _createExperiment();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _createExperiment() async {
    final service = CarouselABTestingService.instance;
    await service.createExperiment(
      experimentName: _experimentName,
      experimentDescription: _experimentDescription,
      testType: _testType,
      variants: _variants,
      successMetrics: _successMetrics,
      primaryMetric: _primaryMetric,
      durationDays: _durationDays,
      minimumSampleSize: _minimumSampleSize,
      significanceThreshold: _significanceThreshold,
    );

    if (mounted) {
      Navigator.pop(context);
      widget.onExperimentCreated();
    }
  }
}