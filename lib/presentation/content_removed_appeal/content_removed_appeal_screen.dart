import 'package:flutter/material.dart';
import '../../services/moderation_shared_service.dart';
import '../../routes/app_routes.dart';

/// User-facing screen: view removed content and submit/track appeals (aligned with Web).
class ContentRemovedAppealScreen extends StatefulWidget {
  const ContentRemovedAppealScreen({super.key});

  @override
  State<ContentRemovedAppealScreen> createState() =>
      _ContentRemovedAppealScreenState();
}

class _ContentRemovedAppealScreenState extends State<ContentRemovedAppealScreen> {
  final _moderation = ModerationSharedService.instance;
  List<Map<String, dynamic>> _removed = [];
  List<Map<String, dynamic>> _appeals = [];
  bool _loading = true;
  String? _error;
  String? _submittingContentId;
  final _reasonController = TextEditingController();
  Map<String, dynamic>? _selectedContent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final removed = await _moderation.getRemovedContentForUser();
      final appeals = await _moderation.getMyAppeals();
      if (mounted) {
        setState(() {
          _removed = removed;
          _appeals = appeals;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _submitAppeal() async {
    if (_selectedContent == null) return;
    final contentId = _selectedContent!['content_id'] as String?;
    final contentType = _selectedContent!['content_type'] as String?;
    if (contentId == null || contentType == null) return;
    setState(() {
      _submittingContentId = contentId;
      _error = null;
    });
    try {
      final result = await _moderation.submitAppealByContent(
        contentId: contentId,
        contentType: contentType,
        reason: _reasonController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _submittingContentId = null;
          _selectedContent = null;
          _reasonController.clear();
        });
        if (result != null) await _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submittingContentId = null;
          _error = e.toString();
        });
      }
    }
  }

  String _statusLabel(dynamic status, dynamic outcome) {
    if (status == null) return '—';
    final s = status.toString();
    if (outcome != null) return '$s (${outcome})';
    return s;
  }

  Color _statusColor(dynamic status) {
    final s = status?.toString() ?? '';
    if (s == 'pending') return Colors.amber;
    if (s == 'overturned') return Colors.green;
    if (s == 'upheld' || s == 'dismissed') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Removed & Appeals'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'If your content was removed, you can appeal. We review appeals within a few business days.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!),
                    ),
                  ),
                ),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Text(
                  'Removed content',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_removed.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('You have no removed content.'),
                    ),
                  )
                else
                  ..._removed.map((item) {
                    final appeal = item['appeal'] as Map<String, dynamic>?;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['content_type']} • ${item['violation_type']}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['content_snippet']?.toString() ?? 'Content removed',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item['created_at'] != null)
                              Text(
                                _formatDate(item['created_at']),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            const SizedBox(height: 8),
                            if (appeal != null)
                              Chip(
                                label: Text(
                                  _statusLabel(appeal['status'], appeal['outcome']),
                                ),
                                backgroundColor: _statusColor(appeal['status']).withValues(alpha: 0.2),
                              )
                            else
                              TextButton(
                                onPressed: () => setState(() {
                                  _selectedContent = {
                                    'content_id': item['content_id'],
                                    'content_type': item['content_type'],
                                  };
                                }),
                                child: const Text('Appeal'),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                if (_selectedContent != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Submit appeal',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _reasonController,
                            decoration: const InputDecoration(
                              hintText: 'Why should this content be restored?',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              FilledButton(
                                onPressed: _submittingContentId != null
                                    ? null
                                    : _submitAppeal,
                                child: Text(
                                  _submittingContentId != null
                                      ? 'Submitting...'
                                      : 'Submit appeal',
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => setState(() {
                                  _selectedContent = null;
                                  _reasonController.clear();
                                }),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'My appeals',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_appeals.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('You have not submitted any appeals.'),
                    ),
                  )
                else
                  ..._appeals.map((a) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${a['content_type']}',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                  const Spacer(),
                                  Chip(
                                    label: Text(
                                      _statusLabel(a['status'], a['outcome']),
                                    ),
                                    backgroundColor: _statusColor(a['status']).withValues(alpha: 0.2),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(a['reason']?.toString() ?? ''),
                              if (a['created_at'] != null)
                                Text(
                                  'Submitted ${_formatDate(a['created_at'])}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic v) {
    if (v == null) return '';
    if (v is DateTime) return v.toIso8601String();
    return v.toString();
  }
}
