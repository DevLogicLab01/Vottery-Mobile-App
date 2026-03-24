import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sizer/sizer.dart';

import '../constants/roles.dart';
import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import '../widgets/error_boundary_widget.dart';
import '../widgets/role_route_guard.dart';
import './constants/app_urls.dart';
import './presentation/admin_automation_control_panel/admin_automation_control_panel_screen.dart';
import './presentation/web_admin_launcher_screen/web_admin_launcher_screen.dart';
import './presentation/automated_datadog_response_command_center/automated_datadog_response_command_center.dart';
import './presentation/claude_decision_reasoning_hub/claude_decision_reasoning_hub_screen.dart';
import './presentation/claude_revenue_optimization_coach/claude_revenue_optimization_coach.dart';
import './presentation/cost_analytics_roi_dashboard/cost_analytics_roi_dashboard_screen.dart';
import './presentation/flutter_mobile_implementation_framework_hub/flutter_mobile_implementation_framework_hub.dart';
import './presentation/incident_response_analytics/incident_response_analytics_screen.dart';
import './presentation/multi_region_failover_dashboard/multi_region_failover_dashboard.dart';
import './presentation/performance_optimization_recommendations_engine_dashboard/performance_optimization_recommendations_engine_dashboard.dart';
import './presentation/predictive_performance_tuning_intelligence_dashboard/predictive_performance_tuning_intelligence_dashboard.dart';
import './presentation/realtime_gamification_error_recovery_hub/realtime_gamification_error_recovery_hub.dart';
import './presentation/subscription_architecture_screen/subscription_architecture_screen.dart';
import './presentation/unified_production_monitoring_hub/unified_production_monitoring_hub.dart';
import './presentation/ai_guided_interactive_tutorial/ai_guided_interactive_tutorial_screen.dart';
import './presentation/community_engagement_dashboard/community_engagement_dashboard_screen.dart';
import './presentation/voter_education_hub/voter_education_hub.dart';
import './presentation/real_time_revenue_optimization/real_time_revenue_optimization_screen.dart';
import './presentation/analytics_export_reporting_hub/analytics_export_reporting_hub_screen.dart';
import './presentation/performance_testing_dashboard/performance_testing_dashboard_screen.dart';
import './presentation/creator_revenue_share_screen/creator_revenue_share_screen.dart';
import './presentation/security_compliance_audit_screen/security_compliance_audit_screen.dart';
import './presentation/security_audit_dashboard/security_audit_dashboard.dart';
import './presentation/creator_community_hub/creator_community_hub.dart';
import './presentation/creator_onboarding_wizard/creator_onboarding_wizard_screen.dart';
import './presentation/user_feedback_portal/user_feedback_portal.dart';
import './presentation/feature_implementation_tracking/feature_implementation_tracking_screen.dart';
import './presentation/api_documentation_portal/api_documentation_portal.dart';
import './presentation/api_rate_limiting_dashboard/api_rate_limiting_dashboard_screen.dart';
import './presentation/offline_sync_diagnostics/offline_sync_diagnostics.dart';
import './presentation/community_elections_hub/community_elections_hub.dart';
import './presentation/content_removed_appeal/content_removed_appeal_screen.dart';
import './presentation/content_distribution_control_center/content_distribution_control_center_screen.dart';
import './presentation/content_moderation_control_center/content_moderation_control_center_screen.dart';
import './presentation/participation_fee_controls/participation_fee_controls_screen.dart';
import './presentation/bulk_management_screen/bulk_management_screen.dart';
import './presentation/ga4_enhanced_analytics_dashboard/ga4_enhanced_analytics_dashboard.dart';
import './presentation/real_time_analytics_dashboard/real_time_analytics_dashboard_screen.dart';
import './presentation/live_platform_monitoring_dashboard/live_platform_monitoring_dashboard_screen.dart';
import './presentation/personal_analytics_dashboard/personal_analytics_dashboard_screen.dart';
import './presentation/social_connections_manager/social_connections_manager.dart';
import './presentation/social_activity_timeline/social_activity_timeline_screen.dart';
import './presentation/advanced_unified_search_screen/advanced_unified_search_screen.dart';
import './config/route_feature_keys.dart';
import './config/route_registry.dart';
import './config/batch1_route_allowlist.dart';
import './routes/route_catalog.dart';
import './presentation/route_placeholder_screen/route_placeholder_screen.dart';
import './widgets/feature_gate_widget.dart';
import './services/accessibility_preferences_service.dart';
import './services/ai_cache_service.dart';
import './services/ai_notification_service.dart';
import './services/ai_voice_service.dart';
import './services/datadog_tracing_service.dart';
import './observers/datadog_rum_navigation_observer.dart';
import './services/enhanced_analytics_service.dart';
import './services/ga4_analytics_service.dart';
import './services/hive_offline_service.dart';
import './services/logging/log_notification_service.dart';
import './services/logging/platform_logging_service.dart';
import './services/offline_sync_service.dart';
import './services/payment_service.dart';
import './services/realtime_gamification_notification_service.dart';
import './services/sentry_service.dart';
import './services/creator_churn_prediction_service.dart';
import './services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Sentry
  await SentryService.initialize();

  // Global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    SentryService().captureException(
      details.exception,
      details.stack,
      context: 'FlutterError',
      level: SentryLevel.error,
    );
  };

  // Async error handler
  PlatformDispatcher.instance.onError = (error, stack) {
    SentryService().captureException(
      error,
      stack,
      context: 'PlatformDispatcher',
      level: SentryLevel.fatal,
    );
    return true;
  };

  // Custom error widget
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return FallbackErrorScreen(
      error: details.exception,
      onRetry: () {
        // Trigger app restart or navigation
      },
    );
  };

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    SupabaseService.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session == null) return;
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.initialSession) {
        unawaited(
          CreatorChurnPredictionService.instance.invokeUserChurnRefreshIfDue(),
        );
        unawaited(
          CreatorChurnPredictionService.instance.invokeRecordLoginGeoIfDue(),
        );
      }
    });
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Initialize Real-time Gamification Notifications
  try {
    await RealtimeGamificationNotificationService.instance.initialize();
    debugPrint('Realtime gamification notifications initialized');
  } catch (e) {
    debugPrint('Failed to initialize realtime gamification notifications: $e');
  }

  // Initialize Datadog APM
  try {
    await DatadogTracingService.instance.initializeDatadog();
  } catch (e) {
    debugPrint('Failed to initialize Datadog: $e');
  }

  // Remove Firebase initialization
  // try {
  //   await Firebase.initializeApp();
  // } catch (e) {
  //   debugPrint('Failed to initialize Firebase: $e');
  // }

  // Initialize AI services
  await AINotificationService.initialize();
  await AICacheService.initialize();
  await AIVoiceService.initialize();

  // Track app session start (skip Firebase Analytics on web to avoid JS interop errors)
  if (!kIsWeb) {
    await EnhancedAnalyticsService.instance.trackSessionStart();
  }

  // Initialize Stripe
  try {
    await PaymentService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Stripe: $e');
  }

  // Initialize GA4 Analytics
  try {
    await GA4AnalyticsService.instance.initialize();
    await GA4AnalyticsService.instance.startSession();
  } catch (e) {
    debugPrint('Failed to initialize GA4 Analytics: $e');
  }

  // Initialize Offline Sync Service
  try {
    await OfflineSyncService.instance.initialize();
    debugPrint('Offline sync service initialized');
  } catch (e) {
    debugPrint('Failed to initialize offline sync: $e');
  }

  // Initialize Hive Offline Service
  try {
    await HiveOfflineService.instance.initialize();
    debugPrint('Hive offline service initialized');
  } catch (e) {
    debugPrint('Failed to initialize Hive offline service: $e');
  }

  // Initialize Accessibility Preferences Service
  try {
    await AccessibilityPreferencesService.instance.initialize();
    debugPrint('Accessibility preferences service initialized');
  } catch (e) {
    debugPrint('Failed to initialize accessibility preferences: $e');
  }

  // ✅ Initialize logging services
  try {
    await LogNotificationService.initialize();
    debugPrint('Log notification service initialized');
  } catch (e) {
    debugPrint('Failed to initialize log notifications: $e');
  }

  // ✅ Sync any offline logs on startup
  try {
    await PlatformLoggingService.syncOfflineLogs();
    debugPrint('Offline logs synced');
  } catch (e) {
    debugPrint('Failed to sync offline logs: $e');
  }

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(const Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  runApp(SentryWidget(child: const ProviderScope(child: MyApp())));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _VotteryAppState();
}

class _VotteryAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _fontScale = AccessibilityPreferencesService.instance.fontScaleFactor;
    AccessibilityPreferencesService.instance.fontScaleNotifier.addListener(_onFontScaleChanged);
  }

  @override
  void dispose() {
    AccessibilityPreferencesService.instance.fontScaleNotifier.removeListener(_onFontScaleChanged);
    super.dispose();
  }

  void _onFontScaleChanged() {
    setState(() => _fontScale = AccessibilityPreferencesService.instance.fontScaleFactor);
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return ErrorBoundaryWidget(
          child: MaterialApp(
            title: 'vottery',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeMode,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(_fontScale),
                ),
                child: child!,
              );
            },
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (deviceLocale == null) return supportedLocales.first;
              for (final locale in supportedLocales) {
                if (locale.languageCode == deviceLocale.languageCode &&
                    (locale.countryCode == null ||
                        locale.countryCode == deviceLocale.countryCode)) {
                  return locale;
                }
              }
              return supportedLocales.first;
            },
            // NOTE: The canonical locale list now lives in the shared
            // Supabase table `supported_locales`. The hard-coded list
            // is kept as a safe fallback; AppI18nService can override
            // supportedLocales at runtime by reading from Supabase.
            supportedLocales: const [
              Locale('af'),
              Locale('gn'),
              Locale('ay'),
              Locale('az'),
              Locale('id'),
              Locale('ms'),
              Locale('jv'),
              Locale('bs'),
              Locale('ca'),
              Locale('cs'),
              Locale('chr'),
              Locale('cy'),
              Locale('da'),
              Locale('se'),
              Locale('de'),
              Locale('et'),
              Locale('en', 'IN'),
              Locale('en', 'GB'),
              Locale('en', 'US'),
              Locale('es'),
              Locale('es', 'CL'),
              Locale('es', 'CO'),
              Locale('es', 'ES'),
              Locale('es', 'MX'),
              Locale('es', 'VE'),
              Locale('eo'),
              Locale('eu'),
              Locale('fil'),
              Locale('fo'),
              Locale('fr', 'FR'),
              Locale('fr', 'CA'),
              Locale('fy'),
              Locale('ga'),
              Locale('gl'),
              Locale('ko'),
              Locale('hr'),
              Locale('xh'),
              Locale('zu'),
              Locale('is'),
              Locale('it'),
              Locale('ka'),
              Locale('sw'),
              Locale('tlh'),
              Locale('ku'),
              Locale('lv'),
              Locale('lt'),
              Locale('li'),
              Locale('la'),
              Locale('hu'),
              Locale('mg'),
              Locale('mt'),
              Locale('nl'),
              Locale('nl', 'BE'),
              Locale('ja'),
              Locale('nb'),
              Locale('nn'),
              Locale('uz'),
              Locale('pl'),
              Locale('pt', 'BR'),
              Locale('pt', 'PT'),
              Locale('qu'),
              Locale('ro'),
              Locale('rm'),
              Locale('ru'),
              Locale('sq'),
              Locale('sk'),
              Locale('sl'),
              Locale('so'),
              Locale('fi'),
              Locale('sv'),
              Locale('th'),
              Locale('vi'),
              Locale('tr'),
              Locale('zh', 'CN'),
              Locale('zh', 'TW'),
              Locale('zh', 'HK'),
              Locale('el'),
              Locale('grc'),
              Locale('be'),
              Locale('bg'),
              Locale('kk'),
              Locale('mk'),
              Locale('mn'),
              Locale('sr'),
              Locale('tt'),
              Locale('tg'),
              Locale('uk'),
              Locale('hy'),
              Locale('yi'),
              Locale('he'),
              Locale('ur'),
              Locale('ar'),
              Locale('ps'),
              Locale('fa'),
              Locale('syr'),
              Locale('ne'),
              Locale('mr'),
              Locale('sa'),
              Locale('hi'),
              Locale('bn'),
              Locale('pa'),
              Locale('gu'),
              Locale('ta'),
              Locale('te'),
              Locale('kn'),
              Locale('ml'),
              Locale('km'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            navigatorObservers: [DatadogRumNavigationObserver()],
            debugShowCheckedModeBanner: false,
            initialRoute: AppRoutes.initial,
            onGenerateRoute: (settings) {
              if (!Batch1RouteAllowlist.isAllowed(settings.name)) {
                return MaterialPageRoute(
                  builder: (_) => RoutePlaceholderScreen(
                    routeName: settings.name ?? '',
                    title: 'Disabled for Batch 1',
                  ),
                  settings: settings,
                );
              }
              final featureKey = RouteCatalog.lookup(settings.name ?? '')?.featureKey ??
                  RouteFeatureKeys.getFeatureKeyForRoute(settings.name ?? '');

              Widget gate(Widget child) {
                if (featureKey == null) return child;
                return FeatureGateWidget(featureKey: featureKey, child: child);
              }

              switch (settings.name) {
                case AppRoutes.unifiedProductionMonitoringHub:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const UnifiedProductionMonitoringHub(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes
                    .performanceOptimizationRecommendationsEngineDashboard:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child:
                            const PerformanceOptimizationRecommendationsEngineDashboard(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.flutterMobileImplementationFrameworkHub:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const FlutterMobileImplementationFrameworkHub(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.incidentResponseAnalytics:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const IncidentResponseAnalyticsScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.subscriptionArchitecture:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const SubscriptionArchitectureScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.realtimeGamificationErrorRecoveryHub:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const RealtimeGamificationErrorRecoveryHub(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.automatedDatadogResponseCommandCenter:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const AutomatedDatadogResponseCommandCenter(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.predictivePerformanceTuningDashboard:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child:
                            const PredictivePerformanceTuningIntelligenceDashboard(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.costAnalyticsRoiDashboard:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const CostAnalyticsRoiDashboardScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.claudeDecisionReasoningHub:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const ClaudeDecisionReasoningHubScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.claudeRevenueOptimizationCoach:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const ClaudeRevenueOptimizationCoachScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.adminAutomationControlPanel:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const AdminAutomationControlPanelScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.countryRestrictionsAdmin:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Country restrictions',
                          url: AppUrls.countryRestrictionsAdmin,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.platformIntegrationsAdmin:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Platform integrations',
                          url: AppUrls.platformIntegrationsAdmin,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.countryRevenueShareAdmin:
                case AppRoutes.countryRevenueShareManagementCenterWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Country revenue share',
                          url: AppUrls.countryRevenueShareManagement,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.regionalRevenueAnalyticsAdmin:
                case AppRoutes.regionalRevenueAnalyticsDashboardWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Regional revenue analytics',
                          url: AppUrls.regionalRevenueAnalytics,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.claudeDisputeResolutionAdmin:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Dispute resolution',
                          url: AppUrls.claudeDisputeResolution,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.multiCurrencySettlementAdmin:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Multi-currency settlement',
                          url: AppUrls.multiCurrencySettlement,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.adminSubscriptionAnalyticsAdmin:
                case AppRoutes.adminSubscriptionAnalyticsHubWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Admin subscription analytics',
                          url: AppUrls.adminSubscriptionAnalyticsHub,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.stripeSubscriptionManagementAdmin:
                case AppRoutes.stripeSubscriptionManagementCenterWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Stripe subscription management',
                          url: AppUrls.stripeSubscriptionManagementCenter,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.stripePaymentIntegrationHubAdmin:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Stripe payment integration',
                          url: AppUrls.stripePaymentIntegrationHub,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.automatedPayoutCalculationEngineAdmin:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Automated payout calculation engine',
                          url: AppUrls.automatedPayoutCalculationEngine,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.countryBasedPayoutProcessingEngineAdmin:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Country-based payout processing engine',
                          url: AppUrls.countryBasedPayoutProcessingEngine,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.comprehensiveGamificationAdminWeb:
                case AppRoutes.comprehensiveGamificationAdminControlCenterWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Gamification admin control center',
                          url: AppUrls.comprehensiveGamificationAdminControlCenter,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.platformGamificationCoreEngineAdmin:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Platform gamification core engine',
                          url: AppUrls.platformGamificationCoreEngine,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.gamificationCampaignManagementAdmin:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Gamification campaign management',
                          url: AppUrls.gamificationCampaignManagementCenter,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.gamificationRewardsManagementAdmin:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Gamification rewards management',
                          url: AppUrls.gamificationRewardsManagementCenter,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.securityComplianceAutomationAdmin:
                case AppRoutes.securityComplianceAutomationCenterWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Security compliance automation',
                          url: AppUrls.securityComplianceAutomationCenter,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.localizationTaxReportingAdmin:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Localization & tax reporting',
                          url: AppUrls.localizationTaxReportingIntelligenceCenter,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.complianceDashboardWeb:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Compliance dashboard',
                          url: AppUrls.complianceDashboard,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.complianceAuditDashboardWeb:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Compliance audit dashboard',
                          url: AppUrls.complianceAuditDashboard,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.regulatoryComplianceAutomationWeb:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Regulatory compliance automation',
                          url: AppUrls.regulatoryComplianceAutomationHub,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.claudeAiDisputeModerationAdmin:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Claude dispute moderation',
                          url: AppUrls.claudeAiDisputeModerationCenter,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.publicBulletinBoardWeb:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const WebAdminLauncherScreen(
                        title: 'Public bulletin & audit trail',
                        url: AppUrls.publicBulletinBoardAuditTrailCenter,
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.voteVerificationPortalWeb:
                case AppRoutes.voteVerificationPortalWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const WebAdminLauncherScreen(
                        title: 'Vote verification portal',
                        url: AppUrls.voteVerificationPortal,
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.adminQuestConfigurationControlCenterWeb:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const WebAdminLauncherScreen(
                          title: 'Admin quest configuration control center',
                          url: AppUrls.adminQuestConfigurationControlCenter,
                        ),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.multiRegionFailoverDashboard:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const MultiRegionFailoverDashboard(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.securityComplianceAudit:
                case AppRoutes.securityComplianceAuditWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const SecurityComplianceAuditScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.securityAuditDashboard:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const SecurityAuditDashboard(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.creatorCommunityHub:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.creatorRoles,
                        child: const CreatorCommunityHub(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.creatorOnboardingWizard:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.creatorRoles,
                        child: const CreatorOnboardingWizardScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.aiGuidedInteractiveTutorial:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const AiGuidedInteractiveTutorialScreen(),
                    ),
                    settings: settings,
                  );
                case AppRoutes.creatorRevenueShareScreen:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const CreatorRevenueShareScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.communityEngagementDashboard:
                case AppRoutes.communityEngagementDashboardWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.creatorRoles,
                        child: const CommunityEngagementDashboardScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.voterEducationHub:
                case AppRoutes.voterEducationHubWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const VoterEducationHub(),
                    ),
                    settings: settings,
                  );
                case AppRoutes.userFeedbackPortal:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const UserFeedbackPortal(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.featureImplementationTracking:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const FeatureImplementationTrackingScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.realTimeRevenueOptimization:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const RealTimeRevenueOptimizationScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.analyticsExportReportingHub:
                case AppRoutes.analyticsExportReportingHubWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const AnalyticsExportReportingHubScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.performanceTestingDashboard:
                case AppRoutes.performanceTestingDashboardWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const PerformanceTestingDashboardScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.apiDocumentationPortal:
                case AppRoutes.apiDocumentationPortalWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const ApiDocumentationPortalScreen(),
                    ),
                    settings: settings,
                  );
                case AppRoutes.apiRateLimitingDashboard:
                case AppRoutes.apiRateLimitingDashboardWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const ApiRateLimitingDashboardScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.offlineSyncDiagnostics:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const OfflineSyncDiagnostics(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.communityElectionsHub:
                case AppRoutes.communityElectionsHubWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const CommunityElectionsHubScreen(),
                    ),
                    settings: settings,
                  );
                case AppRoutes.ga4EnhancedAnalyticsDashboard:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const Ga4EnhancedAnalyticsDashboard(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.realTimeAnalyticsDashboard:
                case AppRoutes.realTimeAnalyticsDashboardWeb:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.creatorRoles,
                        child: const RealTimeAnalyticsDashboardScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.livePlatformMonitoringDashboard:
                case AppRoutes.livePlatformMonitoringDashboardWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const LivePlatformMonitoringDashboardScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.personalAnalyticsDashboard:
                case AppRoutes.personalAnalyticsDashboardWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const PersonalAnalyticsDashboardScreen(),
                    ),
                    settings: settings,
                  );
                case AppRoutes.socialActivityTimeline:
                case AppRoutes.socialActivityTimelineWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const SocialActivityTimelineScreen(),
                    ),
                    settings: settings,
                  );
                case AppRoutes.friendsManagementHub:
                case AppRoutes.friendsManagementHubWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const SocialConnectionsManager(),
                    ),
                    settings: settings,
                  );
                case AppRoutes.advancedUnifiedSearchScreen:
                case AppRoutes.advancedUnifiedSearchScreenWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const AdvancedUnifiedSearchScreen(),
                    ),
                    settings: settings,
                  );
                case AppRoutes.contentRemovedAppeal:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const ContentRemovedAppealScreen(),
                    ),
                    settings: settings,
                  );
                case AppRoutes.contentModerationControlCenter:
                case AppRoutes.contentModerationControlCenterWebCanonical:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const ContentModerationControlCenterScreen(),
                    ),
                    settings: settings,
                  );
                case AppRoutes.contentDistributionControlCenter:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const ContentDistributionControlCenterScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.participationFeeControls:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      RoleRouteGuard(
                        requiredRoles: AppRoles.adminRoles,
                        child: const ParticipationFeeControlsScreen(),
                      ),
                    ),
                    settings: settings,
                  );
                case AppRoutes.bulkManagementScreen:
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      const BulkManagementScreen(),
                    ),
                    settings: settings,
                  );
                default:
                  final widget = screenForRoute(settings.name);
                  return MaterialPageRoute(
                    builder: (_) => gate(
                      widget ??
                          RoutePlaceholderScreen(
                            routeName: settings.name ?? '',
                            title: settings.name ?? '',
                          ),
                    ),
                    settings: settings,
                  );
              }
            },
          ),
        );
      },
    );
  }
}
