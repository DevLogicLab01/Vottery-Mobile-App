import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/fraud_engine_service.dart';
import './widgets/appeal_queue_widget.dart';
import './widgets/fraud_alert_card_widget.dart';
import './widgets/fraud_metrics_widget.dart';
import './widgets/suspension_list_widget.dart';

class FraudMonitoringDashboard extends StatefulWidget {
  const FraudMonitoringDashboard({super.key});

  @override
  State<FraudMonitoringDashboard> createState() =>
      _FraudMonitoringDashboardState();
}

class _FraudMonitoringDashboardState extends State<FraudMonitoringDashboard>
    with SingleTickerProviderStateMixin {
  final FraudEngineService _fraudService = FraudEngineService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _fraudEvents = [];
  List<Map<String, dynamic>> _suspensions = [];
  List<Map<String, dynamic>> _appeals = [];
  String _selectedRiskFilter = 'all';

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
      final events = await _fraudService.getFraudDetectionEvents(
        riskLevel: _selectedRiskFilter == 'all' ? null : _selectedRiskFilter,
      );
      final suspensions = await _fraudService.getActiveSuspensions();
      final appeals = await _fraudService.getFraudAppeals(status: 'pending');

      setState(() {
        _fraudEvents = events;
        _suspensions = suspensions;
        _appeals = appeals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fraud Monitoring Dashboard',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red.shade700,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'Alerts (${_fraudEvents.length})'),
            Tab(text: 'Suspensions (${_suspensions.length})'),
            Tab(text: 'Appeals (${_appeals.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Threat Status Overview
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade700, Colors.red.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FraudMetricsWidget(fraudEvents: _fraudEvents),
          ),

          // Risk Filter
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Text(
                  'Risk Level:',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All'),
                        _buildFilterChip('critical', 'Critical'),
                        _buildFilterChip('high', 'High'),
                        _buildFilterChip('medium', 'Medium'),
                        _buildFilterChip('low', 'Low'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Alerts Tab
                      _fraudEvents.isEmpty
                          ? _buildEmptyState('No fraud alerts detected')
                          : ListView.builder(
                              padding: EdgeInsets.all(4.w),
                              itemCount: _fraudEvents.length,
                              itemBuilder: (context, index) {
                                return FraudAlertCardWidget(
                                  event: _fraudEvents[index],
                                  onInvestigate: () => _investigateEvent(
                                    _fraudEvents[index]['event_id'],
                                  ),
                                  onDismiss: () => _dismissEvent(
                                    _fraudEvents[index]['event_id'],
                                  ),
                                );
                              },
                            ),

                      // Suspensions Tab
                      _suspensions.isEmpty
                          ? _buildEmptyState('No active suspensions')
                          : SuspensionListWidget(
                              suspensions: _suspensions,
                              onLift: _liftSuspension,
                            ),

                      // Appeals Tab
                      _appeals.isEmpty
                          ? _buildEmptyState('No pending appeals')
                          : AppealQueueWidget(
                              appeals: _appeals,
                              onReview: _reviewAppeal,
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedRiskFilter == value;
    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedRiskFilter = value);
          _loadData();
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.red.shade100,
        labelStyle: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? Colors.red.shade700 : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 20.w, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _investigateEvent(String eventId) async {
    // Navigate to investigation screen or show details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Investigation started for event $eventId')),
    );
  }

  Future<void> _dismissEvent(String eventId) async {
    // Mark event as reviewed/dismissed
    _loadData();
  }

  Future<void> _liftSuspension(String suspensionId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lift Suspension'),
        content: Text('Are you sure you want to lift this suspension?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Implement lift logic
              _loadData();
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewAppeal(String appealId, String decision) async {
    final success = await _fraudService.reviewFraudAppeal(
      appealId: appealId,
      decision: decision,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appeal reviewed: $decision'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    }
  }
}
