import './business_intelligence_service.dart';

class AutomatedExecutiveReportingService {
  static AutomatedExecutiveReportingService? _instance;
  static AutomatedExecutiveReportingService get instance =>
      _instance ??= AutomatedExecutiveReportingService._();

  AutomatedExecutiveReportingService._();

  final BusinessIntelligenceService _bi = BusinessIntelligenceService.instance;

  Future<Map<String, dynamic>> generateClaudeIntelligenceBrief({
    String reportType = 'executive_summary',
  }) async {
    final predictive = await _bi.getPredictiveInsights();
    final report = await _bi.generateExecutiveReport(reportType: reportType);
    return {
      'reportType': reportType,
      'generatedAt': DateTime.now().toIso8601String(),
      'predictiveInsights': predictive,
      'report': report,
    };
  }

  Future<Map<String, dynamic>> generateAndDeliverAutomatedReport({
    required String reportType,
    required String stakeholderGroupId,
  }) {
    return _bi.sendExecutiveReport(
      reportType: reportType,
      stakeholderGroupId: stakeholderGroupId,
    );
  }
}
