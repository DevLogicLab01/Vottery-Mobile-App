import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/app_urls.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Achievement unlock - Web/Mobile contract', () {
    test('gamification/profile/notification URLs stay aligned', () {
      expect(AppUrls.userProfileHub, endsWith('/user-profile-hub'));
      expect(
        AppUrls.unifiedGamificationDashboard,
        endsWith('/unified-gamification-dashboard'),
      );
      expect(
        AppUrls.dynamicQuestManagementDashboard,
        endsWith('/dynamic-quest-management-dashboard'),
      );
      expect(
        AppUrls.vpEconomyHealthMonitorDashboard,
        endsWith('/vp-economy-health-monitor-dashboard'),
      );
      expect(AppUrls.creatorSuccessAcademy, endsWith('/creator-success-academy'));
      expect(AppUrls.notificationCenterHub, endsWith('/notification-center-hub'));
      expect(
        AppUrls.predictionPoolNotificationsHub,
        endsWith('/prediction-pool-notifications-hub'),
      );
      expect(
        AppUrls.comprehensiveGamificationAdminControlCenter,
        endsWith('/comprehensive-gamification-admin-control-center'),
      );
    });

    test('route registry keeps achievement flow canonical mappings', () {
      expect(
        screenForRoute(AppRoutes.userProfileWebCanonical).runtimeType.toString(),
        'UserProfile',
      );
      expect(
        screenForRoute(AppRoutes.unifiedGamificationDashboardWebCanonical)
            .runtimeType
            .toString(),
        'UnifiedGamificationDashboard',
      );
      expect(
        screenForRoute(AppRoutes.questManagementDashboardWebCanonical)
            .runtimeType
            .toString(),
        'QuestManagementDashboard',
      );
      expect(
        screenForRoute(AppRoutes.vpEconomyHealthMonitorWebCanonical)
            .runtimeType
            .toString(),
        'VpEconomyHealthMonitor',
      );
      expect(
        screenForRoute(AppRoutes.creatorSuccessAcademyWebCanonical)
            .runtimeType
            .toString(),
        'CreatorSuccessAcademy',
      );
      expect(
        screenForRoute(AppRoutes.notificationCenterHubWebCanonical)
            .runtimeType
            .toString(),
        'NotificationCenterHub',
      );
      expect(
        screenForRoute(AppRoutes.predictionPoolNotificationsHubWebCanonical)
            .runtimeType
            .toString(),
        'PredictionPoolNotificationsHub',
      );
      expect(
        screenForRoute(AppRoutes.comprehensiveGamificationAdminControlCenterWebCanonical)
            .runtimeType
            .toString(),
        'WebAdminLauncherScreen',
      );
    });
  });
}
