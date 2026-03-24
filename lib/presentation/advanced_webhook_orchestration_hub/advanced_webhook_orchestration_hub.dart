import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/webhook_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

class AdvancedWebhookOrchestrationHub extends StatefulWidget {
  const AdvancedWebhookOrchestrationHub({super.key});

  @override
  State<AdvancedWebhookOrchestrationHub> createState() =>
      _AdvancedWebhookOrchestrationHubState();
}

class _AdvancedWebhookOrchestrationHubState
    extends State<AdvancedWebhookOrchestrationHub> {
  final WebhookService _webhookService = WebhookService.instance;
  final List<String> _tabs = <String>[
    'routing',
    'transformation',
    'retry',
    'correlation',
    'testing',
  ];

  String _activeTab = 'routing';
  bool _isLoading = true;
  List<Map<String, dynamic>> _webhookConfigs = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _deliveryLogs = <Map<String, dynamic>>[];
  String? _selectedConfigId;
  final TextEditingController _routingController = TextEditingController();
  final TextEditingController _transformController = TextEditingController();
  final TextEditingController _retryController = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _routingController.dispose();
    _transformController.dispose();
    _retryController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final configs = await _webhookService.getWebhookConfigurations();
    List<Map<String, dynamic>> logs = <Map<String, dynamic>>[];
    if (configs.isNotEmpty && configs.first['id'] != null) {
      logs = await _webhookService.getDeliveryLogs(
        configId: configs.first['id'].toString(),
        limit: 50,
      );
    }
    if (!mounted) return;
    setState(() {
      _webhookConfigs = configs;
      _deliveryLogs = logs;
      if (_selectedConfigId == null && configs.isNotEmpty) {
        _selectedConfigId = configs.first['id']?.toString();
      }
      _syncConfigEditors();
      _isLoading = false;
    });
  }

  Map<String, dynamic>? get _selectedConfig {
    if (_selectedConfigId == null) return null;
    try {
      return _webhookConfigs.firstWhere(
        (config) => config['id']?.toString() == _selectedConfigId,
      );
    } catch (_) {
      return null;
    }
  }

  void _syncConfigEditors() {
    final config = _selectedConfig;
    if (config == null) return;
    final customHeaders = Map<String, dynamic>.from(
      config['custom_headers'] ?? <String, dynamic>{},
    );
    _routingController.text =
        customHeaders['x-routing-rule']?.toString() ?? '';
    _transformController.text =
        customHeaders['x-payload-transform']?.toString() ?? '';
    _retryController.text =
        customHeaders['x-retry-max']?.toString() ??
        (config['max_retries']?.toString() ?? '5');
  }

  Future<void> _saveOrchestrationSettings() async {
    final config = _selectedConfig;
    if (config == null) return;
    final configId = config['id']?.toString();
    if (configId == null || configId.isEmpty) return;
    final existingHeaders = Map<String, dynamic>.from(
      config['custom_headers'] ?? <String, dynamic>{},
    );
    final newHeaders = <String, String>{
      ...existingHeaders.map((key, value) => MapEntry(key, value.toString())),
      'x-routing-rule': _routingController.text.trim(),
      'x-payload-transform': _transformController.text.trim(),
      'x-retry-max': _retryController.text.trim().isEmpty
          ? '5'
          : _retryController.text.trim(),
    };
    final success = await _webhookService.updateWebhookConfiguration(
      configId: configId,
      customHeaders: newHeaders,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Orchestration settings saved'
              : 'Failed to save orchestration settings',
        ),
      ),
    );
    if (success) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AdvancedWebhookOrchestrationHub',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Advanced Webhook Orchestration',
          variant: CustomAppBarVariant.withBack,
          actions: [
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildStatsRow(),
                  _buildTabBar(),
                  Expanded(child: _buildActiveTab()),
                ],
              ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final activeCount = _webhookConfigs.where((w) => w['is_active'] == true).length;
    final retryingCount = _deliveryLogs.where((l) => l['status'] == 'retrying').length;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Active', '$activeCount', Colors.green)),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard('Queue', '${_deliveryLogs.length}', Colors.purple),
          ),
          SizedBox(width: 2.w),
          Expanded(child: _buildStatCard('Retrying', '$retryingCount', Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
          ),
          SizedBox(height: 0.4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(3.w, 1.h, 3.w, 1.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs
              .map((tab) => Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: ChoiceChip(
                      label: Text(_tabLabel(tab)),
                      selected: _activeTab == tab,
                      onSelected: (_) => setState(() => _activeTab = tab),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_activeTab) {
      case 'routing':
        return _buildRoutingTab();
      case 'transformation':
        return _buildTransformationTab();
      case 'retry':
        return _buildRetryTab();
      case 'correlation':
        return _buildCorrelationTab();
      case 'testing':
        return _buildTestingTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRoutingTab() {
    final selectedConfig = _selectedConfig;
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        _buildConfigSelector(),
        SizedBox(height: 1.h),
        ..._webhookConfigs.map((config) {
          final events = List<String>.from(config['event_types'] ?? <String>[]);
          return Card(
            child: ListTile(
              title: Text(config['name']?.toString() ?? 'Webhook'),
              subtitle: Text(
                'Route by event types: ${events.isEmpty ? 'none' : events.join(', ')}',
              ),
              trailing: Icon(
                config['is_active'] == true ? Icons.check_circle : Icons.pause_circle,
                color: config['is_active'] == true ? Colors.green : Colors.grey,
              ),
            ),
          );
        }),
        if (selectedConfig != null) ...[
          SizedBox(height: 1.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conditional Routing Rule',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 1.h),
                  TextField(
                    controller: _routingController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'if severity == critical then route:incident_bridge',
                    ),
                  ),
                  SizedBox(height: 1.h),
                  ElevatedButton.icon(
                    onPressed: _saveOrchestrationSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Routing Rule'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfigSelector() {
    if (_webhookConfigs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: DropdownButtonFormField<String>(
          initialValue: _selectedConfigId ?? _webhookConfigs.first['id']?.toString(),
          decoration: const InputDecoration(
            labelText: 'Webhook configuration',
            border: OutlineInputBorder(),
          ),
          items: _webhookConfigs
              .map(
                (config) => DropdownMenuItem<String>(
                  value: config['id']?.toString(),
                  child: Text(config['name']?.toString() ?? 'Webhook'),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedConfigId = value;
              _syncConfigEditors();
            });
          },
        ),
      ),
    );
  }

  Widget _buildTransformationTab() {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        _buildConfigSelector(),
        SizedBox(height: 1.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payload Transformation Rule',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: _transformController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText:
                        'map: { user_id -> actor.id, event_type -> event.name }',
                  ),
                ),
                SizedBox(height: 1.h),
                ElevatedButton.icon(
                  onPressed: _saveOrchestrationSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Transformation'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetryTab() {
    final retries = _deliveryLogs.where((l) {
      final attempts = (l['attempts'] ?? l['attempt_count'] ?? 1) as int;
      return attempts > 1 || l['status'] == 'retrying';
    }).toList();

    if (retries.isEmpty) {
      return const Center(child: Text('No retry activity found'));
    }

    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        _buildConfigSelector(),
        SizedBox(height: 1.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Retry Policy',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: _retryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Max retries',
                  ),
                ),
                SizedBox(height: 1.h),
                ElevatedButton.icon(
                  onPressed: _saveOrchestrationSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Retry Policy'),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 1.h),
        ...retries.map((row) {
          final attempts = row['attempts'] ?? row['attempt_count'] ?? 1;
          return Card(
            child: ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(row['event_type']?.toString() ?? 'Unknown event'),
              subtitle: Text('Attempts: $attempts'),
              trailing: Text(row['status']?.toString() ?? 'pending'),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCorrelationTab() {
    final byEvent = <String, int>{};
    for (final row in _deliveryLogs) {
      final event = row['event_type']?.toString() ?? 'unknown';
      byEvent[event] = (byEvent[event] ?? 0) + 1;
    }

    return ListView(
      padding: EdgeInsets.all(3.w),
      children: byEvent.entries
          .map(
            (entry) => Card(
              child: ListTile(
                leading: const Icon(Icons.hub),
                title: Text(entry.key),
                subtitle: Text('Correlated deliveries: ${entry.value}'),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTestingTab() {
    if (_webhookConfigs.isEmpty) {
      return const Center(child: Text('No webhook configurations available'));
    }
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _webhookConfigs.length,
      itemBuilder: (_, index) {
        final config = _webhookConfigs[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.science),
            title: Text(config['name']?.toString() ?? 'Webhook'),
            subtitle: Text(config['webhook_url']?.toString() ?? ''),
            trailing: ElevatedButton(
              onPressed: () async {
                final result = await _webhookService.testWebhook(
                  configId: config['id'].toString(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['success'] == true
                          ? 'Test sent for ${config['name']}'
                          : 'Test failed: ${result['message']}',
                    ),
                  ),
                );
                _loadData();
              },
              child: const Text('Test'),
            ),
          ),
        );
      },
    );
  }

  String _tabLabel(String tab) {
    switch (tab) {
      case 'routing':
        return 'Conditional Routing';
      case 'transformation':
        return 'Payload Transformation';
      case 'retry':
        return 'Retry Policies';
      case 'correlation':
        return 'Cross-System Correlation';
      case 'testing':
        return 'Webhook Testing';
      default:
        return tab;
    }
  }
}
