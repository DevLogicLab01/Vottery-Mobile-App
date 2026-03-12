import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/election_forecast_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/forecast_header_widget.dart';
import './widgets/swing_voter_heatmap_widget.dart';
import './widgets/demographic_trends_widget.dart';
import './widgets/outcome_probability_chart_widget.dart';
import './widgets/scenario_simulation_widget.dart';
import './widgets/forecast_accuracy_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// AI Predictive Modeling Screen
/// OpenAI GPT-5 powered election forecasting with swing voter identification,
/// demographic shift analysis, and 30-60 day trend modeling
class AIPredictiveModelingScreen extends StatefulWidget {
  final String? electionId;

  const AIPredictiveModelingScreen({super.key, this.electionId});

  @override
  State<AIPredictiveModelingScreen> createState() =>
      _AIPredictiveModelingScreenState();
}

class _AIPredictiveModelingScreenState extends State<AIPredictiveModelingScreen>
    with SingleTickerProviderStateMixin {
  final ElectionForecastService _forecastService =
      ElectionForecastService.instance;
  late TabController _tabController;

  String? _electionId;
  bool _isLoading = true;
  bool _isGenerating = false;

  Map<String, dynamic>? _latestForecast;
  List<Map<String, dynamic>> _swingVoters = [];
  List<Map<String, dynamic>> _demographicShifts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _electionId = widget.electionId;
    if (_electionId != null) {
      _loadForecastData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadForecastData() async {
    if (_electionId == null) return;

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _forecastService.getLatestForecast(_electionId!),
        _forecastService.getSwingVoters(_electionId!),
        _forecastService.getDemographicShifts(_electionId!),
      ]);

      setState(() {
        _latestForecast = results[0] as Map<String, dynamic>?;
        _swingVoters = results[1] as List<Map<String, dynamic>>;
        _demographicShifts = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load forecast data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateNewForecast() async {
    if (_electionId == null) return;

    setState(() => _isGenerating = true);

    try {
      await _forecastService.generateForecast(
        electionId: _electionId!,
        forecastHorizonDays: 30,
      );

      await _loadForecastData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Forecast generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Generate forecast error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportReport() async {
    if (_electionId == null) return;

    try {
      final reportUrl = await _forecastService.exportForecastReport(
        _electionId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported: $reportUrl'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Export report error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_electionId == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'AI Predictive Modeling',
          variant: CustomAppBarVariant.withBack,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 20.w,
                color: theme.colorScheme.primary.withAlpha(77),
              ),
              SizedBox(height: 2.h),
              Text(
                'No Election Selected',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Select an election to view predictions',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ErrorBoundaryWrapper(
      screenName: 'AIPredictiveModelingScreen',
      onRetry: _loadForecastData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'AI Predictive Modeling',
          variant: CustomAppBarVariant.withBack,
          actions: [
            if (_isGenerating)
              Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Center(
                  child: SizedBox(
                    width: 5.w,
                    height: 5.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              )
            else ...[
              IconButton(
                icon: Icon(Icons.refresh, size: 6.w),
                onPressed: _generateNewForecast,
                tooltip: 'Generate New Forecast',
              ),
              IconButton(
                icon: Icon(Icons.download, size: 6.w),
                onPressed: _exportReport,
                tooltip: 'Export Report',
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  if (_latestForecast != null)
                    ForecastHeaderWidget(forecast: _latestForecast!),
                  _buildTabBar(theme),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildForecastTab(),
                        _buildSwingVotersTab(),
                        _buildDemographicsTab(),
                        _buildScenarioTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(153),
        indicatorColor: theme.colorScheme.primary,
        labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 13.sp),
        tabs: const [
          Tab(text: 'Forecast'),
          Tab(text: 'Swing Voters'),
          Tab(text: 'Demographics'),
          Tab(text: 'Scenarios'),
        ],
      ),
    );
  }

  Widget _buildForecastTab() {
    if (_latestForecast == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 15.w,
              color: Colors.grey.withAlpha(77),
            ),
            SizedBox(height: 2.h),
            Text(
              'No Forecast Available',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 1.h),
            ElevatedButton(
              onPressed: _generateNewForecast,
              child: const Text('Generate Forecast'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutcomeProbabilityChartWidget(forecast: _latestForecast!),
          SizedBox(height: 2.h),
          ForecastAccuracyWidget(forecast: _latestForecast!),
        ],
      ),
    );
  }

  Widget _buildSwingVotersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwingVoterHeatmapWidget(
            swingVoters: _swingVoters,
            electionId: _electionId!,
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [DemographicTrendsWidget(shifts: _demographicShifts)],
      ),
    );
  }

  Widget _buildScenarioTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScenarioSimulationWidget(
            electionId: _electionId!,
            currentForecast: _latestForecast,
          ),
        ],
      ),
    );
  }
}
