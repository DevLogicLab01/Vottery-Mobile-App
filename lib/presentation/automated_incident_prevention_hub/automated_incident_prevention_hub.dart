import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/claude_prevention_service.dart';

class AutomatedIncidentPreventionHub extends StatefulWidget {
  const AutomatedIncidentPreventionHub({super.key});

  @override
  State<AutomatedIncidentPreventionHub> createState() =>
      _AutomatedIncidentPreventionHubState();
}

class _AutomatedIncidentPreventionHubState
    extends State<AutomatedIncidentPreventionHub> {
  final ClaudePreventionService _service = ClaudePreventionService.instance;
  List<Map<String, dynamic>> _activePolicies = [];
  List<Map<String, dynamic>> _pendingRules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _service.getActivePolicies(),
        _service.getPendingRules(),
      ]);

      setState(() {
        _activePolicies = results[0];
        _pendingRules = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Automated Incident Prevention'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricsOverview(),
                    SizedBox(height: 3.h),
                    Text(
                      'Active Prevention Rules',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ..._activePolicies.map(_buildPolicyCard),
                    SizedBox(height: 3.h),
                    Text(
                      'Pending Review',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ..._pendingRules.map(_buildPendingRuleCard),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsOverview() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            'Active Rules',
            _activePolicies.length.toString(),
            Colors.green,
          ),
          _buildMetricItem(
            'Pending Review',
            _pendingRules.length.toString(),
            Colors.orange,
          ),
          _buildMetricItem('Attacks Prevented', '0', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPolicyCard(Map<String, dynamic> policy) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: Colors.green, size: 20.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Policy ${policy['id']}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: policy['policy_status'] == 'enabled',
                onChanged: (value) async {
                  await _service.updateRuleStatus(
                    ruleId: policy['id'],
                    status: value ? 'enabled' : 'disabled',
                  );
                  await _loadData();
                },
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Created by: ${policy['created_by']}',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRuleCard(Map<String, dynamic> rule) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.withAlpha(51)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Rule ${rule['id']}',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _service.applyRule(rule);
                    await _loadData();
                  },
                  child: const Text('Approve'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
