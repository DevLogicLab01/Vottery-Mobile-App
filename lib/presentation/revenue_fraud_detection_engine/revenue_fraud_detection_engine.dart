import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/openai_fraud_detection_service.dart';
import '../../services/resend_email_service.dart';
import '../../services/supabase_service.dart';
import '../../services/twilio_notification_service.dart';

class RevenueFraudDetectionEngine extends StatefulWidget {
  const RevenueFraudDetectionEngine({super.key});

  @override
  State<RevenueFraudDetectionEngine> createState() =>
      _RevenueFraudDetectionEngineState();
}

class _RevenueFraudDetectionEngineState
    extends State<RevenueFraudDetectionEngine> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final OpenAIFraudDetectionService _fraudService =
      OpenAIFraudDetectionService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _fraudAlerts = [];
  Map<String, dynamic> _fraudMetrics = {};
  String _selectedFilter = 'all';
  Map<String, dynamic>? _selectedAlert;

  @override
  void initState() {
    super.initState();
    _loadFraudData();
  }

  Future<void> _loadFraudData() async {
    setState(() => _isLoading = true);
    try {
      // Detect payout manipulation
      await _detectPayoutManipulation();

      // Detect creator override exploitation
      await _detectCreatorOverrideExploitation();

      // Detect campaign split abuse
      await _detectCampaignSplitAbuse();

      // Load fraud alerts
      final alerts = await _supabaseService.client
          .from('fraud_alerts')
          .select()
          .order('detected_at', ascending: false)
          .limit(50);

      // Calculate metrics
      final metrics = await _calculateFraudMetrics();

      setState(() {
        _fraudAlerts = List<Map<String, dynamic>>.from(alerts);
        _fraudMetrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading fraud data: $e')));
      }
    }
  }

  Future<void> _detectPayoutManipulation() async {
    // Query creator payouts from last 30 days
    final payouts = await _supabaseService.client
        .from('creator_payouts')
        .select()
        .gte(
          'created_at',
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        );

    // Group by creator and analyze patterns
    Map<String, List<Map<String, dynamic>>> payoutsByCreator = {};
    for (var payout in payouts) {
      final creatorId = payout['creator_id'];
      payoutsByCreator[creatorId] = payoutsByCreator[creatorId] ?? [];
      payoutsByCreator[creatorId]!.add(payout);
    }

    // Analyze each creator's payout patterns
    for (var entry in payoutsByCreator.entries) {
      final creatorId = entry.key;
      final creatorPayouts = entry.value;

      if (creatorPayouts.length < 2) continue;

      // Calculate average payout
      final amounts = creatorPayouts
          .map((p) => (p['amount'] as num).toDouble())
          .toList();
      final average = amounts.reduce((a, b) => a + b) / amounts.length;
      final latest = amounts.last;

      // Check for suspicious increase
      final deviation = ((latest - average) / average * 100).abs();

      if (deviation > 300) {
        // High risk - create fraud alert
        await _createFraudAlert(
          alertType: 'payout_manipulation',
          creatorId: creatorId,
          riskScore: 95,
          indicators: [
            'Payout increased by ${deviation.toStringAsFixed(0)}% above average',
            'Amount: \$${latest.toStringAsFixed(2)} vs avg \$${average.toStringAsFixed(2)}',
          ],
        );
      } else if (deviation > 200) {
        // Medium risk
        await _createFraudAlert(
          alertType: 'payout_manipulation',
          creatorId: creatorId,
          riskScore: 75,
          indicators: [
            'Payout increased by ${deviation.toStringAsFixed(0)}% above average',
          ],
        );
      }

      // Check payout frequency
      final last7Days = creatorPayouts
          .where(
            (p) => DateTime.parse(
              p['created_at'],
            ).isAfter(DateTime.now().subtract(const Duration(days: 7))),
          )
          .length;

      if (last7Days > 4) {
        await _createFraudAlert(
          alertType: 'payout_manipulation',
          creatorId: creatorId,
          riskScore: 80,
          indicators: [
            'Unusual payout frequency: $last7Days payouts in 7 days',
          ],
        );
      }
    }
  }

  Future<void> _detectCreatorOverrideExploitation() async {
    // Query creator overrides from last 30 days
    final overrides = await _supabaseService.client
        .from('creator_overrides')
        .select()
        .gte(
          'created_at',
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        );

    // Group by creator
    Map<String, List<Map<String, dynamic>>> overridesByCreator = {};
    for (var override in overrides) {
      final creatorId = override['creator_id'];
      overridesByCreator[creatorId] = overridesByCreator[creatorId] ?? [];
      overridesByCreator[creatorId]!.add(override);
    }

    // Analyze patterns
    for (var entry in overridesByCreator.entries) {
      final creatorId = entry.key;
      final creatorOverrides = entry.value;

      // Check override count
      if (creatorOverrides.length > 5) {
        await _createFraudAlert(
          alertType: 'override_exploitation',
          creatorId: creatorId,
          riskScore: 85,
          indicators: [
            '${creatorOverrides.length} overrides in 30 days',
            'Potential abuse of override system',
          ],
        );
      }

      // Check total override amounts
      final totalAmount = creatorOverrides
          .map((o) => (o['override_amount'] as num?)?.toDouble() ?? 0)
          .reduce((a, b) => a + b);

      if (totalAmount > 1000) {
        await _createFraudAlert(
          alertType: 'override_exploitation',
          creatorId: creatorId,
          riskScore: 90,
          indicators: [
            'Total override amount: \$${totalAmount.toStringAsFixed(2)}',
            'Exceeds \$1000 threshold',
          ],
        );
      }

      // Check for missing justifications
      final missingJustification = creatorOverrides
          .where(
            (o) =>
                o['justification'] == null ||
                o['justification'] == 'N/A' ||
                o['justification'] == 'miscellaneous',
          )
          .length;

      if (missingJustification > 2) {
        await _createFraudAlert(
          alertType: 'override_exploitation',
          creatorId: creatorId,
          riskScore: 70,
          indicators: [
            '$missingJustification overrides with missing/generic justification',
          ],
        );
      }
    }
  }

  Future<void> _detectCampaignSplitAbuse() async {
    // Query campaign revenue splits
    final splits = await _supabaseService.client
        .from('campaign_revenue_splits')
        .select()
        .gte(
          'updated_at',
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        );

    // Group by campaign
    Map<String, List<Map<String, dynamic>>> splitsByCampaign = {};
    for (var split in splits) {
      final campaignId = split['campaign_id'];
      splitsByCampaign[campaignId] = splitsByCampaign[campaignId] ?? [];
      splitsByCampaign[campaignId]!.add(split);
    }

    // Analyze patterns
    for (var entry in splitsByCampaign.entries) {
      final campaignId = entry.key;
      final campaignSplits = entry.value;

      // Check modification frequency
      if (campaignSplits.length > 3) {
        await _createFraudAlert(
          alertType: 'split_abuse',
          campaignId: campaignId,
          riskScore: 75,
          indicators: [
            'Revenue split modified ${campaignSplits.length} times',
            'Potential manipulation',
          ],
        );
      }

      // Check creator allocation percentage
      final latestSplit = campaignSplits.last;
      final creatorAllocation =
          latestSplit['creator_allocation_percentage'] ?? 0;

      if (creatorAllocation > 80) {
        await _createFraudAlert(
          alertType: 'split_abuse',
          campaignId: campaignId,
          riskScore: 85,
          indicators: [
            'Creator allocation: $creatorAllocation% (normal: 60-70%)',
            'Unusually high creator split',
          ],
        );
      }
    }
  }

  Future<void> _createFraudAlert({
    required String alertType,
    String? creatorId,
    String? campaignId,
    required int riskScore,
    required List<String> indicators,
  }) async {
    // Check if similar alert already exists
    final existing = await _supabaseService.client
        .from('fraud_alerts')
        .select()
        .eq('alert_type', alertType)
        .eq('affected_creator_id', creatorId ?? '')
        .eq('status', 'pending')
        .maybeSingle();

    if (existing != null) return; // Alert already exists

    // Determine risk level
    String riskLevel;
    if (riskScore > 90) {
      riskLevel = 'critical';
    } else if (riskScore > 75) {
      riskLevel = 'high';
    } else if (riskScore > 50) {
      riskLevel = 'medium';
    } else {
      riskLevel = 'low';
    }

    // Create alert
    await _supabaseService.client.from('fraud_alerts').insert({
      'alert_type': alertType,
      'detected_at': DateTime.now().toIso8601String(),
      'affected_creator_id': creatorId,
      'affected_campaign_id': campaignId,
      'fraud_indicators': indicators,
      'risk_score': riskScore,
      'risk_level': riskLevel,
      'status': 'pending',
      'confidence_level': 'high',
    });

    // Send notifications for high-risk alerts
    if (riskScore > 90) {
      await _sendFraudNotification(alertType, riskScore, indicators);
    }

    // Execute automated actions based on risk level
    if (riskScore > 90) {
      await _executeAutomatedActions(creatorId, riskLevel);
    }
  }

  Future<void> _sendFraudNotification(
    String alertType,
    int riskScore,
    List<String> indicators,
  ) async {
    try {
      // Send SMS alert
      await TwilioNotificationService.instance.sendVoteDeadlineNotification(
        phoneNumber: const String.fromEnvironment('FRAUD_TEAM_PHONE'),
        voteTitle: 'FRAUD ALERT',
        deadline: DateTime.now(),
      );

      // Send email alert
      await ResendEmailService.instance.sendComplianceReport(
        recipientEmail: const String.fromEnvironment('FRAUD_TEAM_EMAIL'),
        reportType: 'Fraud Alert',
        reportData: {
          'alert_type': alertType,
          'risk_score': riskScore,
          'indicators': indicators,
        },
      );
    } catch (e) {
      // Silent fail - don't block fraud detection
    }
  }

  Future<void> _executeAutomatedActions(
    String? creatorId,
    String riskLevel,
  ) async {
    if (creatorId == null) return;

    if (riskLevel == 'critical') {
      // Freeze payouts
      await _supabaseService.client
          .from('creator_accounts')
          .update({'payouts_enabled': false})
          .eq('creator_id', creatorId);

      // Add investigation flag
      await _supabaseService.client
          .from('user_profiles')
          .update({'fraud_investigation_required': true})
          .eq('id', creatorId);
    } else if (riskLevel == 'high') {
      // Enhanced monitoring
      await _supabaseService.client
          .from('creator_accounts')
          .update({'enhanced_monitoring': true, 'daily_payout_limit': 100})
          .eq('creator_id', creatorId);
    }
  }

  Future<Map<String, dynamic>> _calculateFraudMetrics() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Active alerts
    final activeAlerts = await _supabaseService.client
        .from('fraud_alerts')
        .select()
        .eq('status', 'pending');

    // Blocked payouts today
    final blockedPayouts = await _supabaseService.client
        .from('creator_payouts')
        .select()
        .eq('status', 'blocked')
        .gte('created_at', today.toIso8601String());

    final blockedAmount = blockedPayouts
        .map((p) => (p['amount'] as num?)?.toDouble() ?? 0)
        .fold(0.0, (a, b) => a + b);

    // Confirmed fraud this month
    final confirmedFraud = await _supabaseService.client
        .from('fraud_alerts')
        .select()
        .eq('status', 'confirmed')
        .gte('detected_at', DateTime(now.year, now.month, 1).toIso8601String());

    // False positive rate
    final falsePositives = await _supabaseService.client
        .from('fraud_alerts')
        .select()
        .eq('status', 'false_positive')
        .gte('detected_at', DateTime(now.year, now.month, 1).toIso8601String());

    final totalResolved = confirmedFraud.length + falsePositives.length;
    final falsePositiveRate = totalResolved > 0
        ? (falsePositives.length / totalResolved * 100)
        : 0.0;

    // Average detection time
    final resolvedAlerts = await _supabaseService.client
        .from('fraud_alerts')
        .select()
        .neq('status', 'pending')
        .gte('detected_at', DateTime(now.year, now.month, 1).toIso8601String());

    double avgDetectionTime = 0;
    if (resolvedAlerts.isNotEmpty) {
      final times = resolvedAlerts.map((alert) {
        final detected = DateTime.parse(alert['detected_at']);
        final resolved = DateTime.parse(alert['updated_at']);
        return resolved.difference(detected).inHours;
      }).toList();
      avgDetectionTime = times.reduce((a, b) => a + b) / times.length;
    }

    return {
      'active_alerts': activeAlerts.length,
      'blocked_payouts_today': blockedPayouts.length,
      'blocked_amount': blockedAmount,
      'confirmed_fraud_month': confirmedFraud.length,
      'false_positive_rate': falsePositiveRate,
      'avg_detection_time_hours': avgDetectionTime,
    };
  }

  Future<void> _confirmFraud(String alertId) async {
    await _supabaseService.client
        .from('fraud_alerts')
        .update({'status': 'confirmed'})
        .eq('id', alertId);
    _loadFraudData();
  }

  Future<void> _markFalsePositive(String alertId) async {
    await _supabaseService.client
        .from('fraud_alerts')
        .update({'status': 'false_positive'})
        .eq('id', alertId);
    _loadFraudData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Fraud Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFraudData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFraudData,
              child: Row(
                children: [
                  Expanded(flex: 2, child: _buildAlertsList()),
                  if (_selectedAlert != null)
                    Expanded(flex: 3, child: _buildInvestigationPanel()),
                ],
              ),
            ),
    );
  }

  Widget _buildAlertsList() {
    return Column(
      children: [
        _buildFraudOverview(),
        _buildFilterBar(),
        Expanded(child: _buildAlertCards()),
      ],
    );
  }

  Widget _buildFraudOverview() {
    return Container(
      padding: EdgeInsets.all(3.w),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Active Alerts',
                  _fraudMetrics['active_alerts']?.toString() ?? '0',
                  Colors.red,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Blocked Today',
                  _fraudMetrics['blocked_payouts_today']?.toString() ?? '0',
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Amount Saved',
                  '\$${(_fraudMetrics['blocked_amount'] ?? 0).toStringAsFixed(0)}',
                  Colors.green,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'False Positive',
                  '${(_fraudMetrics['false_positive_rate'] ?? 0).toStringAsFixed(1)}%',
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(2.w),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          _buildFilterChip('Critical', 'critical'),
          _buildFilterChip('High', 'high'),
          _buildFilterChip('Medium', 'medium'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: EdgeInsets.only(right: 1.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
        },
      ),
    );
  }

  Widget _buildAlertCards() {
    var filteredAlerts = _fraudAlerts;
    if (_selectedFilter != 'all') {
      filteredAlerts = _fraudAlerts
          .where((alert) => alert['risk_level'] == _selectedFilter)
          .toList();
    }

    if (filteredAlerts.isEmpty) {
      return const Center(child: Text('No fraud alerts'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: filteredAlerts.length,
      itemBuilder: (context, index) {
        final alert = filteredAlerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final riskLevel = alert['risk_level'] ?? 'low';
    final color = riskLevel == 'critical'
        ? Colors.red
        : riskLevel == 'high'
        ? Colors.orange
        : Colors.yellow;

    final isSelected = _selectedAlert?['id'] == alert['id'];

    return GestureDetector(
      onTap: () => setState(() => _selectedAlert = alert),
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(26) : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    alert['alert_type'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${alert['risk_score']}',
                    style: TextStyle(color: Colors.white, fontSize: 11.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Creator: ${alert['affected_creator_id'] ?? 'N/A'}',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
            Text(
              DateTime.parse(alert['detected_at']).toString(),
              style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestigationPanel() {
    if (_selectedAlert == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Investigation Details',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedAlert = null),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildInvestigationSection(
              'Alert Type',
              _selectedAlert!['alert_type'],
            ),
            _buildInvestigationSection(
              'Risk Score',
              '${_selectedAlert!['risk_score']}/100',
            ),
            _buildInvestigationSection(
              'Risk Level',
              _selectedAlert!['risk_level'],
            ),
            _buildInvestigationSection('Status', _selectedAlert!['status']),
            SizedBox(height: 2.h),
            Text(
              'Fraud Indicators:',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            ...(_selectedAlert!['fraud_indicators'] as List? ?? []).map(
              (indicator) => Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16.sp, color: Colors.orange),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(indicator, style: TextStyle(fontSize: 12.sp)),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmFraud(_selectedAlert!['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Confirm Fraud'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _markFalsePositive(_selectedAlert!['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('False Positive'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestigationSection(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13.sp)),
          ),
        ],
      ),
    );
  }
}
