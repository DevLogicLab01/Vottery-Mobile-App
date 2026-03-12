import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/restful_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/endpoint_configuration_widget.dart';
import './widgets/jwt_authentication_panel_widget.dart';
import './widgets/api_key_management_widget.dart';
import './widgets/request_response_logging_widget.dart';
import './widgets/rate_limiting_dashboard_widget.dart';
import './widgets/swagger_documentation_widget.dart';

/// RESTful API Management Hub
/// Comprehensive API service layer administration with JWT authentication
class RestfulApiManagementHub extends StatefulWidget {
  const RestfulApiManagementHub({super.key});

  @override
  State<RestfulApiManagementHub> createState() =>
      _RestfulApiManagementHubState();
}

class _RestfulApiManagementHubState extends State<RestfulApiManagementHub>
    with SingleTickerProviderStateMixin {
  final RestfulApiService _apiService = RestfulApiService.instance;
  late TabController _tabController;

  Map<String, dynamic> _performanceMetrics = {};
  List<Map<String, dynamic>> _endpointStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final metrics = await _apiService.getApiPerformanceMetrics();
    final stats = await _apiService.getEndpointStatistics();

    setState(() {
      _performanceMetrics = metrics;
      _endpointStats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'RESTful API Management Hub',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'RESTful API Management',
          variant: CustomAppBarVariant.withBack,
        ),
        body: Column(
          children: [
            // API Status Overview
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Column(
                      children: [
                        Text(
                          'API Service Layer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricCard(
                              'Active Endpoints',
                              '${_endpointStats.length}',
                              Icons.api,
                            ),
                            _buildMetricCard(
                              'Avg Response',
                              '${_performanceMetrics['avg_response_time'] ?? 0}ms',
                              Icons.speed,
                            ),
                            _buildMetricCard(
                              'Success Rate',
                              '${_performanceMetrics['success_rate'] ?? 0}%',
                              Icons.check_circle,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // Tab Navigation
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.blue.shade700,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue.shade700,
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Endpoints'),
                  Tab(text: 'JWT Auth'),
                  Tab(text: 'API Keys'),
                  Tab(text: 'Logging'),
                  Tab(text: 'Rate Limiting'),
                  Tab(text: 'Swagger Docs'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  EndpointConfigurationWidget(endpointStats: _endpointStats),
                  const JwtAuthenticationPanelWidget(),
                  const ApiKeyManagementWidget(),
                  const RequestResponseLoggingWidget(),
                  const RateLimitingDashboardWidget(),
                  const SwaggerDocumentationWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20.sp),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 10.sp),
        ),
      ],
    );
  }
}
