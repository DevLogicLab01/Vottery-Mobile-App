import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/verification_audit_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/audit_report_card_widget.dart';
import './widgets/blockchain_proof_widget.dart';
import './widgets/verification_result_card_widget.dart';
import './widgets/voting_history_selection_widget.dart';

/// Verify & Audit Elections Hub - Comprehensive blockchain verification and audit capabilities
/// Accessible from vote history and left sidebar menu for transparent election integrity checking
class VerifyAuditElectionsHub extends StatefulWidget {
  const VerifyAuditElectionsHub({super.key});

  @override
  State<VerifyAuditElectionsHub> createState() =>
      _VerifyAuditElectionsHubState();
}

class _VerifyAuditElectionsHubState extends State<VerifyAuditElectionsHub>
    with SingleTickerProviderStateMixin {
  final VerificationAuditService _verificationService =
      VerificationAuditService.instance;
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _votingHistory = [];
  Set<String> _selectedElections = {};
  Map<String, dynamic>? _verificationResults;
  List<Map<String, dynamic>> _auditReports = [];
  bool _isVerifying = false;

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
      final history = await _verificationService.getVotingHistory();

      setState(() {
        _votingHistory = history;
      });
    } catch (e) {
      debugPrint('Load verification data error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifySelected() async {
    if (_selectedElections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one election to verify'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final requestId = await _verificationService.submitVerificationRequest(
        _selectedElections.toList(),
      );

      if (requestId != null) {
        // Wait for verification to complete
        await Future.delayed(Duration(seconds: 2));

        final results = await _verificationService.getVerificationRequest(
          requestId,
        );

        setState(() {
          _verificationResults = results;
          _selectedElections.clear();
        });

        // Switch to results tab
        _tabController.animateTo(1);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification completed successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Verify selected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'VerifyAuditElectionsHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Verify & Audit Elections',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'info',
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              onPressed: () => _showInfoDialog(),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : Column(
                children: [
                  // Verification Status Header
                  _buildStatusHeader(theme),

                  SizedBox(height: 2.h),

                  // Tab Bar
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.onPrimary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      indicator: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Select'),
                        Tab(text: 'Results'),
                        Tab(text: 'Audit'),
                      ],
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSelectionTab(theme),
                        _buildResultsTab(theme),
                        _buildAuditTab(theme),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton:
            _tabController.index == 0 && _selectedElections.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _isVerifying ? null : _verifySelected,
                backgroundColor: theme.colorScheme.primary,
                icon: _isVerifying
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : CustomIconWidget(
                        iconName: 'verified',
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                label: Text(
                  _isVerifying
                      ? 'Verifying...'
                      : 'Verify Selected (${_selectedElections.length})',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildStatusHeader(ThemeData theme) {
    final totalElections = _votingHistory.length;
    final verifiedCount = _verificationResults != null
        ? (_verificationResults!['verification_results'] as Map).values
              .where((result) => result['status'] == 'verified')
              .length
        : 0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            theme,
            'Total Elections',
            totalElections.toString(),
            Icons.how_to_vote,
          ),
          Container(
            width: 1,
            height: 6.h,
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
          ),
          _buildStatColumn(
            theme,
            'Verified',
            verifiedCount.toString(),
            Icons.verified,
          ),
          Container(
            width: 1,
            height: 6.h,
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
          ),
          _buildStatColumn(
            theme,
            'Audit Trail',
            _auditReports.length.toString(),
            Icons.description,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.onPrimary, size: 8.w),
        SizedBox(height: 1.h),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSelectionTab(ThemeData theme) {
    if (_votingHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'ballot',
              color: theme.colorScheme.onSurfaceVariant,
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'No voting history found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Cast your first vote to start verifying',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return VotingHistorySelectionWidget(
      votingHistory: _votingHistory,
      selectedElections: _selectedElections,
      onSelectionChanged: (selected) {
        setState(() => _selectedElections = selected);
      },
    );
  }

  Widget _buildResultsTab(ThemeData theme) {
    if (_verificationResults == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'pending_actions',
              color: theme.colorScheme.onSurfaceVariant,
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'No verification results yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Select elections and verify to see results',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final results =
        _verificationResults!['verification_results'] as Map<String, dynamic>;

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final electionId = results.keys.elementAt(index);
        final result = results[electionId];

        return VerificationResultCardWidget(
          electionId: electionId,
          result: result,
          onViewBlockchainProof: () => _showBlockchainProof(result),
        );
      },
    );
  }

  Widget _buildAuditTab(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(4.w),
          child: Text(
            'Generate comprehensive audit reports with timeline visualization and blockchain verification links',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: _auditReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'description',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 64,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No audit reports generated',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      ElevatedButton.icon(
                        onPressed: () => _generateAuditReport(),
                        icon: Icon(Icons.add),
                        label: Text('Generate Audit Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _auditReports.length,
                  itemBuilder: (context, index) {
                    return AuditReportCardWidget(
                      report: _auditReports[index],
                      onDownload: () =>
                          _downloadAuditReport(_auditReports[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showBlockchainProof(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlockchainProofWidget(result: result),
    );
  }

  Future<void> _generateAuditReport() async {
    // Show election selection dialog
    final selectedElection = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Election'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _votingHistory.length,
            itemBuilder: (context, index) {
              final vote = _votingHistory[index];
              final election = vote['elections'] as Map<String, dynamic>;
              return ListTile(
                title: Text(election['title'] ?? 'Unknown'),
                onTap: () => Navigator.pop(context, election['id']),
              );
            },
          ),
        ),
      ),
    );

    if (selectedElection != null) {
      final reportId = await _verificationService.generateAuditReport(
        selectedElection,
      );

      if (reportId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audit report generated successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        // Reload audit reports
        final reports = await _verificationService.getElectionAuditReports(
          selectedElection,
        );
        setState(() => _auditReports = reports);
      }
    }
  }

  Future<void> _downloadAuditReport(Map<String, dynamic> report) async {
    try {
      final pdf = pw.Document();
      final title = report['report_name']?.toString() ?? 'Election Audit Report';
      final generatedAt =
          report['generated_at']?.toString() ?? DateTime.now().toIso8601String();
      final verificationStatus =
          report['verification_status']?.toString() ?? 'unknown';
      final electionId = report['election_id']?.toString() ?? 'N/A';
      final blockchainRef = report['blockchain_reference']?.toString() ?? 'N/A';
      final reportId = report['id']?.toString() ?? 'N/A';

      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(level: 0, child: pw.Text(title)),
            pw.Paragraph(text: 'Report ID: $reportId'),
            pw.Paragraph(text: 'Election ID: $electionId'),
            pw.Paragraph(text: 'Generated At: $generatedAt'),
            pw.Paragraph(text: 'Verification Status: $verificationStatus'),
            pw.Paragraph(text: 'Blockchain Reference: $blockchainRef'),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/audit-report-${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Election audit report',
        subject: title,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not export report: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 2.w),
            Text('About Verification'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Blockchain Verification',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Text(
                'Your votes are secured with blockchain technology. Each vote generates a unique hash that is permanently recorded in an immutable audit log.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 2.h),
              Text(
                'Public Verification',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Text(
                'Anyone can verify election integrity without revealing individual vote choices through cryptographic proof validation.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 2.h),
              Text(
                'Audit Reports',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Text(
                'Generate comprehensive audit reports with timeline visualization, blockchain transaction references, and verification status for complete transparency.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
}
