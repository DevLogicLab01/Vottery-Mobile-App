class Batch1ControlPolicy {
  Batch1ControlPolicy._();

  static const Set<String> forceDisabledFeatureKeys = {
    'participatory_advertising',
    'campaign_management_dashboard',
    'campaign_optimization_dashboard',
    'campaign_template_gallery',
    'advertiser_analytics_roi',
    'enhanced_real_time_advertiser_roi_dashboard',
    'sponsored_elections_schema_cpe_management_hub',
    'dynamic_ad_rendering_fill_rate_analytics_hub',
    'ad_slot_manager_inventory_control_center',
    'dual_advertising_system_analytics_dashboard',
    'advanced_perplexity_fraud_intelligence_center',
    'advanced_perplexity_fraud_forecasting_center',
    'content_distribution_control_center',
    'enterprise_white_label',
    'enterprise_sso',
  };

  static const Set<String> defaultDisabledIfMissing = {
    'advanced_perplexity_fraud_intelligence_center',
    'advanced_perplexity_fraud_forecasting_center',
    'unified_incident_response_orchestration_center',
    'real_time_performance_testing_suite',
    'content_distribution_control_center',
    'enterprise_white_label',
    'enterprise_sso',
    'participatory_advertising',
  };

  static const Set<String> defaultEnabledIfMissing = {
    'vote_in_elections_hub',
    'secure_voting_interface',
    'voting_categories',
    'notification_center_hub',
    'settings_account_dashboard',
    'user_profile_hub',
    'digital_wallet_hub',
    'stripe_connect_account_linking_interface',
    'user_subscription_dashboard',
    'interactive_onboarding_wizard',
    'multi_authentication_gateway',
  };
}
