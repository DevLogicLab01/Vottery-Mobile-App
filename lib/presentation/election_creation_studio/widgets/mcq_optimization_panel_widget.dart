import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as gf;

import '../../../models/mcq_optimization_suggestion.dart';
import '../../../services/mcq/mcq_claude_optimization_service.dart';
import '../../../theme/app_theme.dart';

/// MCQ Optimization Panel Widget - shows Claude AI suggestions for low-performing questions
class MCQOptimizationPanel extends StatefulWidget {
  final Map<String, dynamic> currentQuestion;
  final int questionIndex;
  final double accuracyRate;
  final VoidCallback onApplySuggestion;
  final Function(Map<String, dynamic>) onQuestionUpdated;
  final VoidCallback onDismiss;

  const MCQOptimizationPanel({
    super.key,
    required this.currentQuestion,
    required this.questionIndex,
    required this.accuracyRate,
    required this.onApplySuggestion,
    required this.onQuestionUpdated,
    required this.onDismiss,
  });

  @override
  State<MCQOptimizationPanel> createState() => _MCQOptimizationPanelState();
}

class _MCQOptimizationPanelState extends State<MCQOptimizationPanel>
    with SingleTickerProviderStateMixin {
  bool _loadingSuggestion = true;
  MCQOptimizationSuggestion? _suggestion;
  final String _selectedVariant = 'improved'; // 'original', 'improved', 'alternative'
  late AnimationController _checkAnimController;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnim = CurvedAnimation(
      parent: _checkAnimController,
      curve: Curves.elasticOut,
    );
    _loadSuggestions();
  }

  @override
  void dispose() {
    _checkAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _loadingSuggestion = true);
    try {
      final suggestion = await MCQClaudeOptimizationService.instance
          .generateOptimizationSuggestions(
            widget.currentQuestion,
            accuracyRate: widget.accuracyRate,
          );
      if (mounted) {
        setState(() {
          _suggestion = suggestion;
          _loadingSuggestion = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingSuggestion = false);
    }
  }

  void _applyOptimization() {
    if (_suggestion == null) return;

    final updatedQuestion = Map<String, dynamic>.from(widget.currentQuestion);
    updatedQuestion['question_text'] = _suggestion!.improvedQuestionText;

    // Convert improved options back to the format used by the widget
    final existingOptions = List<dynamic>.from(
      widget.currentQuestion['options'] ?? [],
    );
    final newOptions = _suggestion!.improvedOptions.asMap().entries.map((e) {
      if (e.key < existingOptions.length && existingOptions[e.key] is Map) {
        return {
          ...Map<String, dynamic>.from(existingOptions[e.key] as Map),
          'text': e.value,
        };
      }
      return e.value;
    }).toList();
    updatedQuestion['options'] = newOptions;

    widget.onQuestionUpdated(updatedQuestion);
    widget.onApplySuggestion();

    _checkAnimController.forward();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Optimization applied successfully'),
        backgroundColor: Colors.green.shade700,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            widget.onQuestionUpdated(
              Map<String, dynamic>.from(widget.currentQuestion),
            );
          },
        ),
      ),
    );

    // Save to history
    final mcqId = widget.currentQuestion['mcq_id'] as String?;
    if (mcqId != null) {
      MCQClaudeOptimizationService.instance.saveOptimizationHistory(
        mcqId: mcqId,
        suggestion: _suggestion!,
        optimizationType: 'wording_clarity',
      );
    }
  }

  void _showAlternativeDialog() {
    if (_suggestion == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Alternative Question',
          style: gf.GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _suggestion!.alternativeQuestionText,
                style: gf.GoogleFonts.inter(fontSize: 13.sp),
              ),
              SizedBox(height: 1.5.h),
              ..._suggestion!.alternativeOptions.asMap().entries.map(
                (e) => Padding(
                  padding: EdgeInsets.only(bottom: 0.5.h),
                  child: Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + e.key),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          e.value,
                          style: gf.GoogleFonts.inter(fontSize: 11.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Keep both - add alternative as note (no-op for now)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Alternative question noted for reference'),
                ),
              );
            },
            child: const Text('Keep Both'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (_suggestion == null) return;
              final updatedQuestion = Map<String, dynamic>.from(
                widget.currentQuestion,
              );
              updatedQuestion['question_text'] =
                  _suggestion!.alternativeQuestionText;
              final altOptions = _suggestion!.alternativeOptions
                  .map((o) => o)
                  .toList();
              updatedQuestion['options'] = altOptions;
              widget.onQuestionUpdated(updatedQuestion);
              widget.onApplySuggestion();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Alternative question applied'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Replace Original',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.orange.shade300, width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 1.5.h),
            if (_loadingSuggestion)
              _buildLoadingState()
            else if (_suggestion != null) ...[
              _buildComparisonSection(),
              SizedBox(height: 1.5.h),
              _buildProjectedImpact(),
              SizedBox(height: 1.5.h),
              _buildActionButtons(),
            ] else
              _buildErrorState(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.orange.shade700,
                size: 4.w,
              ),
              SizedBox(width: 1.w),
              Text(
                '⚠️ Needs Optimization',
                style: gf.GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 2.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Text(
            'Accuracy: ${(widget.accuracyRate * 100).toStringAsFixed(0)}%',
            style: gf.GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.refresh, size: 5.w, color: AppTheme.primaryLight),
          tooltip: 'Refresh suggestions',
          onPressed: _loadSuggestions,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        SizedBox(width: 2.w),
        GestureDetector(
          onTap: widget.onDismiss,
          child: Icon(Icons.close, size: 5.w, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 1.5.h),
          Text(
            'Claude AI is analyzing this question...',
            style: gf.GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        'Unable to generate suggestions. Check Claude API configuration.',
        style: gf.GoogleFonts.inter(
          fontSize: 11.sp,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildComparisonSection() {
    if (_suggestion == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildOriginalColumn()),
        SizedBox(width: 2.w),
        Expanded(child: _buildImprovedColumn()),
      ],
    );
  }

  Widget _buildOriginalColumn() {
    if (_suggestion == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Question',
            style: gf.GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: Colors.red.shade700,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            _suggestion!.originalQuestionText,
            style: gf.GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.grey.shade800,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.8.h),
          ..._suggestion!.originalOptions.asMap().entries.map(
            (e) => Padding(
              padding: EdgeInsets.only(bottom: 0.3.h),
              child: Text(
                '${String.fromCharCode(65 + e.key)}) ${e.value}',
                style: gf.GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(height: 0.8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              'Accuracy: ${(widget.accuracyRate * 100).toStringAsFixed(0)}%',
              style: gf.GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovedColumn() {
    if (_suggestion == null) return const SizedBox.shrink();
    final projectedAccuracy =
        widget.accuracyRate * 100 + _suggestion!.projectedAccuracyImprovement;
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.green.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Optimization',
            style: gf.GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            _suggestion!.improvedQuestionText,
            style: gf.GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.8.h),
          ..._suggestion!.improvedOptions.asMap().entries.map(
            (e) => Padding(
              padding: EdgeInsets.only(bottom: 0.3.h),
              child: Text(
                '${String.fromCharCode(65 + e.key)}) ${e.value}',
                style: gf.GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(height: 0.8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              'Projected: ${projectedAccuracy.clamp(0, 100).toStringAsFixed(0)}%',
              style: gf.GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectedImpact() {
    if (_suggestion == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+${_suggestion!.projectedAccuracyImprovement.toStringAsFixed(0)}% accuracy',
                  style: gf.GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Confidence: ${_suggestion!.confidenceScore.toStringAsFixed(0)}%',
                  style: gf.GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            flex: 2,
            child: Text(
              _suggestion!.reasoning.isNotEmpty
                  ? _suggestion!.reasoning
                  : 'Improved wording and clearer distractors will reduce ambiguity.',
              style: gf.GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.white.withAlpha(230),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _suggestion != null ? _applyOptimization : null,
            icon: ScaleTransition(
              scale: _checkAnim,
              child: const Icon(Icons.check, size: 18),
            ),
            label: Text(
              'Apply Suggestion',
              style: gf.GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              minimumSize: Size(0, 5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        SizedBox(width: 2.w),
        OutlinedButton.icon(
          onPressed: _suggestion != null ? _showAlternativeDialog : null,
          icon: const Icon(Icons.swap_horiz, size: 16),
          label: Text(
            'Try Alternative',
            style: gf.GoogleFonts.inter(fontSize: 9.sp),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, 5.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        SizedBox(width: 2.w),
        TextButton(
          onPressed: widget.onDismiss,
          child: Text(
            'Dismiss',
            style: gf.GoogleFonts.inter(
              fontSize: 9.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
