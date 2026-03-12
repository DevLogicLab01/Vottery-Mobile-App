# Vottery Mobile App — Codebase Architecture Diagram

Flutter/Dart mobile app (vottery M). High-level structure and relationships.

---

## 1. High-level layer diagram

```mermaid
flowchart TB
    subgraph entry["Entry & Bootstrap"]
        main["main.dart"]
    end

    subgraph core["Core"]
        app_export["core/app_export.dart"]
        theme["theme/app_theme.dart"]
    end

    subgraph navigation["Navigation"]
        routes["routes/app_routes.dart"]
    end

    subgraph ui["Presentation Layer"]
        presentation["presentation/"]
        features_ui["features/ (screens & widgets)"]
    end

    subgraph shared_ui["Shared UI"]
        widgets["widgets/"]
    end

    subgraph business["Business & Data"]
        services["services/"]
        models["models/"]
        features_logic["features/ (api, controllers)"]
    end

    subgraph platform["Platform & Config"]
        android["android/"]
        ios["ios/"]
        web_platform["web/"]
        pubspec["pubspec.yaml"]
    end

    main --> app_export
    main --> theme
    main --> routes
    main --> services
    routes --> presentation
    routes --> features_ui
    presentation --> widgets
    features_ui --> widgets
    presentation --> services
    features_logic --> services
    features_logic --> models
    services --> models
```

---

## 2. lib/ folder structure

```mermaid
flowchart LR
    subgraph lib["lib/"]
        main["main.dart"]
        core["core/"]
        routes["routes/"]
        theme["theme/"]
        utils["utils/"]
        presentation["presentation/"]
        features["features/"]
        services["services/"]
        models["models/"]
        widgets["widgets/"]
    end

    main --> core
    main --> routes
    main --> theme
    routes --> presentation
    routes --> features
    presentation --> widgets
    features --> widgets
```

---

## 3. Services layer (detail)

```mermaid
flowchart TB
    subgraph services_root["services/"]
        auth["auth_service"]
        payout_settings["payout_settings_service"]
        stripe["stripe_connect_service"]
        wallet["wallet_service"]
        supabase["supabase_service"]
        sentry["sentry_service"]
        payment["payment_service"]
        voting["voting_service"]
        vp["vp_service"]
        ga4["ga4_analytics_service"]
        offline["offline_sync_service"]
        hive["hive_offline_service"]
        ai_notif["ai_notification_service"]
        ai_voice["ai_voice_service"]
        datadog["datadog_tracing_service"]
        webhook["webhook_service"]
    end

    subgraph services_ai["services/ai/"]
        perplexity["perplexity_service"]
        ai_base["ai_service_base"]
    end

    subgraph services_blockchain["services/blockchain/"]
        solana["solana_service"]
        nft["nft_achievement_service"]
    end

    subgraph services_sms["services/sms/"]
        telnyx["telnyx_http_client"]
    end

    subgraph services_logging["services/logging/"]
        log_notif["log_notification_service"]
        platform_log["platform_logging_service"]
        log_stream["log_stream_service"]
    end

    subgraph services_mcq["services/mcq/"]
        mcq_opt["mcq_claude_optimization_service"]
    end

    subgraph services_load["services/load_testing/"]
        load_test["production_load_test_service"]
        load_auto["production_load_test_auto_response_service"]
    end
```

---

## 4. Features module (payouts example)

```mermaid
flowchart TB
    subgraph payouts["features/payouts/"]
        api["api/ payout_api"]
        constants["constants/ payout_constants"]
        controllers["controllers/ payout_controller"]
        screens["screens/ payout_screen"]
        subgraph payouts_widgets["widgets/"]
            balance["balance_card_widget"]
            threshold["threshold_progress_widget"]
            payment_method["payment_method_card_widget"]
            history["payout_history_widget"]
            request_form["request_payout_form_widget"]
        end
    end

    screens --> controllers
    screens --> payouts_widgets
    controllers --> api
    controllers --> constants
```

---

## 5. Presentation layer (screen categories)

```mermaid
flowchart TB
    subgraph presentation["presentation/"]
        subgraph voting_core["Voting & Elections"]
            splash["splash_screen"]
            vote_dashboard["vote_dashboard"]
            vote_discovery["vote_discovery"]
            vote_casting["vote_casting"]
            create_vote["create_vote"]
            vote_analytics["vote_analytics"]
            election_studio["election_creation_studio"]
        end

        subgraph creator["Creator & Monetization"]
            creator_studio["creator_studio_dashboard"]
            creator_analytics["creator_analytics_dashboard"]
            payout_screen["payout_screen (feature)"]
            stripe_hub["stripe_connect_payout_management_hub"]
            wallet["wallet_dashboard"]
            digital_wallet["digital_wallet_screen"]
        end

        subgraph social["Social & Feed"]
            home_feed["social_media_home_feed"]
            nav_hub["social_media_navigation_hub"]
            groups["groups_hub"]
            messaging["direct_messaging_screen"]
            jolts["jolts_video_feed"]
        end

        subgraph admin_ops["Admin & Operations"]
            admin_dashboard["admin_dashboard"]
            feature_toggle["admin_feature_toggle_panel"]
            fraud["advanced_fraud_detection_center"]
            ai_security["ai_security_dashboard"]
            sms_dashboards["sms_* dashboards"]
        end

        subgraph settings["Settings & Profile"]
            settings_hub["comprehensive_settings_hub"]
            user_profile["user_profile"]
            accessibility["accessibility_settings_hub"]
            security_center["user_security_center"]
        end
    end
```

---

## 6. Shared widgets

```mermaid
flowchart LR
    subgraph widgets["widgets/"]
        custom_app_bar["custom_app_bar"]
        custom_bottom_bar["custom_bottom_bar"]
        custom_icon["custom_icon_widget"]
        custom_image["custom_image_widget"]
        custom_error["custom_error_widget"]
        dual_header_top["dual_header_top_bar"]
        dual_header_bottom["dual_header_bottom_bar"]
        error_boundary["error_boundary_widget"]
        shimmer["shimmer_skeleton_loader"]
        offline_banner["offline_banner_widget"]
    end

    subgraph widgets_ai["widgets/ai/"]
        ai_consensus["ai_consensus_widget"]
    end

    subgraph widgets_gamification["widgets/gamification/"]
        vp_dashboard["vp_dashboard_widget"]
        quest_tile["quest_tile_widget"]
        ai_quest["ai_quest_widget"]
    end

    subgraph widgets_security["widgets/security/"]
        security_alerts["security_alerts_widget"]
        security_alert_tile["security_alert_tile"]
    end
```

---

## 7. Main.dart initialization flow

```mermaid
sequenceDiagram
    participant App
    participant Sentry
    participant Supabase
    participant Datadog
    participant Services

    App->>Sentry: SentryService.initialize()
    App->>App: FlutterError / PlatformDispatcher handlers
    App->>App: ErrorWidget.builder (FallbackErrorScreen)
    App->>Supabase: SupabaseService.initialize()
    App->>Datadog: DatadogTracingService.initializeDatadog()
    App->>Services: Accessibility, AI cache, GA4, Hive, etc.
    App->>App: runApp(MyApp)
```

---

## 8. External dependencies (from pubspec)

| Category        | Examples                                      |
|----------------|-----------------------------------------------|
| Backend        | `supabase_flutter`, `dio`, `http`             |
| Auth & security| `local_auth`, `passkeys`, `google_sign_in`     |
| Payments       | `flutter_stripe`                              |
| Analytics      | `sentry_flutter`, GA4, Datadog (via services)  |
| UI & layout    | `sizer`, `flutter_svg`, `google_fonts`        |
| Media          | `video_player`, `camera`, `image_picker`      |
| Maps & location| `geolocator`, `google_maps_flutter`           |
| State & routing| `provider`, `go_router`                       |
| Blockchain     | `web3dart`                                    |

---

## Summary

| Layer        | Location        | Role                                      |
|-------------|-----------------|-------------------------------------------|
| Entry       | `main.dart`     | Bootstrap, Sentry, Supabase, Datadog, runApp |
| Core        | `core/`, `theme/` | Exports, theme                            |
| Navigation  | `routes/`       | Route map → presentation & feature screens |
| Screens     | `presentation/`, `features/*/screens/` | Full-page UIs        |
| Shared UI   | `widgets/`      | App bar, bottom bar, error, loading, etc. |
| Business    | `services/`, `features/*/api|controllers` | Auth, payouts, wallet, AI, SMS, etc. |
| Data        | `models/`       | Domain / API models                       |
| Config      | `pubspec.yaml`, `android/`, `ios/`, `web/` | Deps and platform  |

Render the Mermaid blocks in any Markdown viewer that supports Mermaid (e.g. GitHub, VS Code with Mermaid extension, or [mermaid.live](https://mermaid.live)).
