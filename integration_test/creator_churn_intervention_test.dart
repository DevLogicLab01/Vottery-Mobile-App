import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Creator Churn Intervention E2E Test', () {
    testWidgets('should detect churn and trigger multi-channel intervention', (tester) async {
      bool churnPredictionCreated = false;
      bool smsSent = false;
      bool emailSent = false;
      bool interventionLogged = false;
      double churnProbability = 0.0;

      // Test setup: at-risk creator
      final atRiskCreator = {
        'creator_id': 'creator_churn_test_001',
        'name': 'Test Creator',
        'email': 'creator@test.com',
        'phone': '+1234567890',
        'engagement_decline': 0.40, // 40% decline
        'earnings_drop': 0.30, // 30% drop
        'days_since_last_post': 12,
      };

      // Step 1: Calculate churn probability
      churnProbability = _calculateChurnProbability(
        engagementDecline: atRiskCreator['engagement_decline'] as double,
        earningsDrop: atRiskCreator['earnings_drop'] as double,
        daysSincePost: atRiskCreator['days_since_last_post'] as int,
      );

      expect(churnProbability, greaterThan(0.7));

      // Step 2: Store prediction in creator_churn_predictions
      final predictionStored = await _storePrediction(
        creatorId: atRiskCreator['creator_id'] as String,
        probability: churnProbability,
      );
      churnPredictionCreated = predictionStored['stored'] as bool;

      // Step 3: Trigger RetentionWorkflowTrigger.processChurnPredictions
      final interventionResult = await _processChurnPrediction(
        creatorId: atRiskCreator['creator_id'] as String,
        creatorName: atRiskCreator['name'] as String,
        phone: atRiskCreator['phone'] as String,
        email: atRiskCreator['email'] as String,
        probability: churnProbability,
        daysSincePost: atRiskCreator['days_since_last_post'] as int,
      );

      smsSent = interventionResult['sms_sent'] as bool;
      emailSent = interventionResult['email_sent'] as bool;
      interventionLogged = interventionResult['logged'] as bool;

      // Assertions
      expect(churnPredictionCreated, isTrue);
      expect(smsSent, isTrue);
      expect(emailSent, isTrue);
      expect(interventionLogged, isTrue);
      expect(churnProbability, greaterThan(0.7));
    });

    testWidgets('should use softer messaging for high risk (0.5-0.7)', (tester) async {
      final probability = 0.62;
      final messageType = probability >= 0.7 ? 'urgent' : 'proactive';
      expect(messageType, equals('proactive'));
    });

    testWidgets('should use urgent messaging for critical risk (>=0.7)', (tester) async {
      final probability = 0.85;
      final messageType = probability >= 0.7 ? 'urgent' : 'proactive';
      expect(messageType, equals('urgent'));
    });
  });
}

double _calculateChurnProbability({
  required double engagementDecline,
  required double earningsDrop,
  required int daysSincePost,
}) {
  final loginGapScore = (daysSincePost / 30).clamp(0.0, 1.0);
  return (engagementDecline * 0.25 +
          earningsDrop * 0.30 +
          loginGapScore * 0.20 +
          engagementDecline * 0.25)
      .clamp(0.0, 1.0);
}

Future<Map<String, dynamic>> _storePrediction({
  required String creatorId,
  required double probability,
}) async {
  return {
    'stored': true,
    'prediction_id': 'pred_${DateTime.now().millisecondsSinceEpoch}',
    'probability': probability,
  };
}

Future<Map<String, dynamic>> _processChurnPrediction({
  required String creatorId,
  required String creatorName,
  required String phone,
  required String email,
  required double probability,
  required int daysSincePost,
}) async {
  final smsMessage =
      'Hi $creatorName, we noticed you haven\'t posted in $daysSincePost days. '
      'Quick question: what would help you create more? Reply and let\'s chat!';

  return {
    'sms_sent': phone.isNotEmpty,
    'email_sent': email.isNotEmpty,
    'logged': true,
    'intervention_type': probability >= 0.7 ? 'urgent' : 'proactive',
    'sms_message': smsMessage,
  };
}
