import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/advertiser_registration_service.dart';

class ComplianceScreeningStepWidget extends StatefulWidget {
  final Map<String, dynamic>? registration;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const ComplianceScreeningStepWidget({
    super.key,
    this.registration,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ComplianceScreeningStepWidget> createState() =>
      _ComplianceScreeningStepWidgetState();
}

class _ComplianceScreeningStepWidgetState
    extends State<ComplianceScreeningStepWidget> {
  bool _isScreening = false;
  List<Map<String, dynamic>> _screenings = [];

  @override
  void initState() {
    super.initState();
    if (widget.registration != null) {
      _loadScreenings();
    }
  }

  Future<void> _loadScreenings() async {
    final screenings = await AdvertiserRegistrationService.instance
        .getComplianceScreenings(widget.registration!['id']);
    if (mounted) {
      setState(() => _screenings = screenings);
    }
  }

  Future<void> _runScreening() async {
    setState(() => _isScreening = true);

    try {
      if (widget.registration != null) {
        await AdvertiserRegistrationService.instance.runComplianceScreening(
          registrationId: widget.registration!['id'],
          screeningType: 'aml_kyc',
        );
        await _loadScreenings();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Screening error: $e')));
    } finally {
      setState(() => _isScreening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPassedScreening = _screenings.any(
      (s) => s['risk_level'] == 'low' && s['sanctions_match'] == false,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compliance Screening', style: theme.textTheme.titleMedium),
          SizedBox(height: 2.h),
          Text(
            'AML/KYC verification and risk assessment',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Icon(
                    _isScreening
                        ? Icons.hourglass_empty
                        : hasPassedScreening
                        ? Icons.check_circle
                        : Icons.security,
                    size: 48.sp,
                    color: _isScreening
                        ? Colors.orange
                        : hasPassedScreening
                        ? Colors.green
                        : Colors.blue,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _isScreening
                        ? 'Running Compliance Screening...'
                        : hasPassedScreening
                        ? 'Screening Passed'
                        : 'Ready for Screening',
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    _isScreening
                        ? 'This may take a few moments'
                        : hasPassedScreening
                        ? 'All compliance checks passed successfully'
                        : 'Click below to start AML/KYC verification',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  if (!hasPassedScreening && !_isScreening) ...[
                    SizedBox(height: 3.h),
                    ElevatedButton.icon(
                      onPressed: _runScreening,
                      icon: Icon(Icons.play_arrow),
                      label: Text('Run Screening'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_screenings.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text('Screening Results', style: theme.textTheme.titleSmall),
            SizedBox(height: 1.h),
            ..._screenings.map(
              (screening) => Card(
                child: ListTile(
                  leading: Icon(
                    screening['risk_level'] == 'low'
                        ? Icons.check_circle
                        : Icons.warning,
                    color: screening['risk_level'] == 'low'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  title: Text(
                    'Risk Level: ${screening['risk_level'] ?? 'N/A'}',
                  ),
                  subtitle: Text(
                    'Score: ${screening['risk_score'] ?? 0} | Sanctions: ${screening['sanctions_match'] ? 'Match' : 'Clear'}',
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: Text('Back'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: hasPassedScreening
                      ? () => widget.onNext({})
                      : null,
                  child: Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
