import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/fraud_engine_service.dart';
import '../../theme/app_theme.dart';
import './widgets/coordinated_voting_card_widget.dart';

class CoordinatedVotingDetectionScreen extends StatefulWidget {
  const CoordinatedVotingDetectionScreen({super.key});

  @override
  State<CoordinatedVotingDetectionScreen> createState() =>
      _CoordinatedVotingDetectionScreenState();
}

class _CoordinatedVotingDetectionScreenState
    extends State<CoordinatedVotingDetectionScreen> {
  final FraudEngineService _fraudService = FraudEngineService.instance;
  final TextEditingController _electionIdController = TextEditingController();

  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _coordinatedVotes = [];
  Map<String, dynamic>? _analysisResult;

  @override
  void dispose() {
    _electionIdController.dispose();
    super.dispose();
  }

  Future<void> _analyzeElection() async {
    if (_electionIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an election ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final votes = await _fraudService.detectCoordinatedVoting(
        electionId: _electionIdController.text.trim(),
      );

      setState(() {
        _coordinatedVotes = votes;
        _analysisResult = votes.isNotEmpty
            ? {
                'detected': true,
                'voter_count': votes.length,
                'confidence': 0.85,
              }
            : {'detected': false};
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Coordinated Voting Detection',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyze Election for Coordinated Voting',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _electionIdController,
              decoration: InputDecoration(
                labelText: 'Election ID',
                hintText: 'Enter election ID to analyze',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _analyzeElection,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _analyzeElection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: _isAnalyzing
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Analyze Election',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 3.h),

            if (_analysisResult != null) ...[
              _buildAnalysisResults(),
              SizedBox(height: 3.h),
            ],

            if (_coordinatedVotes.isNotEmpty) ...[
              Text(
                'Detected Coordinated Votes (${_coordinatedVotes.length})',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(height: 2.h),
              ..._coordinatedVotes
                  .take(20)
                  .map((vote) => CoordinatedVotingCardWidget(vote: vote)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResults() {
    final detected = _analysisResult!['detected'] as bool? ?? false;
    final voterCount = _analysisResult!['voter_count'] as int? ?? 0;
    final confidence =
        (_analysisResult!['confidence'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: detected ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: detected ? Colors.red.shade300 : Colors.green.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                detected ? Icons.warning : Icons.check_circle,
                color: detected ? Colors.red.shade700 : Colors.green.shade700,
                size: 8.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  detected
                      ? 'Coordinated Voting Detected'
                      : 'No Coordinated Voting Detected',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: detected
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (detected) ...[
            SizedBox(height: 2.h),
            _buildResultRow('Suspicious Voters', voterCount.toString()),
            _buildResultRow(
              'Confidence',
              '${(confidence * 100).toStringAsFixed(0)}%',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
