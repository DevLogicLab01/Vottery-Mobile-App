import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/bulk_management_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Bulk Management: process multiple elections, users, or compliance with progress and rollback (Web parity).
class BulkManagementScreen extends StatefulWidget {
  const BulkManagementScreen({super.key});

  @override
  State<BulkManagementScreen> createState() => _BulkManagementScreenState();
}

class _BulkManagementScreenState extends State<BulkManagementScreen> {
  final BulkManagementService _bulk = BulkManagementService.instance;

  bool _loading = true;
  List<Map<String, dynamic>> _operations = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic>? _selectedDetail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _bulk.getBulkOperations(limit: 50),
        _bulk.getBulkOperationStatistics('30d'),
      ]);
      if (mounted) {
        setState(() {
          _operations = results[0] as List<Map<String, dynamic>>;
          _stats = results[1] as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDetail(String id) async {
    final detail = await _bulk.getBulkOperationDetails(id);
    if (mounted) setState(() => _selectedDetail = detail);
  }

  Future<void> _createOperation() async {
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _CreateOperationDialog(),
    );
    if (result == null || !mounted) return;
    final ids = (result['ids'] as String?)
            ?.split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one entity ID (comma-separated)')),
      );
      return;
    }
    final op = await _bulk.createBulkOperation(
      operationName: result['name'] as String? ?? 'Bulk operation',
      operationType: result['type'] as String? ?? 'election_approval',
      targetEntityType: result['entityType'] as String? ?? 'elections',
      targetEntityIds: ids,
    );
    if (op != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation created')),
      );
      _load();
    }
  }

  Future<void> _execute(String id) async {
    final ok = await _bulk.executeBulkOperation(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Execution started' : 'Failed')),
      );
      if (ok) _load();
    }
  }

  Future<void> _rollback(String id) async {
    final ok = await _bulk.rollbackBulkOperation(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Rollback completed' : 'Rollback failed')),
      );
      if (ok) {
        _load();
        _selectedDetail = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'BulkManagementScreen',
      onRetry: _load,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Bulk Management',
          variant: CustomAppBarVariant.withBack,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _load,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Process multiple elections, users, or compliance with progress tracking and rollback.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      _buildStats(theme),
                      SizedBox(height: 3.h),
                      Text(
                        'Operation History',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      if (_operations.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.w),
                            child: Text(
                              'No bulk operations yet. Create one from the Web dashboard or add a create flow here.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
                      else
                        ..._operations.map((op) => _buildOperationCard(theme, op)),
                      if (_selectedDetail != null) ...[
                        SizedBox(height: 3.h),
                        _buildDetailPanel(theme),
                      ],
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createOperation,
          icon: const Icon(Icons.add),
          label: const Text('New operation'),
        ),
      ),
    );
  }

  Widget _buildStats(ThemeData theme) {
    return Row(
      children: [
        _statChip(theme, 'Total', _stats['total']?.toString() ?? '0'),
        SizedBox(width: 2.w),
        _statChip(theme, 'Completed', _stats['completed']?.toString() ?? '0'),
        SizedBox(width: 2.w),
        _statChip(theme, 'Processing', _stats['processing']?.toString() ?? '0'),
        SizedBox(width: 2.w),
        _statChip(theme, 'Failed', _stats['failed']?.toString() ?? '0'),
      ],
    );
  }

  Widget _statChip(ThemeData theme, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationCard(ThemeData theme, Map<String, dynamic> op) {
    final id = op['id'] as String?;
    final name = op['operation_name'] as String? ?? 'Operation';
    final status = op['status'] as String? ?? 'pending';
    final progress = (op['progress_percentage'] as num?)?.toDouble() ?? 0.0;
    final total = op['total_items'] as int? ?? 0;
    final processed = op['processed_items'] as int? ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        title: Text(name),
        subtitle: Text(
          '$status • $processed / $total (${progress.toStringAsFixed(0)}%)',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == 'pending')
              TextButton(
                onPressed: id == null ? null : () => _execute(id),
                child: const Text('Execute'),
              ),
            if (status == 'completed' && (op['rollback_enabled'] == true))
              TextButton(
                onPressed: id == null ? null : () => _rollback(id),
                child: const Text('Rollback'),
              ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: id == null ? null : () => _loadDetail(id),
            ),
          ],
        ),
        onTap: id == null ? null : () => _loadDetail(id),
      ),
    );
  }

  Widget _buildDetailPanel(ThemeData theme) {
    final op = _selectedDetail!['operation'] as Map<String, dynamic>?;
    final items = _selectedDetail!['items'] as List<dynamic>? ?? [];
    final logs = _selectedDetail!['logs'] as List<dynamic>? ?? [];
    if (op == null) return const SizedBox();

    final id = op['id'] as String?;
    final status = op['status'] as String? ?? '';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedDetail = null),
                ),
              ],
            ),
            Text('Status: $status'),
            Text('Items: ${items.length}'),
            Text('Logs: ${logs.length}'),
            if (status == 'pending' && id != null) ...[
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () => _execute(id),
                child: const Text('Execute operation'),
              ),
            ],
            if (status == 'completed' &&
                (op['rollback_enabled'] == true) &&
                id != null) ...[
              SizedBox(height: 2.h),
              OutlinedButton(
                onPressed: () => _rollback(id),
                child: const Text('Rollback'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateOperationDialog extends StatefulWidget {
  @override
  State<_CreateOperationDialog> createState() => _CreateOperationDialogState();
}

class _CreateOperationDialogState extends State<_CreateOperationDialog> {
  final _nameController = TextEditingController(
    text: 'Bulk op ${DateTime.now().millisecondsSinceEpoch}',
  );
  final _idsController = TextEditingController();
  String _type = 'election_approval';
  String _entityType = 'elections';

  @override
  void dispose() {
    _nameController.dispose();
    _idsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('New bulk operation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Operation name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Operation type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'election_approval', child: Text('Election approval')),
                DropdownMenuItem(value: 'election_rejection', child: Text('Election rejection')),
                DropdownMenuItem(value: 'user_suspension', child: Text('User suspension')),
                DropdownMenuItem(value: 'user_activation', child: Text('User activation')),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              value: _entityType,
              decoration: const InputDecoration(
                labelText: 'Entity type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'elections', child: Text('elections')),
                DropdownMenuItem(value: 'user_profiles', child: Text('user_profiles')),
              ],
              onChanged: (v) => setState(() => _entityType = v ?? _entityType),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _idsController,
              decoration: const InputDecoration(
                labelText: 'Entity IDs (comma-separated)',
                border: OutlineInputBorder(),
                hintText: 'uuid1, uuid2, uuid3',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'name': _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
              'type': _type,
              'entityType': _entityType,
              'ids': _idsController.text.trim(),
            });
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
