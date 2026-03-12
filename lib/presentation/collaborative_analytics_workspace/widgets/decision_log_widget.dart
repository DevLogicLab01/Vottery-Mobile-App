import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';
import './decision_form_dialog_widget.dart';
import './decision_card_widget.dart';

class DecisionLogWidget extends StatefulWidget {
  final String workspaceId;

  const DecisionLogWidget({super.key, required this.workspaceId});

  @override
  State<DecisionLogWidget> createState() => _DecisionLogWidgetState();
}

class _DecisionLogWidgetState extends State<DecisionLogWidget> {
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _decisionsByStatus = {
    'proposed': [],
    'under_review': [],
    'approved': [],
    'rejected': [],
    'implemented': [],
  };

  @override
  void initState() {
    super.initState();
    _loadDecisions();
  }

  Future<void> _loadDecisions() async {
    setState(() => _isLoading = true);

    try {
      final response = await _client
          .from('decision_log')
          .select('*, proposer:user_profiles!proposer_id(*)')
          .eq('workspace_id', widget.workspaceId)
          .order('created_at', ascending: false);

      final decisions = List<Map<String, dynamic>>.from(response);

      final grouped = <String, List<Map<String, dynamic>>>{
        'proposed': [],
        'under_review': [],
        'approved': [],
        'rejected': [],
        'implemented': [],
      };

      for (var decision in decisions) {
        final status = decision['status'] as String;
        grouped[status]?.add(decision);
      }

      setState(() {
        _decisionsByStatus = grouped;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load decisions error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDecisionStatus(
    String decisionId,
    String newStatus,
  ) async {
    try {
      await _client
          .from('decision_log')
          .update({'status': newStatus})
          .eq('id', decisionId);

      await _loadDecisions();
    } catch (e) {
      debugPrint('Update decision status error: $e');
    }
  }

  void _showDecisionForm() {
    showDialog(
      context: context,
      builder: (context) => DecisionFormDialogWidget(
        workspaceId: widget.workspaceId,
        onSubmit: (data) async {
          await _createDecision(data);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _createDecision(Map<String, dynamic> data) async {
    try {
      await _client.from('decision_log').insert({
        ...data,
        'workspace_id': widget.workspaceId,
        'proposer_id': _auth.currentUser!.id,
        'status': 'proposed',
      });

      await _loadDecisions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Decision created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Create decision error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: SkeletonCard(height: 15.h, width: double.infinity),
          );
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(4.w),
          child: ElevatedButton.icon(
            onPressed: _showDecisionForm,
            icon: const Icon(Icons.add),
            label: const Text('Add Decision'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 6.h),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusColumn('Proposed', 'proposed', theme),
                _buildStatusColumn('Under Review', 'under_review', theme),
                _buildStatusColumn('Approved', 'approved', theme),
                _buildStatusColumn('Rejected', 'rejected', theme),
                _buildStatusColumn('Implemented', 'implemented', theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusColumn(String title, String status, ThemeData theme) {
    final decisions = _decisionsByStatus[status] ?? [];

    return Container(
      width: 80.w,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withAlpha(51),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    decisions.length.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          ...decisions.map((decision) {
            return DecisionCardWidget(
              decision: decision,
              onStatusChange: (newStatus) =>
                  _updateDecisionStatus(decision['id'], newStatus),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'proposed':
        return Colors.blue;
      case 'under_review':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'implemented':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
