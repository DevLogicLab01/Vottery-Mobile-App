import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/load_testing/production_load_test_service.dart';
import './widgets/load_test_control_panel_widget.dart';
import './widgets/regression_alerts_panel_widget.dart';
import './widgets/test_history_table_widget.dart';
import './widgets/test_results_panel_widget.dart';

class ProductionLoadTestingSuiteDashboard extends StatefulWidget {
  const ProductionLoadTestingSuiteDashboard({super.key});

  @override
  State<ProductionLoadTestingSuiteDashboard> createState() =>
      _ProductionLoadTestingSuiteDashboardState();
}

class _ProductionLoadTestingSuiteDashboardState
    extends State<ProductionLoadTestingSuiteDashboard>
    with SingleTickerProviderStateMixin {
  final _service = ProductionLoadTestService();
  late TabController _tabController;

  int _selectedTierIndex = 0;
  bool _testWebSocket = true;
  bool _testBlockchain = true;
  bool _testDatabase = true;
  bool _testApi = true;

  LoadTestReport? _currentReport;
  bool _isRunning = false;
  String _progressMessage = '';
  List<Map<String, dynamic>> _testHistory = [];
  List<FlSpot> _throughputData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHistory();
    _service.progressStream.listen((msg) {
      if (mounted) setState(() => _progressMessage = msg);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _service.getTestHistory();
    if (mounted) setState(() => _testHistory = history);
  }

  Future<void> _executeLoadTest() async {
    setState(() {
      _isRunning = true;
      _currentReport = null;
      _throughputData = [];
    });
    try {
      final report = await _service.runLoadTest(_selectedTierIndex);
      if (mounted) {
        setState(() {
          _currentReport = report;
          _isRunning = false;
          _throughputData = List.generate(
            10,
            (i) => FlSpot(
              i.toDouble(),
              (report.websocketMetrics.messagesPerSecond * (0.7 + i * 0.03))
                  .toDouble(),
            ),
          );
        });
        await _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRunning = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Test failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Production Load Testing Suite',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 3.w),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: _isRunning
                  ? const Color(0xFFFF6B35).withAlpha(26)
                  : const Color(0xFF4CAF50).withAlpha(26),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isRunning
                        ? const Color(0xFFFF6B35)
                        : const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 1.w),
                Text(
                  _isRunning ? 'Running' : 'Ready',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _isRunning
                        ? const Color(0xFFFF6B35)
                        : const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LoadTestControlPanelWidget(
            selectedTierIndex: _selectedTierIndex,
            isRunning: _isRunning,
            testWebSocket: _testWebSocket,
            testBlockchain: _testBlockchain,
            testDatabase: _testDatabase,
            testApi: _testApi,
            progressMessage: _progressMessage,
            onTierChanged: (v) => setState(() => _selectedTierIndex = v),
            onWebSocketToggle: (v) => setState(() => _testWebSocket = v),
            onBlockchainToggle: (v) => setState(() => _testBlockchain = v),
            onDatabaseToggle: (v) => setState(() => _testDatabase = v),
            onApiToggle: (v) => setState(() => _testApi = v),
            onRunTest: _executeLoadTest,
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6C63FF),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF6C63FF),
              labelStyle: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'WebSocket'),
                Tab(text: 'Blockchain'),
                Tab(text: 'Regressions'),
                Tab(text: 'History'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TestResultsPanelWidget(
                  report: _currentReport,
                  isRunning: _isRunning,
                  throughputData: _throughputData,
                  tabType: 'websocket',
                ),
                TestResultsPanelWidget(
                  report: _currentReport,
                  isRunning: _isRunning,
                  throughputData: _throughputData,
                  tabType: 'blockchain',
                ),
                RegressionAlertsPanelWidget(
                  regressions: _currentReport?.regressionsDetected ?? [],
                  isRunning: _isRunning,
                ),
                TestHistoryTableWidget(history: _testHistory),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
