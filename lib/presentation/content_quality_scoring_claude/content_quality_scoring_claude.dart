import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/content_quality_scoring_service.dart';
import '../../widgets/custom_app_bar.dart';

class ContentQualityScoringClaude extends StatefulWidget {
  const ContentQualityScoringClaude({super.key});

  @override
  State<ContentQualityScoringClaude> createState() =>
      _ContentQualityScoringClaudeState();
}

class _ContentQualityScoringClaudeState
    extends State<ContentQualityScoringClaude> {
  final TextEditingController _contentController = TextEditingController();
  String _contentType = 'election';
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _score() async {
    if (_contentController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter content before running Claude scoring.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ContentQualityScoringService.instance.scoreContent(
        content: _contentController.text.trim(),
        contentType: _contentType,
      );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to score content right now.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'Content Quality Scoring (Claude)',
        leading: Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _contentType,
            decoration: const InputDecoration(
              labelText: 'Content Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'election', child: Text('Election')),
              DropdownMenuItem(value: 'moment', child: Text('Moment')),
              DropdownMenuItem(value: 'mcq', child: Text('MCQ')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _contentType = value);
            },
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _contentController,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Content',
              hintText: 'Paste or write content to evaluate...',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: _loading ? null : _score,
            child: Text(_loading ? 'Scoring...' : 'Run Claude Scoring'),
          ),
          if (_error != null) ...[
            SizedBox(height: 1.5.h),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_result != null) ...[
            SizedBox(height: 2.h),
            _ScoreRow(
              label: 'Clarity',
              value: (_result!['clarity_score'] as num?)?.toDouble() ?? 0,
            ),
            _ScoreRow(
              label: 'Neutrality',
              value: (_result!['neutrality_score'] as num?)?.toDouble() ?? 0,
            ),
            _ScoreRow(
              label: 'Engagement Prediction',
              value: (_result!['engagement_prediction'] as num?)?.toDouble() ?? 0,
            ),
            SizedBox(height: 2.h),
            Text(
              'Improvement Suggestions',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            ...List<String>.from(_result!['suggestions'] ?? const [])
                .map((s) => Text('- $s')),
            SizedBox(height: 2.h),
            Text(
              'Rewritten Version',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text((_result!['rewritten_version'] ?? '').toString()),
          ],
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double value;

  const _ScoreRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${value.toStringAsFixed(1)}/100'),
          ],
        ),
      ),
    );
  }
}
