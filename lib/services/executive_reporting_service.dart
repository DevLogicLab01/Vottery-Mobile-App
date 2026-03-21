import './business_intelligence_service.dart';

class ExecutiveReportingService {
  static ExecutiveReportingService? _instance;
  static ExecutiveReportingService get instance =>
      _instance ??= ExecutiveReportingService._();

  ExecutiveReportingService._();

  final BusinessIntelligenceService _bi = BusinessIntelligenceService.instance;

  Future<List<Map<String, dynamic>>> getExecutiveReports({
    String reportType = 'all',
    String timeRange = '30d',
  }) async {
    // Mobile parity wrapper: returns generated report snapshots.
    final report = await _bi.generateExecutiveReport(reportType: reportType);
    return [report];
  }

  Future<List<Map<String, dynamic>>> getStakeholderGroups() {
    return _bi.getStakeholderGroups();
  }

  Future<Map<String, dynamic>> getDeliveryStatistics({
    String timeRange = '30d',
  }) {
    return _bi.getDeliveryStatistics(timeRange: timeRange);
  }
}
