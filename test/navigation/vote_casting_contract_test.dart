import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/app_urls.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Vote casting - Web/Mobile contract', () {
    test('vote casting web URLs stay aligned', () {
      expect(
        AppUrls.voteInElectionsHub,
        endsWith('/vote-in-elections-hub'),
      );
      expect(
        AppUrls.electionsDashboard,
        endsWith('/elections-dashboard'),
      );
      expect(
        AppUrls.secureVotingInterface,
        endsWith('/secure-voting-interface'),
      );
      expect(
        AppUrls.votingCategories,
        endsWith('/voting-categories'),
      );
      expect(
        AppUrls.voteVerificationPortal,
        endsWith('/vote-verification-portal'),
      );
      expect(
        AppUrls.blockchainAuditPortal,
        endsWith('/blockchain-audit-portal'),
      );
    });

    test('route registry keeps vote casting canonical mappings', () {
      expect(
        screenForRoute(AppRoutes.voteInElectionsHubWebCanonical)
            .runtimeType
            .toString(),
        'VoteDashboard',
      );
      expect(
        screenForRoute(AppRoutes.electionsDashboardWebCanonical)
            .runtimeType
            .toString(),
        'VoteDashboard',
      );
      expect(
        screenForRoute(AppRoutes.secureVotingInterfaceWebCanonical)
            .runtimeType
            .toString(),
        'VoteCasting',
      );
      expect(
        screenForRoute(AppRoutes.votingCategoriesWebCanonical)
            .runtimeType
            .toString(),
        'VoteDiscovery',
      );
      expect(
        screenForRoute(AppRoutes.voteVerificationPortalWebCanonical)
            .runtimeType
            .toString(),
        'WebAdminLauncherScreen',
      );
      expect(
        screenForRoute(AppRoutes.blockchainAuditPortal)
            .runtimeType
            .toString(),
        'VerifyAuditElectionsHub',
      );
    });
  });
}
