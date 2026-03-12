import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/claude_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

/// Claude Tax Guidance Widget
/// AI-powered tax strategy recommendations, settlement optimization,
/// and multi-jurisdiction compliance guidance
class ClaudeTaxGuidanceWidget extends StatefulWidget {
  const ClaudeTaxGuidanceWidget({super.key});

  @override
  State<ClaudeTaxGuidanceWidget> createState() =>
      _ClaudeTaxGuidanceWidgetState();
}

class _ClaudeTaxGuidanceWidgetState extends State<ClaudeTaxGuidanceWidget> {
  final ClaudeService _claudeService = ClaudeService.instance;
  final AuthService _authService = AuthService.instance;

  bool _isLoading = false;
  String _selectedGuidanceType = 'tax_strategy';
  Map<String, dynamic> _guidanceResult = {};

  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];

  final Map<String, String> _guidanceTypes = {
    'tax_strategy': 'Tax Strategy Recommendations',
    'settlement_optimization': 'Settlement Optimization',
    'jurisdiction_guidance': 'Multi-Jurisdiction Guidance',
    'quarterly_planning': 'Quarterly Tax Planning',
    'compliance_risk': 'Compliance Risk Assessment',
    'structure_comparison': 'Entity Structure Comparison',
    'chatbot': 'Ask Claude (Tax Chatbot)',
  };

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGuidanceTypeSelector(),
          SizedBox(height: 3.h),
          if (_selectedGuidanceType == 'chatbot')
            _buildChatbotInterface()
          else
            _buildGuidanceInterface(),
        ],
      ),
    );
  }

  Widget _buildGuidanceTypeSelector() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.purple, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'Claude AI Tax Guidance',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _guidanceTypes.entries.map((entry) {
              final isSelected = _selectedGuidanceType == entry.key;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGuidanceType = entry.key;
                    _guidanceResult = {};
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryLight
                        : Colors.grey.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceInterface() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _getGuidance,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLight,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 5.w,
                  height: 5.w,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Get ${_guidanceTypes[_selectedGuidanceType]}',
                  style: TextStyle(fontSize: 13.sp),
                ),
        ),
        SizedBox(height: 3.h),
        if (_guidanceResult.isNotEmpty) _buildGuidanceResults(),
      ],
    );
  }

  Widget _buildGuidanceResults() {
    switch (_selectedGuidanceType) {
      case 'tax_strategy':
        return _buildTaxStrategyResults();
      case 'settlement_optimization':
        return _buildSettlementOptimizationResults();
      case 'jurisdiction_guidance':
        return _buildJurisdictionGuidanceResults();
      case 'quarterly_planning':
        return _buildQuarterlyPlanningResults();
      case 'compliance_risk':
        return _buildComplianceRiskResults();
      case 'structure_comparison':
        return _buildStructureComparisonResults();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildTaxStrategyResults() {
    final recommendations = _guidanceResult['recommendations'] as List? ?? [];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tax Strategy Recommendations',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          ...recommendations.map((rec) {
            final title = rec['title'] ?? '';
            final description = rec['description'] ?? '';
            final priority = rec['priority'] ?? 'medium';
            final estimatedSavings = rec['estimated_savings'] ?? 0;

            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: _getPriorityColor(priority).withAlpha(77),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (estimatedSavings > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              '\$${estimatedSavings.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettlementOptimizationResults() {
    final recommendedTiming = _guidanceResult['recommended_timing'] ?? '';
    final reasoning = _guidanceResult['reasoning'] ?? '';
    final estimatedSavings = _guidanceResult['estimated_tax_savings'] ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settlement Optimization',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildInfoRow('Recommended Timing', _formatTiming(recommendedTiming)),
          SizedBox(height: 1.h),
          _buildInfoRow(
            'Estimated Tax Savings',
            '\$${estimatedSavings.toStringAsFixed(2)}',
          ),
          SizedBox(height: 2.h),
          Text(
            'Reasoning:',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Text(
            reasoning,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJurisdictionGuidanceResults() {
    final jurisdictionGuidance =
        _guidanceResult['jurisdiction_guidance'] as List? ?? [];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multi-Jurisdiction Guidance',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          ...jurisdictionGuidance.map((guidance) {
            final country = guidance['country'] ?? '';
            final tips = List<String>.from(guidance['tips'] ?? []);

            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      country,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ...tips.map(
                      (tip) => Padding(
                        padding: EdgeInsets.only(bottom: 0.5.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(fontSize: 11.sp)),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(fontSize: 11.sp),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuarterlyPlanningResults() {
    final projectedLiability = _guidanceResult['projected_tax_liability'] ?? 0;
    final underpaymentRisk = _guidanceResult['underpayment_risk'] ?? 'unknown';
    final optimizationActions = List<String>.from(
      _guidanceResult['optimization_actions'] ?? [],
    );

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quarterly Tax Planning',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildInfoRow(
            'Projected Tax Liability',
            '\$${projectedLiability.toStringAsFixed(2)}',
          ),
          SizedBox(height: 1.h),
          _buildInfoRow('Underpayment Risk', underpaymentRisk.toUpperCase()),
          SizedBox(height: 2.h),
          Text(
            'Optimization Actions:',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          ...optimizationActions.map(
            (action) => Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(fontSize: 11.sp)),
                  Expanded(
                    child: Text(action, style: TextStyle(fontSize: 11.sp)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceRiskResults() {
    final riskScore = _guidanceResult['risk_score'] ?? 0;
    final riskLevel = _guidanceResult['risk_level'] ?? 'unknown';
    final vulnerabilities = List<String>.from(
      _guidanceResult['vulnerabilities'] ?? [],
    );
    final priorityActions = List<String>.from(
      _guidanceResult['priority_actions'] ?? [],
    );

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance Risk Assessment',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(child: _buildRiskScoreCard(riskScore, riskLevel)),
            ],
          ),
          SizedBox(height: 2.h),
          if (vulnerabilities.isNotEmpty) ...[
            Text(
              'Vulnerabilities:',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            ...vulnerabilities.map(
              (vuln) => Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 4.w),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(vuln, style: TextStyle(fontSize: 11.sp)),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],
          if (priorityActions.isNotEmpty) ...[
            Text(
              'Priority Actions:',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            ...priorityActions.map(
              (action) => Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(fontSize: 11.sp)),
                    Expanded(
                      child: Text(action, style: TextStyle(fontSize: 11.sp)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStructureComparisonResults() {
    final structureComparison =
        _guidanceResult['structure_comparison'] as List? ?? [];
    final recommendedStructure = _guidanceResult['recommended_structure'] ?? '';
    final projectedSavings = _guidanceResult['projected_savings'] ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entity Structure Comparison',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildInfoRow('Recommended Structure', recommendedStructure),
          _buildInfoRow(
            'Projected Savings',
            '\$${projectedSavings.toStringAsFixed(2)}',
          ),
          SizedBox(height: 2.h),
          ...structureComparison.map((structure) {
            final structureName = structure['structure'] ?? '';
            final estimatedTax = structure['estimated_tax'] ?? 0;
            final pros = List<String>.from(structure['pros'] ?? []);

            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          structureName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '\$${estimatedTax.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    ...pros
                        .take(3)
                        .map(
                          (pro) => Padding(
                            padding: EdgeInsets.only(bottom: 0.5.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 4.w,
                                ),
                                SizedBox(width: 1.w),
                                Expanded(
                                  child: Text(
                                    pro,
                                    style: TextStyle(fontSize: 11.sp),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChatbotInterface() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask Claude Tax Questions',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 40.h,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListView.builder(
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                final isUser = message['role'] == 'user';

                return Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        Icon(Icons.psychology, color: Colors.purple, size: 5.w),
                        SizedBox(width: 2.w),
                      ],
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppTheme.primaryLight.withAlpha(26)
                                : Colors.purple.withAlpha(26),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            message['content'] ?? '',
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        SizedBox(width: 2.w),
                        Icon(
                          Icons.person,
                          color: AppTheme.primaryLight,
                          size: 5.w,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Ask a tax question...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  maxLines: 2,
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: _isLoading ? null : _sendChatMessage,
                icon: _isLoading
                    ? SizedBox(
                        width: 5.w,
                        height: 5.w,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send, color: AppTheme.primaryLight, size: 6.w),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskScoreCard(int riskScore, String riskLevel) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _getRiskColor(riskLevel).withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            riskScore.toString(),
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: _getRiskColor(riskLevel),
            ),
          ),
          Text(
            riskLevel.toUpperCase(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: _getRiskColor(riskLevel),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTiming(String timing) {
    switch (timing) {
      case 'immediate':
        return 'Withdraw Immediately';
      case 'defer_to_next_month':
        return 'Defer to Next Month';
      case 'defer_to_next_year':
        return 'Defer to Next Year';
      default:
        return timing;
    }
  }

  Future<void> _getGuidance() async {
    setState(() => _isLoading = true);

    try {
      final creatorId = _authService.currentUser?.id ?? '';

      Map<String, dynamic> result = {};

      switch (_selectedGuidanceType) {
        case 'tax_strategy':
          result = await _claudeService.getTaxStrategyRecommendations(
            creatorId: creatorId,
            earningsData: {
              'total_revenue': 50000,
              'revenue_sources': 'Marketplace, Partnerships, Ads',
            },
            jurisdictions: ['US', 'UK', 'CA'],
          );
          break;
        case 'settlement_optimization':
          result = await _claudeService.analyzeSettlementOptimization(
            creatorId: creatorId,
            pendingAmount: 5000,
            earningsHistory: {'ytd_earnings': 45000, 'projected_annual': 60000},
            currentTaxBracket: '24%',
          );
          break;
        case 'jurisdiction_guidance':
          result = await _claudeService.getMultiJurisdictionGuidance(
            creatorId: creatorId,
            jurisdictionData: [
              {
                'country': 'US',
                'revenue': 30000,
                'compliance_status': 'active',
              },
              {
                'country': 'UK',
                'revenue': 15000,
                'compliance_status': 'active',
              },
            ],
          );
          break;
        case 'quarterly_planning':
          result = await _claudeService.getQuarterlyTaxPlanning(
            creatorId: creatorId,
            yearToDateEarnings: 45000,
            projectedEarnings: {
              'q4_projection': 15000,
              'annual_projection': 60000,
            },
          );
          break;
        case 'compliance_risk':
          result = await _claudeService.getComplianceRiskAssessment(
            creatorId: creatorId,
            taxSetup: {
              'entity_type': 'sole_proprietor',
              'jurisdictions': ['US', 'UK'],
            },
            recentTransactions: [],
          );
          break;
        case 'structure_comparison':
          result = await _claudeService.compareTaxStructures(
            creatorId: creatorId,
            annualRevenue: 60000,
            currentStructure: 'sole_proprietor',
          );
          break;
      }

      if (mounted) {
        setState(() {
          _guidanceResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Get guidance error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendChatMessage() async {
    final question = _chatController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'content': question});
      _isLoading = true;
    });

    _chatController.clear();

    try {
      final creatorId = _authService.currentUser?.id ?? '';
      final response = await _claudeService.processTaxQuestion(
        creatorId: creatorId,
        question: question,
        creatorContext: {
          'annual_revenue': 50000,
          'jurisdictions': ['US', 'UK'],
          'entity_type': 'sole_proprietor',
        },
      );

      if (mounted) {
        setState(() {
          _chatHistory.add({'role': 'assistant', 'content': response});
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Send chat message error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
