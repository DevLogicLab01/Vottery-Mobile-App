import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';
import '../../../services/mcq_service.dart';

class ExportOptionsWidget extends StatefulWidget {
  final String? electionId;

  const ExportOptionsWidget({super.key, this.electionId});

  @override
  State<ExportOptionsWidget> createState() => _ExportOptionsWidgetState();
}

class _ExportOptionsWidgetState extends State<ExportOptionsWidget> {
  final MCQService _mcqService = MCQService.instance;
  bool _isExporting = false;

  Future<void> _exportToCSV() async {
    if (widget.electionId == null) return;

    setState(() => _isExporting = true);
    try {
      final csv = await _mcqService.exportFreeTextAnswersToCSV(
        electionId: widget.electionId!,
      );

      if (csv.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV export ready (${csv.length} bytes)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToJSON() async {
    if (widget.electionId == null) return;

    setState(() => _isExporting = true);
    try {
      final json = await _mcqService.exportFreeTextAnswersToJSON(
        electionId: widget.electionId!,
      );

      if (json.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('JSON export ready (${json.length} bytes)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportAnalyticsReport() async {
    if (widget.electionId == null) return;

    setState(() => _isExporting = true);
    try {
      final analytics = await _mcqService.getFreeTextAnalytics(
        electionId: widget.electionId!,
      );
      final totalResponses = analytics['total_responses'] ?? 0;
      final avgChars = analytics['average_character_count'] ?? 0.0;
      final moderationFlags = analytics['moderation_flags'] ?? 0;
      final sentiment = Map<String, dynamic>.from(
        analytics['sentiment_distribution'] ?? <String, dynamic>{},
      );
      final themes = (analytics['common_themes'] as List?) ?? const [];

      final report = StringBuffer()
        ..writeln('Vottery Open-Ended Answers Analytics')
        ..writeln('Election ID: ${widget.electionId}')
        ..writeln('Generated: ${DateTime.now().toIso8601String()}')
        ..writeln('')
        ..writeln('Summary')
        ..writeln('- Total responses: $totalResponses')
        ..writeln('- Avg character count: $avgChars')
        ..writeln('- Moderation flags: $moderationFlags')
        ..writeln('')
        ..writeln('Sentiment distribution')
        ..writeln(
          sentiment.isEmpty
              ? '- No sentiment data'
              : sentiment.entries.map((e) => '- ${e.key}: ${e.value}').join('\n'),
        )
        ..writeln('')
        ..writeln('Common themes')
        ..writeln(
          themes.isEmpty
              ? '- No themes detected'
              : themes.map((t) => '- $t').join('\n'),
        );

      await Share.share(
        report.toString(),
        subject: 'Open-ended analytics report',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.electionId == null) {
      return Center(
        child: Text(
          'Please select an election first',
          style: TextStyle(fontSize: 13.sp, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExportCard(
            'Export to CSV',
            'Download all responses in CSV format for spreadsheet analysis',
            Icons.table_chart,
            Colors.green,
            _exportToCSV,
          ),
          SizedBox(height: 2.h),
          _buildExportCard(
            'Export to JSON',
            'Download all responses in JSON format for programmatic access',
            Icons.code,
            Colors.blue,
            _exportToJSON,
          ),
          SizedBox(height: 2.h),
          _buildExportCard(
            'Export Analytics Report',
            'Generate comprehensive analytics report with charts and insights',
            Icons.analytics,
            Colors.purple,
            _exportAnalyticsReport,
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: _isExporting ? null : onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(icon, color: color, size: 8.w),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isExporting)
                SizedBox(
                  width: 5.w,
                  height: 5.w,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.download, color: color, size: 6.w),
            ],
          ),
        ),
      ),
    );
  }
}
