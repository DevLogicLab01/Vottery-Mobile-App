import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// GA4 Analytics Service using Google Analytics Measurement Protocol v2
/// Comprehensive event tracking with offline queuing support
class GA4AnalyticsService {
  static GA4AnalyticsService? _instance;
  static GA4AnalyticsService get instance =>
      _instance ??= GA4AnalyticsService._();
  GA4AnalyticsService._();

  final Dio _dio = Dio();
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  static const String _ga4MeasurementId = String.fromEnvironment(
    'GA4_MEASUREMENT_ID',
    defaultValue: '',
  );
  static const String _ga4ApiSecret = String.fromEnvironment(
    'GA4_API_SECRET',
    defaultValue: '',
  );
  static const String _offlineQueueKey = 'ga4_offline_events';

  String? _sessionId;
  String? _clientId;
  DateTime? _sessionStart;

  /// Initialize GA4 service and sync offline events
  Future<void> initialize() async {
    try {
      _clientId = _uuid.v4();
      await _syncOfflineEvents();
    } catch (e) {
      debugPrint('GA4 initialization error: $e');
    }
  }

  /// Start new session
  Future<void> startSession() async {
    try {
      _sessionId = 'session_${_uuid.v4()}';
      _sessionStart = DateTime.now();

      await _trackEvent(
        eventName: 'session_start',
        eventType: 'session_start',
        params: {
          'session_id': _sessionId,
          'timestamp': _sessionStart!.toIso8601String(),
        },
      );

      // Store in Supabase
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('ga4_sessions').insert({
          'user_id': userId,
          'session_id': _sessionId,
          'session_start': _sessionStart!.toIso8601String(),
          'screen_views_count': 0,
          'events_count': 0,
        });
      }
    } catch (e) {
      debugPrint('Start session error: $e');
    }
  }

  /// End current session
  Future<void> endSession() async {
    try {
      if (_sessionId == null || _sessionStart == null) return;

      final sessionDuration = DateTime.now()
          .difference(_sessionStart!)
          .inSeconds;

      await _trackEvent(
        eventName: 'session_end',
        eventType: 'session_end',
        params: {'session_id': _sessionId, 'session_duration': sessionDuration},
      );

      // Update Supabase
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase
            .from('ga4_sessions')
            .update({
              'session_end': DateTime.now().toIso8601String(),
              'session_duration_seconds': sessionDuration,
            })
            .eq('session_id', _sessionId!);
      }

      _sessionId = null;
      _sessionStart = null;
    } catch (e) {
      debugPrint('End session error: $e');
    }
  }

  // ============================================================
  // VOTING EVENTS
  // ============================================================

  Future<void> trackVoteCast({
    required String electionId,
    required String category,
    required String votingType,
    String? zone,
  }) async {
    await _trackEvent(
      eventName: 'vote_cast',
      eventType: 'vote_cast',
      params: {
        'election_id': electionId,
        'category': category,
        'voting_type': votingType,
        if (zone != null) 'zone': zone,
      },
    );
  }

  Future<void> trackVoteVerified({
    required String electionId,
    required String verificationMethod,
  }) async {
    await _trackEvent(
      eventName: 'vote_verified',
      eventType: 'vote_verified',
      params: {
        'election_id': electionId,
        'verification_method': verificationMethod,
      },
    );
  }

  Future<void> trackVoteAudited({
    required String electionId,
    required String auditType,
  }) async {
    await _trackEvent(
      eventName: 'vote_audited',
      eventType: 'vote_audited',
      params: {'election_id': electionId, 'audit_type': auditType},
    );
  }

  // ============================================================
  // QUEST EVENTS
  // ============================================================

  Future<void> trackQuestComplete({
    required String questId,
    required String questType,
    required int vpEarned,
    required String difficulty,
    required int completionTimeSeconds,
  }) async {
    await _trackEvent(
      eventName: 'quest_complete',
      eventType: 'quest_complete',
      params: {
        'quest_id': questId,
        'type': questType,
        'vp_earned': vpEarned,
        'difficulty': difficulty,
        'completion_time': completionTimeSeconds,
      },
    );
  }

  Future<void> trackQuestStart({
    required String questId,
    required String questType,
  }) async {
    await _trackEvent(
      eventName: 'quest_start',
      eventType: 'quest_start',
      params: {'quest_id': questId, 'type': questType},
    );
  }

  // ============================================================
  // VP EARNING EVENTS
  // ============================================================

  Future<void> trackVPEarned({
    required int amount,
    required String source,
    required String transactionType,
    String? paymentMethod,
  }) async {
    await _trackEvent(
      eventName: 'vp_earned',
      eventType: 'vp_earned',
      params: {
        'amount': amount,
        'source': source,
        'transaction_type': transactionType,
        if (paymentMethod != null) 'payment_method': paymentMethod,
      },
    );
  }

  // ============================================================
  // SOCIAL INTERACTION EVENTS
  // ============================================================

  Future<void> trackPostLike({
    required String postId,
    required String contentType,
  }) async {
    await _trackEvent(
      eventName: 'post_like',
      eventType: 'post_like',
      params: {'post_id': postId, 'content_type': contentType},
    );
  }

  Future<void> trackCommentAdded({
    required String postId,
    required String contentType,
  }) async {
    await _trackEvent(
      eventName: 'comment_added',
      eventType: 'comment_added',
      params: {'post_id': postId, 'content_type': contentType},
    );
  }

  Future<void> trackShareClicked({
    required String contentId,
    required String contentType,
  }) async {
    await _trackEvent(
      eventName: 'share_clicked',
      eventType: 'share_clicked',
      params: {'content_id': contentId, 'content_type': contentType},
    );
  }

  Future<void> trackJoltViewed({
    required String joltId,
    required int engagementTimeSeconds,
  }) async {
    await _trackEvent(
      eventName: 'jolt_viewed',
      eventType: 'jolt_viewed',
      params: {
        'jolt_id': joltId,
        'engagement_time': engagementTimeSeconds,
        'content_type': 'jolt',
      },
    );
  }

  Future<void> trackMomentViewed({
    required String momentId,
    required int engagementTimeSeconds,
  }) async {
    await _trackEvent(
      eventName: 'moment_viewed',
      eventType: 'moment_viewed',
      params: {
        'moment_id': momentId,
        'engagement_time': engagementTimeSeconds,
        'content_type': 'moment',
      },
    );
  }

  // ============================================================
  // SCREEN VIEW TRACKING
  // ============================================================

  Future<void> trackScreenView({
    required String screenName,
    String? previousScreen,
    int? timeSpentSeconds,
    String? entryPoint,
  }) async {
    await _trackEvent(
      eventName: 'screen_view',
      eventType: 'screen_view',
      params: {
        'screen_name': screenName,
        if (previousScreen != null) 'previous_screen': previousScreen,
        if (timeSpentSeconds != null) 'time_spent': timeSpentSeconds,
        if (entryPoint != null) 'entry_point': entryPoint,
      },
    );

    // Store in Supabase
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null && _sessionId != null) {
      await _supabase.from('ga4_screen_views').insert({
        'user_id': userId,
        'screen_name': screenName,
        'previous_screen': previousScreen,
        'time_spent_seconds': timeSpentSeconds,
        'entry_point': entryPoint,
        'session_id': _sessionId,
      });
    }
  }

  // ============================================================
  // CONVERSION FUNNEL TRACKING
  // ============================================================

  Future<void> trackConversionFunnel({
    required String funnelStage,
    required bool completed,
  }) async {
    await _trackEvent(
      eventName: funnelStage,
      eventType: funnelStage,
      params: {'funnel_stage': funnelStage, 'completed': completed},
    );

    // Store in Supabase
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null && _sessionId != null) {
      await _supabase.from('ga4_conversion_funnels').insert({
        'user_id': userId,
        'funnel_stage': funnelStage,
        'completed': completed,
        'completion_time': completed ? DateTime.now().toIso8601String() : null,
        'session_id': _sessionId,
      });
    }
  }

  // ============================================================
  // USER PROPERTIES
  // ============================================================

  Future<void> setUserProperties({
    required String subscriptionTier,
    required int userLevel,
    required int totalVPBalance,
    required String votingFrequency,
    required List<String> preferredCategories,
    required int accountAgeDays,
    required String country,
    required String purchasingPowerZone,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('ga4_user_properties').upsert({
        'user_id': userId,
        'subscription_tier': subscriptionTier,
        'user_level': userLevel,
        'total_vp_balance': totalVPBalance,
        'voting_frequency': votingFrequency,
        'preferred_categories': preferredCategories,
        'account_age_days': accountAgeDays,
        'country': country,
        'purchasing_power_zone': purchasingPowerZone,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Set user properties error: $e');
    }
  }

  // ============================================================
  // E-COMMERCE TRACKING
  // ============================================================

  Future<void> trackTransaction({
    required String transactionId,
    required String transactionType,
    required double revenue,
    required String currency,
    String? paymentMethod,
    List<Map<String, dynamic>>? items,
  }) async {
    await _trackEvent(
      eventName: 'purchase',
      eventType: 'transaction',
      params: {
        'transaction_id': transactionId,
        'transaction_type': transactionType,
        'revenue': revenue,
        'currency': currency,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (items != null) 'items': items,
      },
    );

    // Store in Supabase
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase.from('ga4_ecommerce_transactions').insert({
        'user_id': userId,
        'transaction_id': transactionId,
        'transaction_type': transactionType,
        'revenue': revenue,
        'currency': currency,
        'payment_method': paymentMethod,
        'items': items,
      });
    }
  }

  // ============================================================
  // CRASH ANALYTICS
  // ============================================================

  Future<void> trackCrash({
    required String crashType,
    required String stackTrace,
    Map<String, dynamic>? deviceInfo,
    String? appVersion,
  }) async {
    await _trackEvent(
      eventName: 'app_crash',
      eventType: 'app_crash',
      params: {
        'crash_type': crashType,
        'stack_trace': stackTrace,
        if (deviceInfo != null) 'device_info': deviceInfo,
        if (appVersion != null) 'app_version': appVersion,
      },
    );

    // Store in Supabase
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('ga4_crash_reports').insert({
      'user_id': userId,
      'crash_type': crashType,
      'stack_trace': stackTrace,
      'device_info': deviceInfo,
      'app_version': appVersion,
    });
  }

  // ============================================================
  // MONETIZATION TRACKING EVENTS (Phase 5 Batch 7)
  // ============================================================

  /// Track when creator views earnings widget
  Future<void> trackEarningsViewed({
    required String creatorId,
    required double totalEarnings,
  }) async {
    await _trackEvent(
      eventName: 'earnings_viewed',
      eventType: 'monetization',
      params: {
        'creator_id': creatorId,
        'total_earnings': totalEarnings,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track when withdrawal is initiated
  Future<void> trackWithdrawalInitiated({
    required double amount,
    required String zone,
    required String paymentMethod,
  }) async {
    await _trackEvent(
      eventName: 'withdrawal_initiated',
      eventType: 'monetization',
      params: {
        'amount': amount,
        'zone': zone,
        'payment_method': paymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track successful withdrawal completion
  Future<void> trackWithdrawalCompleted({
    required String settlementId,
    required double amount,
    required String currency,
    required String paymentMethod,
  }) async {
    await _trackEvent(
      eventName: 'withdrawal_completed',
      eventType: 'monetization',
      params: {
        'settlement_id': settlementId,
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track failed withdrawal
  Future<void> trackWithdrawalFailed({
    required String settlementId,
    required String errorReason,
  }) async {
    await _trackEvent(
      eventName: 'withdrawal_failed',
      eventType: 'monetization',
      params: {
        'settlement_id': settlementId,
        'error_reason': errorReason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track KYC process start
  Future<void> trackKycStarted() async {
    await _trackEvent(
      eventName: 'kyc_started',
      eventType: 'compliance',
      params: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Track KYC step completion
  Future<void> trackKycStepCompleted({
    required int stepNumber,
    required String stepName,
  }) async {
    await _trackEvent(
      eventName: 'kyc_step_completed',
      eventType: 'compliance',
      params: {
        'step_number': stepNumber,
        'step_name': stepName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track KYC approval
  Future<void> trackKycApproved() async {
    await _trackEvent(
      eventName: 'kyc_approved',
      eventType: 'compliance',
      params: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Track KYC rejection
  Future<void> trackKycRejected({required String rejectionReason}) async {
    await _trackEvent(
      eventName: 'kyc_rejected',
      eventType: 'compliance',
      params: {
        'rejection_reason': rejectionReason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track settlement request
  Future<void> trackSettlementRequested({
    required String settlementId,
    required double amount,
    required String zone,
  }) async {
    await _trackEvent(
      eventName: 'settlement_requested',
      eventType: 'monetization',
      params: {
        'settlement_id': settlementId,
        'amount': amount,
        'zone': zone,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track settlement pending status
  Future<void> trackSettlementPending({required String settlementId}) async {
    await _trackEvent(
      eventName: 'settlement_pending',
      eventType: 'monetization',
      params: {
        'settlement_id': settlementId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track settlement completion
  Future<void> trackSettlementCompleted({
    required String settlementId,
    required double amount,
  }) async {
    await _trackEvent(
      eventName: 'settlement_completed',
      eventType: 'monetization',
      params: {
        'settlement_id': settlementId,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track settlement reconciliation
  Future<void> trackSettlementReconciled({
    required String settlementId,
    required double expectedAmount,
    required double actualAmount,
  }) async {
    await _trackEvent(
      eventName: 'settlement_reconciled',
      eventType: 'monetization',
      params: {
        'settlement_id': settlementId,
        'expected_amount': expectedAmount,
        'actual_amount': actualAmount,
        'discrepancy': actualAmount - expectedAmount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track revenue by source
  Future<void> trackRevenueSource({
    required String source,
    required double amount,
    required String currency,
    String? attributedCampaign,
  }) async {
    await _trackEvent(
      eventName: 'revenue_source',
      eventType: 'monetization',
      params: {
        'revenue_source': source,
        'revenue_amount': amount,
        'revenue_currency': currency,
        if (attributedCampaign != null)
          'attributed_campaign': attributedCampaign,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track lottery draw completion
  Future<void> trackLotteryDrawCompleted({
    required String electionId,
    required int winnersCount,
  }) async {
    await _trackEvent(
      eventName: 'lottery_draw_completed',
      eventType: 'lottery',
      params: {
        'election_id': electionId,
        'winners_count': winnersCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track lottery winner notification sent
  Future<void> trackLotteryWinnerNotified({
    required String winnerId,
    required String electionId,
    required int position,
    required double prizeAmount,
  }) async {
    await _trackEvent(
      eventName: 'lottery_winner_notified',
      eventType: 'lottery',
      params: {
        'winner_id': winnerId,
        'election_id': electionId,
        'position': position,
        'prize_amount': prizeAmount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track lottery prize claimed
  Future<void> trackLotteryPrizeClaimed({
    required String winnerId,
    required String electionId,
    required double prizeAmount,
  }) async {
    await _trackEvent(
      eventName: 'lottery_prize_claimed',
      eventType: 'lottery',
      params: {
        'winner_id': winnerId,
        'election_id': electionId,
        'prize_amount': prizeAmount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // ADVANCED MONETIZATION FUNNEL EVENTS (Phase B Batch 5)
  // ============================================================

  /// Track when earnings widget is opened
  Future<void> trackEarningsWidgetOpened({
    required String creatorId,
    required double currentBalance,
  }) async {
    await _trackEvent(
      eventName: 'earnings_widget_opened',
      eventType: 'monetization_funnel',
      params: {
        'creator_id': creatorId,
        'current_balance': currentBalance,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track withdrawal initiated with detailed parameters
  Future<void> trackWithdrawalInitiatedAdvanced({
    required double amount,
    required String currency,
    required String method,
    required String zone,
  }) async {
    await _trackEvent(
      eventName: 'withdrawal_initiated',
      eventType: 'monetization_funnel',
      params: {
        'amount': amount,
        'currency': currency,
        'method': method,
        'zone': zone,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track withdrawal completed with settlement details
  Future<void> trackWithdrawalCompletedAdvanced({
    required String settlementId,
    required double netAmount,
    required double fees,
    required String currency,
  }) async {
    await _trackEvent(
      eventName: 'withdrawal_completed',
      eventType: 'monetization_funnel',
      params: {
        'settlement_id': settlementId,
        'net_amount': netAmount,
        'fees': fees,
        'currency': currency,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track withdrawal failed with retry information
  Future<void> trackWithdrawalFailedAdvanced({
    required String settlementId,
    required String errorReason,
    required int retryCount,
  }) async {
    await _trackEvent(
      eventName: 'withdrawal_failed',
      eventType: 'monetization_funnel',
      params: {
        'settlement_id': settlementId,
        'error_reason': errorReason,
        'retry_count': retryCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // DETAILED KYC STAGE TRACKING
  // ============================================================

  /// Track KYC Step 1 started
  Future<void> trackKycStep1Started() async {
    await _trackEvent(
      eventName: 'kyc_step_1_started',
      eventType: 'kyc_funnel',
      params: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Track KYC Step 1 completed
  Future<void> trackKycStep1Completed() async {
    await _trackEvent(
      eventName: 'kyc_step_1_completed',
      eventType: 'kyc_funnel',
      params: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Track KYC Step 2 identity upload
  Future<void> trackKycStep2IdentityUpload({
    required String documentType,
  }) async {
    await _trackEvent(
      eventName: 'kyc_step_2_identity_upload',
      eventType: 'kyc_funnel',
      params: {
        'document_type': documentType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track KYC Step 3 address verification
  Future<void> trackKycStep3AddressVerification() async {
    await _trackEvent(
      eventName: 'kyc_step_3_address_verification',
      eventType: 'kyc_funnel',
      params: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Track KYC Step 4 bank details
  Future<void> trackKycStep4BankDetails({required String accountType}) async {
    await _trackEvent(
      eventName: 'kyc_step_4_bank_details',
      eventType: 'kyc_funnel',
      params: {
        'account_type': accountType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track KYC Step 5 tax documents
  Future<void> trackKycStep5TaxDocuments({required String formType}) async {
    await _trackEvent(
      eventName: 'kyc_step_5_tax_documents',
      eventType: 'kyc_funnel',
      params: {
        'form_type': formType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track KYC approved with duration
  Future<void> trackKycApprovedAdvanced({
    required int approvalDurationHours,
  }) async {
    await _trackEvent(
      eventName: 'kyc_approved',
      eventType: 'kyc_funnel',
      params: {
        'approval_duration_hours': approvalDurationHours,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track KYC rejected with detailed reason
  Future<void> trackKycRejectedAdvanced({
    required String rejectionReason,
  }) async {
    await _trackEvent(
      eventName: 'kyc_rejected',
      eventType: 'kyc_funnel',
      params: {
        'rejection_reason': rejectionReason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // SETTLEMENT SUCCESS METRICS
  // ============================================================

  /// Track settlement requested with zone and amount
  Future<void> trackSettlementRequestedAdvanced({
    required String settlementId,
    required String zone,
    required double amount,
  }) async {
    await _trackEvent(
      eventName: 'settlement_requested',
      eventType: 'settlement_metrics',
      params: {
        'settlement_id': settlementId,
        'zone': zone,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track settlement pending with processing estimate
  Future<void> trackSettlementPendingAdvanced({
    required String settlementId,
    required int processingTimeEstimateMinutes,
  }) async {
    await _trackEvent(
      eventName: 'settlement_pending',
      eventType: 'settlement_metrics',
      params: {
        'settlement_id': settlementId,
        'processing_time_estimate': processingTimeEstimateMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track settlement completed with payout details
  Future<void> trackSettlementCompletedAdvanced({
    required String settlementId,
    required double actualPayout,
    required double exchangeRate,
    required double fees,
  }) async {
    await _trackEvent(
      eventName: 'settlement_completed',
      eventType: 'settlement_metrics',
      params: {
        'settlement_id': settlementId,
        'actual_payout': actualPayout,
        'exchange_rate': exchangeRate,
        'fees': fees,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track settlement failed with failure category
  Future<void> trackSettlementFailed({
    required String settlementId,
    required String failureCategory,
  }) async {
    await _trackEvent(
      eventName: 'settlement_failed',
      eventType: 'settlement_metrics',
      params: {
        'settlement_id': settlementId,
        'failure_category': failureCategory,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track settlement reconciled with discrepancy
  Future<void> trackSettlementReconciledAdvanced({
    required String settlementId,
    required double discrepancyAmount,
  }) async {
    await _trackEvent(
      eventName: 'settlement_reconciled',
      eventType: 'settlement_metrics',
      params: {
        'settlement_id': settlementId,
        'discrepancy_amount': discrepancyAmount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // REVENUE ATTRIBUTION TRACKING
  // ============================================================

  /// Track revenue with full attribution
  Future<void> trackRevenueAttribution({
    required String revenueSource,
    required double revenueAmount,
    required String revenueCurrency,
    String? attributedCampaign,
    String? userCohort,
    String? acquisitionChannel,
    double? lifetimeValue,
  }) async {
    await _trackEvent(
      eventName: 'revenue_attribution',
      eventType: 'revenue_tracking',
      params: {
        'revenue_source': revenueSource,
        'revenue_amount': revenueAmount,
        'revenue_currency': revenueCurrency,
        if (attributedCampaign != null)
          'attributed_campaign': attributedCampaign,
        if (userCohort != null) 'user_cohort': userCohort,
        if (acquisitionChannel != null)
          'acquisition_channel': acquisitionChannel,
        if (lifetimeValue != null) 'lifetime_value': lifetimeValue,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // PARTICIPATION FEE EVENTS
  // ============================================================

  /// Track participation fee payment initiated
  Future<void> trackFeePaymentInitiated({
    required String electionId,
    required double amount,
    required String zone,
  }) async {
    await _trackEvent(
      eventName: 'fee_payment_initiated',
      eventType: 'participation_fees',
      params: {
        'election_id': electionId,
        'amount': amount,
        'zone': zone,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track participation fee payment success
  Future<void> trackFeePaymentSuccess({
    required String electionId,
    required String zone,
    required double amount,
  }) async {
    await _trackEvent(
      eventName: 'fee_payment_success',
      eventType: 'participation_fees',
      params: {
        'election_id': electionId,
        'zone': zone,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track participation fee refund issued
  Future<void> trackFeeRefundIssued({
    required String electionId,
    required double amount,
    required String reason,
  }) async {
    await _trackEvent(
      eventName: 'fee_refund_issued',
      eventType: 'participation_fees',
      params: {
        'election_id': electionId,
        'amount': amount,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // SUBSCRIPTION EVENTS
  // ============================================================

  /// Track subscription upgraded
  Future<void> trackSubscriptionUpgraded({
    required String oldTier,
    required String newTier,
  }) async {
    await _trackEvent(
      eventName: 'subscription_upgraded',
      eventType: 'subscription',
      params: {
        'old_tier': oldTier,
        'new_tier': newTier,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track subscription downgraded
  Future<void> trackSubscriptionDowngraded({
    required String oldTier,
    required String newTier,
  }) async {
    await _trackEvent(
      eventName: 'subscription_downgraded',
      eventType: 'subscription',
      params: {
        'old_tier': oldTier,
        'new_tier': newTier,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track subscription churned
  Future<void> trackSubscriptionChurned({required String churnReason}) async {
    await _trackEvent(
      eventName: 'subscription_churned',
      eventType: 'subscription',
      params: {
        'churn_reason': churnReason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // CREATOR TIER EVENTS
  // ============================================================

  /// Track creator tier promotion
  Future<void> trackTierPromoted({required String newTier}) async {
    await _trackEvent(
      eventName: 'tier_promoted',
      eventType: 'creator_tier',
      params: {
        'new_tier': newTier,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track creator tier milestone achieved
  Future<void> trackTierMilestoneAchieved({
    required String milestoneName,
  }) async {
    await _trackEvent(
      eventName: 'tier_milestone_achieved',
      eventType: 'creator_tier',
      params: {
        'milestone_name': milestoneName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // PRIZE DISTRIBUTION EVENTS
  // ============================================================

  /// Track prize claimed with claim duration
  Future<void> trackPrizeClaimed({
    required String prizeId,
    required double amount,
    required int claimDurationMinutes,
  }) async {
    await _trackEvent(
      eventName: 'prize_claimed',
      eventType: 'prize_distribution',
      params: {
        'prize_id': prizeId,
        'amount': amount,
        'claim_duration': claimDurationMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track prize forfeited
  Future<void> trackPrizeForfeited({
    required String prizeId,
    required String forfeitReason,
  }) async {
    await _trackEvent(
      eventName: 'prize_forfeited',
      eventType: 'prize_distribution',
      params: {
        'prize_id': prizeId,
        'forfeit_reason': forfeitReason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // CUSTOM DIMENSION TRACKING
  // ============================================================

  /// Set custom user dimensions for advanced segmentation
  Future<void> setCustomDimensions({
    String? creatorTier,
    String? subscriptionStatus,
    String? kycStatus,
    String? primaryZone,
    int? creatorAgeDays,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('ga4_user_properties').upsert({
        'user_id': userId,
        if (creatorTier != null) 'creator_tier': creatorTier,
        if (subscriptionStatus != null)
          'subscription_status': subscriptionStatus,
        if (kycStatus != null) 'kyc_status': kycStatus,
        if (primaryZone != null) 'primary_zone': primaryZone,
        if (creatorAgeDays != null) 'creator_age_days': creatorAgeDays,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Set custom dimensions error: $e');
    }
  }

  // ============================================================
  // CORE EVENT TRACKING
  // ============================================================

  Future<void> trackEvent({
    required String eventName,
    required Map<String, dynamic> eventParams,
  }) async {
    await _trackEvent(
      eventName: eventName,
      eventType: eventName,
      params: eventParams,
    );
  }

  Future<void> _trackEvent({
    required String eventName,
    required String eventType,
    required Map<String, dynamic> params,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final timestampMicros = DateTime.now().microsecondsSinceEpoch;

      final eventData = {
        'user_id': userId,
        'event_type': eventType,
        'event_name': eventName,
        'event_params': params,
        'session_id': _sessionId,
        'client_id': _clientId ?? _uuid.v4(),
        'timestamp_micros': timestampMicros,
        'is_synced': false,
        'sync_attempts': 0,
      };

      // Store in Supabase for offline queuing
      await _supabase.from('ga4_analytics_events').insert(eventData);

      // Attempt to send to GA4 Measurement Protocol
      if (_ga4MeasurementId.isNotEmpty && _ga4ApiSecret.isNotEmpty) {
        await _sendToGA4(eventName, params, timestampMicros);
      }
    } catch (e) {
      debugPrint('Track event error: $e');
      await _queueOfflineEvent(eventName, eventType, params);
    }
  }

  Future<void> _sendToGA4(
    String eventName,
    Map<String, dynamic> params,
    int timestampMicros,
  ) async {
    try {
      final url =
          'https://www.google-analytics.com/mp/collect?measurement_id=$_ga4MeasurementId&api_secret=$_ga4ApiSecret';

      final payload = {
        'client_id': _clientId,
        'timestamp_micros': timestampMicros,
        'events': [
          {'name': eventName, 'params': params},
        ],
      };

      await _dio.post(url, data: payload);
    } catch (e) {
      debugPrint('Send to GA4 error: $e');
    }
  }

  // ============================================================
  // OFFLINE EVENT QUEUING
  // ============================================================

  Future<void> _queueOfflineEvent(
    String eventName,
    String eventType,
    Map<String, dynamic> params,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_offlineQueueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));

      queue.add({
        'event_name': eventName,
        'event_type': eventType,
        'params': params,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await prefs.setString(_offlineQueueKey, jsonEncode(queue));
    } catch (e) {
      debugPrint('Queue offline event error: $e');
    }
  }

  Future<void> _syncOfflineEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_offlineQueueKey);
      if (queueJson == null) return;

      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));
      if (queue.isEmpty) return;

      for (final event in queue) {
        await _trackEvent(
          eventName: event['event_name'],
          eventType: event['event_type'],
          params: Map<String, dynamic>.from(event['params']),
        );
      }

      await prefs.remove(_offlineQueueKey);
      debugPrint('Synced ${queue.length} offline events');
    } catch (e) {
      debugPrint('Sync offline events error: $e');
    }
  }

  // ============================================================
  // TAX COMPLIANCE FLOW TRACKING
  // ============================================================

  /// Track tax compliance flow start
  Future<void> trackTaxComplianceFlowStarted() async {
    await _trackEvent(
      eventName: 'tax_compliance_flow_started',
      eventType: 'tax_compliance',
      params: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Track tax document upload
  Future<void> trackTaxDocumentUploaded({
    required String documentType,
    required String jurisdiction,
  }) async {
    await _trackEvent(
      eventName: 'tax_document_uploaded',
      eventType: 'tax_compliance',
      params: {
        'document_type': documentType,
        'jurisdiction': jurisdiction,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track tax form completion
  Future<void> trackTaxFormCompleted({
    required String formType,
    required String jurisdiction,
  }) async {
    await _trackEvent(
      eventName: 'tax_form_completed',
      eventType: 'tax_compliance',
      params: {
        'form_type': formType,
        'jurisdiction': jurisdiction,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track tax compliance status change
  Future<void> trackTaxComplianceStatusChanged({
    required String previousStatus,
    required String newStatus,
    required String jurisdiction,
  }) async {
    await _trackEvent(
      eventName: 'tax_compliance_status_changed',
      eventType: 'tax_compliance',
      params: {
        'previous_status': previousStatus,
        'new_status': newStatus,
        'jurisdiction': jurisdiction,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track tax notification sent
  Future<void> trackTaxNotificationSent({
    required String notificationType,
    required String jurisdiction,
    required String recipientId,
  }) async {
    await _trackEvent(
      eventName: 'tax_notification_sent',
      eventType: 'tax_compliance',
      params: {
        'notification_type': notificationType,
        'jurisdiction': jurisdiction,
        'recipient_id': recipientId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track tax compliance flow completed
  Future<void> trackTaxComplianceFlowCompleted({
    required int durationMinutes,
    required String jurisdiction,
  }) async {
    await _trackEvent(
      eventName: 'tax_compliance_flow_completed',
      eventType: 'tax_compliance',
      params: {
        'duration_minutes': durationMinutes,
        'jurisdiction': jurisdiction,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // MARKETPLACE CONVERSION TRACKING
  // ============================================================

  /// Track marketplace service viewed
  Future<void> trackMarketplaceServiceViewed({
    required String serviceId,
    required String serviceName,
    required double price,
    required String sellerId,
  }) async {
    await _trackEvent(
      eventName: 'marketplace_service_viewed',
      eventType: 'marketplace',
      params: {
        'service_id': serviceId,
        'service_name': serviceName,
        'price': price,
        'seller_id': sellerId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track marketplace service added to cart
  Future<void> trackMarketplaceAddToCart({
    required String serviceId,
    required String serviceName,
    required double price,
  }) async {
    await _trackEvent(
      eventName: 'marketplace_add_to_cart',
      eventType: 'marketplace',
      params: {
        'service_id': serviceId,
        'service_name': serviceName,
        'price': price,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track marketplace purchase initiated
  Future<void> trackMarketplacePurchaseInitiated({
    required String serviceId,
    required double amount,
    required String currency,
  }) async {
    await _trackEvent(
      eventName: 'marketplace_purchase_initiated',
      eventType: 'marketplace',
      params: {
        'service_id': serviceId,
        'amount': amount,
        'currency': currency,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track marketplace purchase completed
  Future<void> trackMarketplacePurchaseCompleted({
    required String transactionId,
    required String serviceId,
    required double amount,
    required String currency,
    required String sellerId,
    required String buyerId,
  }) async {
    await _trackEvent(
      eventName: 'marketplace_purchase_completed',
      eventType: 'marketplace',
      params: {
        'transaction_id': transactionId,
        'service_id': serviceId,
        'amount': amount,
        'currency': currency,
        'seller_id': sellerId,
        'buyer_id': buyerId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track marketplace purchase failed
  Future<void> trackMarketplacePurchaseFailed({
    required String serviceId,
    required String errorReason,
  }) async {
    await _trackEvent(
      eventName: 'marketplace_purchase_failed',
      eventType: 'marketplace',
      params: {
        'service_id': serviceId,
        'error_reason': errorReason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track marketplace seller revenue
  Future<void> trackMarketplaceSellerRevenue({
    required String sellerId,
    required double revenue,
    required String currency,
    required String transactionId,
  }) async {
    await _trackEvent(
      eventName: 'marketplace_seller_revenue',
      eventType: 'marketplace',
      params: {
        'seller_id': sellerId,
        'revenue': revenue,
        'currency': currency,
        'transaction_id': transactionId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track marketplace review submitted
  Future<void> trackMarketplaceReviewSubmitted({
    required String transactionId,
    required String serviceId,
    required int rating,
  }) async {
    await _trackEvent(
      eventName: 'marketplace_review_submitted',
      eventType: 'marketplace',
      params: {
        'transaction_id': transactionId,
        'service_id': serviceId,
        'rating': rating,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track marketplace conversion funnel
  Future<void> trackMarketplaceConversionFunnel({
    required String funnelStage,
    required String serviceId,
    required bool completed,
  }) async {
    await _trackEvent(
      eventName: 'marketplace_conversion_funnel',
      eventType: 'marketplace',
      params: {
        'funnel_stage': funnelStage,
        'service_id': serviceId,
        'completed': completed,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // COHORT ANALYSIS TRACKING
  // ============================================================

  /// Track user cohort assignment
  Future<void> trackUserCohortAssigned({
    required String cohortId,
    required String cohortName,
    required String cohortType,
  }) async {
    await _trackEvent(
      eventName: 'user_cohort_assigned',
      eventType: 'cohort_analysis',
      params: {
        'cohort_id': cohortId,
        'cohort_name': cohortName,
        'cohort_type': cohortType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track cohort milestone reached
  Future<void> trackCohortMilestoneReached({
    required String cohortId,
    required String milestone,
    required int daysSinceJoin,
  }) async {
    await _trackEvent(
      eventName: 'cohort_milestone_reached',
      eventType: 'cohort_analysis',
      params: {
        'cohort_id': cohortId,
        'milestone': milestone,
        'days_since_join': daysSinceJoin,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track cohort retention event
  Future<void> trackCohortRetention({
    required String cohortId,
    required int dayNumber,
    required bool retained,
  }) async {
    await _trackEvent(
      eventName: 'cohort_retention',
      eventType: 'cohort_analysis',
      params: {
        'cohort_id': cohortId,
        'day_number': dayNumber,
        'retained': retained,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // ACCESSIBILITY EVENTS (NEW)
  // ============================================================

  /// Track font size adjustment
  Future<void> trackFontSizeAdjustment({
    required String size,
    required double scaleFactor,
  }) async {
    await _trackEvent(
      eventName: 'font_size_adjustment',
      eventType: 'accessibility',
      params: {'font_size': size, 'scale_factor': scaleFactor},
    );
  }

  /// Track theme preference change
  Future<void> trackThemePreferenceChange({required String theme}) async {
    await _trackEvent(
      eventName: 'theme_preference_change',
      eventType: 'accessibility',
      params: {'theme': theme},
    );
  }

  /// Track accessibility feature usage
  Future<void> trackAccessibilityFeatureUsage({
    required String featureName,
    required bool enabled,
  }) async {
    await _trackEvent(
      eventName: 'accessibility_feature_usage',
      eventType: 'accessibility',
      params: {'feature_name': featureName, 'enabled': enabled},
    );
  }

  /// Track screen reader usage
  Future<void> trackScreenReaderUsage({required bool enabled}) async {
    await _trackEvent(
      eventName: 'screen_reader_usage',
      eventType: 'accessibility',
      params: {'enabled': enabled},
    );
  }

  /// Track high contrast mode
  Future<void> trackHighContrastMode({required bool enabled}) async {
    await _trackEvent(
      eventName: 'high_contrast_mode',
      eventType: 'accessibility',
      params: {'enabled': enabled},
    );
  }

  /// Track reduced motion preference
  Future<void> trackReducedMotion({required bool enabled}) async {
    await _trackEvent(
      eventName: 'reduced_motion',
      eventType: 'accessibility',
      params: {'enabled': enabled},
    );
  }

  // ============================================================
  // GAMIFICATION EVENTS
  // ============================================================

  /// Track VP spent event
  Future<void> trackVPSpent({
    required String itemCategory,
    required String itemName,
    required int vpAmount,
    required int userBalance,
  }) async {
    await _trackEvent(
      eventName: 'vp_spent',
      eventType: 'vp_spent',
      params: {
        'item_category': itemCategory,
        'item_name': itemName,
        'vp_amount': vpAmount,
        'user_balance': userBalance,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track badge unlocked event
  Future<void> trackBadgeUnlocked({
    required String badgeId,
    required String badgeName,
    required String badgeRarity,
    required int userTotalBadges,
  }) async {
    await _trackEvent(
      eventName: 'badge_unlocked',
      eventType: 'badge_unlocked',
      params: {
        'badge_id': badgeId,
        'badge_name': badgeName,
        'badge_rarity': badgeRarity,
        'unlock_date': DateTime.now().toIso8601String(),
        'user_total_badges': userTotalBadges,
      },
    );
  }

  /// Track streak milestone event
  Future<void> trackStreakMilestone({
    required String streakType,
    required int streakDays,
    required double multiplier,
    required int longestStreak,
  }) async {
    await _trackEvent(
      eventName: 'streak_milestone',
      eventType: 'streak_milestone',
      params: {
        'streak_type': streakType,
        'streak_days': streakDays,
        'multiplier': multiplier,
        'longest_streak': longestStreak,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track prediction accuracy event
  Future<void> trackPredictionAccuracy({
    required String predictionPoolId,
    required double brierScore,
    required int vpReward,
    required int leaderboardRank,
  }) async {
    await _trackEvent(
      eventName: 'prediction_accuracy',
      eventType: 'prediction_accuracy',
      params: {
        'prediction_pool_id': predictionPoolId,
        'brier_score': brierScore,
        'vp_reward': vpReward,
        'leaderboard_rank': leaderboardRank,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track leaderboard change event
  Future<void> trackLeaderboardChange({
    required String leaderboardType,
    required int oldRank,
    required int newRank,
    required int rankChange,
  }) async {
    await _trackEvent(
      eventName: 'leaderboard_change',
      eventType: 'leaderboard_change',
      params: {
        'leaderboard_type': leaderboardType,
        'old_rank': oldRank,
        'new_rank': newRank,
        'rank_change': rankChange,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track quest completed event
  Future<void> trackQuestCompleted({
    required String questId,
    required String questType,
    required int vpReward,
    required int completionTime,
  }) async {
    await _trackEvent(
      eventName: 'quest_completed',
      eventType: 'quest_completed',
      params: {
        'quest_id': questId,
        'quest_type': questType,
        'vp_reward': vpReward,
        'completion_time': completionTime,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Set user gamification properties
  Future<void> setGamificationUserProperties({
    required int userLevel,
    required int currentVPBalance,
    required int totalBadgesEarned,
    required String engagementLevel,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('ga4_user_properties').upsert({
        'user_id': userId,
        'property_name': 'user_level',
        'property_value': userLevel.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _supabase.from('ga4_user_properties').upsert({
        'user_id': userId,
        'property_name': 'current_vp_balance',
        'property_value': currentVPBalance.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _supabase.from('ga4_user_properties').upsert({
        'user_id': userId,
        'property_name': 'total_badges_earned',
        'property_value': totalBadgesEarned.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _supabase.from('ga4_user_properties').upsert({
        'user_id': userId,
        'property_name': 'engagement_level',
        'property_value': engagementLevel,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Set gamification user properties error: $e');
    }
  }

  /// Track gamification funnel
  Future<void> trackGamificationFunnel({
    required String funnelStep,
    required String funnelName,
  }) async {
    await _trackEvent(
      eventName: 'gamification_funnel',
      eventType: 'gamification_funnel',
      params: {
        'funnel_name': funnelName,
        'funnel_step': funnelStep,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================
  // CREATOR EARNINGS TRACKING (NEW)
  // ============================================================

  /// Track creator earnings with detailed breakdown
  Future<void> trackCreatorEarnings({
    required String creatorId,
    required double amount,
    required String earningsType, // jolt, election, prediction, marketplace
    required String payoutMethod, // stripe, trolley
    required String revenueSplit, // 70/30, 80/20, etc.
    String? zone,
    String? currency,
  }) async {
    await _trackEvent(
      eventName: 'creator_earnings',
      eventType: 'creator_monetization',
      params: {
        'creator_id': creatorId,
        'amount': amount,
        'earnings_type': earningsType,
        'payout_method': payoutMethod,
        'revenue_split': revenueSplit,
        if (zone != null) 'zone': zone,
        if (currency != null) 'currency': currency,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Store in Supabase for analytics
    try {
      await _supabase.from('ga4_creator_earnings').insert({
        'creator_id': creatorId,
        'amount': amount,
        'earnings_type': earningsType,
        'payout_method': payoutMethod,
        'revenue_split': revenueSplit,
        'zone': zone,
        'currency': currency,
      });
    } catch (e) {
      debugPrint('Store creator earnings error: $e');
    }
  }

  // ============================================================
  // AI FEATURE ADOPTION TRACKING (NEW)
  // ============================================================

  /// Track AI feature adoption and usage
  Future<void> trackAIFeatureAdoption({
    required String
    featureName, // quest_generation, feed_ranking, threat_detection, etc.
    required String aiProvider, // claude, openai, perplexity, gemini
    required int executionTimeMs,
    required bool successStatus,
    String? errorMessage,
    Map<String, dynamic>? additionalParams,
  }) async {
    await _trackEvent(
      eventName: 'ai_feature_adoption',
      eventType: 'ai_usage',
      params: {
        'feature_name': featureName,
        'ai_provider': aiProvider,
        'execution_time_ms': executionTimeMs,
        'success_status': successStatus,
        if (errorMessage != null) 'error_message': errorMessage,
        if (additionalParams != null) ...additionalParams,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Store in Supabase for analytics
    try {
      await _supabase.from('ga4_ai_feature_adoption').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'feature_name': featureName,
        'ai_provider': aiProvider,
        'execution_time_ms': executionTimeMs,
        'success_status': successStatus,
        'error_message': errorMessage,
        'additional_params': additionalParams,
      });
    } catch (e) {
      debugPrint('Store AI feature adoption error: $e');
    }
  }
}
