import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/app_urls.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Claude recommendations - Web/Mobile contract', () {
    test('Claude web URLs stay aligned', () {
      expect(
        AppUrls.claudeAiFeedIntelligenceCenter,
        endsWith('/claude-ai-feed-intelligence-center'),
      );
      expect(
        AppUrls.contextAwareClaudeRecommendationsOverlay,
        endsWith('/context-aware-claude-recommendations-overlay'),
      );
      expect(
        AppUrls.claudeAiContentCurationIntelligenceCenter,
        endsWith('/claude-ai-content-curation-intelligence-center'),
      );
      expect(
        AppUrls.claudeModelComparisonCenter,
        endsWith('/claude-model-comparison-center'),
      );
      expect(
        AppUrls.claudeContentOptimizationEngine,
        endsWith('/claude-content-optimization-engine'),
      );
      expect(
        AppUrls.claudeDecisionReasoningHub,
        endsWith('/claude-decision-reasoning-hub'),
      );
    });

    test('route registry keeps canonical Claude mappings', () {
      expect(
        screenForRoute(AppRoutes.claudeAiFeedIntelligenceCenterWebCanonical)
            .runtimeType
            .toString(),
        'AiPoweredPredictiveAnalyticsEngine',
      );
      expect(
        screenForRoute(
          AppRoutes.contextAwareClaudeRecommendationsOverlayWebCanonical,
        ).runtimeType.toString(),
        'ClaudeContextualInsightsOverlaySystem',
      );
      expect(
        screenForRoute(
          AppRoutes.claudeAiContentCurationIntelligenceCenterWebCanonical,
        ).runtimeType.toString(),
        'AnthropicContentIntelligenceHub',
      );
      expect(
        screenForRoute(AppRoutes.claudeModelComparisonCenterWebCanonical)
            .runtimeType
            .toString(),
        'ClaudeModelComparisonCenter',
      );
      expect(
        screenForRoute(AppRoutes.claudeContentOptimizationEngineWebCanonical)
            .runtimeType
            .toString(),
        'ContentQualityScoringClaude',
      );
      expect(
        screenForRoute(AppRoutes.claudeDecisionReasoningHub)
            .runtimeType
            .toString(),
        'ClaudeDecisionReasoningHubScreen',
      );
    });
  });
}
