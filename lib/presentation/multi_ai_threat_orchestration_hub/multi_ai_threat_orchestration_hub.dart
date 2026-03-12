import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class MultiAiThreatOrchestrationHub extends StatefulWidget {
  const MultiAiThreatOrchestrationHub({super.key});

  @override
  State<MultiAiThreatOrchestrationHub> createState() =>
      _MultiAiThreatOrchestrationHubState();
}

class _MultiAiThreatOrchestrationHubState
    extends State<MultiAiThreatOrchestrationHub> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isAnalyzing = false;

  List<Map<String, dynamic>> _threats = [];
  int _activeThreats = 0;
  double _avgConsensusScore = 0.0;
  int _p0Threats = 0;

  @override
  void initState() {
    super.initState();
    _loadThreats();
  }

  Future<void> _loadThreats() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('multi_ai_threat_analysis')
          .select()
          .order('analyzed_at', ascending: false)
          .limit(50);

      _threats = List<Map<String, dynamic>>.from(response);

      _activeThreats = _threats
          .where(
            (t) => t['priority_level'] == 'P0' || t['priority_level'] == 'P1',
          )
          .length;

      if (_threats.isNotEmpty) {
        final totalScore = _threats.fold<double>(
          0.0,
          (sum, t) => sum + ((t['consensus_score'] as num?)?.toDouble() ?? 0.0),
        );
        _avgConsensusScore = totalScore / _threats.length;
      }

      _p0Threats = _threats.where((t) => t['priority_level'] == 'P0').length;

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading threats: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeNewThreat() async {
    setState(() => _isAnalyzing = true);

    try {
      final threatDescription =
          'Suspicious login attempts from multiple IPs targeting admin accounts';

      // Call all AI services in parallel
      final results = await Future.wait([
        _analyzeWithOpenAI(threatDescription),
        _analyzeWithAnthropic(threatDescription),
        _analyzeWithPerplexity(threatDescription),
        _analyzeWithGemini(threatDescription),
      ]);

      // Calculate consensus
      final scores = results.map((r) => r['severity'] as double).toList();
      final avgScore = scores.reduce((a, b) => a + b) / scores.length;
      final stdDev = _calculateStdDev(scores, avgScore);

      String agreementLevel;
      if (stdDev < 1.0) {
        agreementLevel = 'high';
      } else if (stdDev < 2.0) {
        agreementLevel = 'medium';
      } else {
        agreementLevel = 'low';
      }

      String priorityLevel;
      if (avgScore > 8.5) {
        priorityLevel = 'P0';
      } else if (avgScore >= 7.0) {
        priorityLevel = 'P1';
      } else if (avgScore >= 5.0) {
        priorityLevel = 'P2';
      } else {
        priorityLevel = 'P3';
      }

      // Store analysis
      await _supabase.from('multi_ai_threat_analysis').insert({
        'threat_description': threatDescription,
        'openai_analysis': results[0],
        'anthropic_analysis': results[1],
        'perplexity_analysis': results[2],
        'gemini_analysis': results[3],
        'consensus_score': avgScore,
        'agreement_level': agreementLevel,
        'priority_level': priorityLevel,
        'unified_summary':
            'Multi-AI consensus indicates $priorityLevel priority threat with $agreementLevel agreement',
        'analyzed_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Threat analysis completed'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadThreats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error analyzing threat: $e')));
      }
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<Map<String, dynamic>> _analyzeWithOpenAI(String threat) async {
    try {
      // Simulate OpenAI analysis
      await Future.delayed(const Duration(seconds: 1));
      return {
        'provider': 'openai',
        'severity': 7.5 + (DateTime.now().millisecondsSinceEpoch % 20) / 10,
        'attack_vector': 'Credential stuffing',
        'iocs': ['192.168.1.100', '192.168.1.101'],
        'recommendations': ['Enable MFA', 'Block suspicious IPs'],
        'confidence': 0.85,
      };
    } catch (e) {
      return {'provider': 'openai', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _analyzeWithAnthropic(String threat) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'provider': 'anthropic',
        'severity': 8.0 + (DateTime.now().millisecondsSinceEpoch % 15) / 10,
        'attack_vector': 'Brute force attack',
        'iocs': ['192.168.1.100', '10.0.0.50'],
        'recommendations': ['Implement rate limiting', 'Review access logs'],
        'confidence': 0.90,
      };
    } catch (e) {
      return {'provider': 'anthropic', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _analyzeWithPerplexity(String threat) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'provider': 'perplexity',
        'severity': 7.8 + (DateTime.now().millisecondsSinceEpoch % 18) / 10,
        'attack_vector': 'Account takeover attempt',
        'iocs': ['192.168.1.101', '172.16.0.10'],
        'recommendations': [
          'Monitor failed login attempts',
          'Alert security team',
        ],
        'confidence': 0.82,
      };
    } catch (e) {
      return {'provider': 'perplexity', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _analyzeWithGemini(String threat) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'provider': 'gemini',
        'severity': 7.2 + (DateTime.now().millisecondsSinceEpoch % 22) / 10,
        'attack_vector': 'Automated bot attack',
        'iocs': ['192.168.1.100'],
        'recommendations': ['Deploy CAPTCHA', 'Enhance bot detection'],
        'confidence': 0.78,
      };
    } catch (e) {
      return {'provider': 'gemini', 'error': e.toString()};
    }
  }

  double _calculateStdDev(List<double> values, double mean) {
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;
    return variance;
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'MultiAiThreatOrchestrationHub',
      onRetry: _loadThreats,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Multi-AI Threat Intelligence',
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _isAnalyzing ? null : _analyzeNewThreat,
              tooltip: 'Analyze New Threat',
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    SizedBox(height: 3.h),
                    _buildThreatsList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Active Threats',
            _activeThreats.toString(),
            Icons.warning,
            AppTheme.errorLight,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildOverviewCard(
            'Consensus Score',
            _avgConsensusScore.toStringAsFixed(1),
            Icons.analytics,
            AppTheme.primaryLight,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildOverviewCard(
            'P0 Threats',
            _p0Threats.toString(),
            Icons.priority_high,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatsList() {
    if (_threats.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.h),
          child: Column(
            children: [
              Icon(
                Icons.security,
                size: 20.w,
                color: AppTheme.textSecondaryLight,
              ),
              SizedBox(height: 2.h),
              Text(
                'No threats analyzed yet',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Threat Analysis',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _threats.length,
          itemBuilder: (context, index) => _buildThreatCard(_threats[index]),
        ),
      ],
    );
  }

  Widget _buildThreatCard(Map<String, dynamic> threat) {
    final priorityLevel = threat['priority_level'] as String? ?? 'P3';
    final consensusScore =
        (threat['consensus_score'] as num?)?.toDouble() ?? 0.0;
    final agreementLevel = threat['agreement_level'] as String? ?? 'low';
    final analyzedAt = threat['analyzed_at'] != null
        ? DateTime.parse(threat['analyzed_at'])
        : DateTime.now();

    Color priorityColor;
    switch (priorityLevel) {
      case 'P0':
        priorityColor = Colors.red;
        break;
      case 'P1':
        priorityColor = Colors.orange;
        break;
      case 'P2':
        priorityColor = Colors.yellow;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: priorityColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  priorityLevel,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  threat['threat_description'] ?? 'Unknown threat',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: 4.w,
                color: AppTheme.textSecondaryLight,
              ),
              SizedBox(width: 1.w),
              Text(
                'Consensus: ${consensusScore.toStringAsFixed(1)}/10',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              SizedBox(width: 3.w),
              Icon(
                Icons.check_circle,
                size: 4.w,
                color: AppTheme.textSecondaryLight,
              ),
              SizedBox(width: 1.w),
              Text(
                'Agreement: $agreementLevel',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              const Spacer(),
              Text(
                timeago.format(analyzedAt),
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            threat['unified_summary'] ?? 'No summary available',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1.w),
                  child: SkeletonCard(height: 15.h, width: double.infinity),
                ),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          ...List.generate(
            5,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: SkeletonCard(height: 15.h, width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}
