import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../config/batch1_route_allowlist.dart';
import '../../../routes/app_routes.dart';
import '../../../services/ad_slot_orchestration_service.dart';
import './sponsored_election_card_widget.dart';
import './spark_post_ad_card_widget.dart';
import './vottery_display_ad_card_widget.dart';
import './vottery_participatory_ad_card_widget.dart';

/// Ad Slot Widget
/// Renders internal sponsored election ads or AdSense fallback
class AdSlotWidget extends StatefulWidget {
  final String slotId;

  const AdSlotWidget({super.key, required this.slotId});

  @override
  State<AdSlotWidget> createState() => _AdSlotWidgetState();
}

class _AdSlotWidgetState extends State<AdSlotWidget> {
  late Future<AdSlotContent?> _adFuture;

  @override
  void initState() {
    super.initState();
    _adFuture = AdSlotOrchestrationService.instance.getAdForSlot(widget.slotId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdSlotContent?>(
      future: _adFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 8.h,
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final adContent = snapshot.data!;

        if (adContent is InternalAdContent) {
          if (!Batch1RouteAllowlist.isAllowed(AppRoutes.voteCasting)) {
            return const SizedBox.shrink();
          }
          return SponsoredElectionCardWidget(
            electionId: adContent.electionId,
            adId: adContent.adId,
            campaignData: adContent.campaignData,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.voteCasting,
                arguments: adContent.electionId,
              );
            },
          );
        } else if (adContent is InternalVotteryAdContent) {
          if (!Batch1RouteAllowlist.isAllowed(AppRoutes.voteCasting)) {
            return const SizedBox.shrink();
          }
          final adType = adContent.adType;
          final creative = adContent.creative;

          if (adType == 'spark' && adContent.sourcePostId != null) {
            final ctaLabel =
                (creative['cta_label'] ?? creative['cta'] ?? 'Learn more')
                    .toString();
            final ctaUrl = creative['cta_url']?.toString();
            return SparkPostAdCardWidget(
              sourcePostId: adContent.sourcePostId!,
              ctaLabel: ctaLabel,
              ctaUrl: ctaUrl,
              onClick: () {
                AdSlotOrchestrationService.instance.recordVotteryAdEvent(
                  adId: adContent.adId,
                  eventType: 'CLICK',
                  slotId: widget.slotId,
                  metadata: {
                    'creative': {'cta_url': ctaUrl, 'cta_label': ctaLabel},
                    'ad_type': adType,
                  },
                );
              },
            );
          }

          if ((adType == 'display' || adType == 'video')) {
            return VotteryDisplayAdCardWidget(
              creative: creative,
              adType: adType,
              onClick: () {
                AdSlotOrchestrationService.instance.recordVotteryAdEvent(
                  adId: adContent.adId,
                  eventType: 'CLICK',
                  slotId: widget.slotId,
                  metadata: {'ad_type': adType},
                );
              },
            );
          }

          if (adType == 'participatory' && adContent.electionId != null) {
            return VotteryParticipatoryAdCardWidget(
              electionId: adContent.electionId!,
              adId: adContent.adId,
              creative: creative,
              onClick: () {
                AdSlotOrchestrationService.instance.recordVotteryAdEvent(
                  adId: adContent.adId,
                  eventType: 'CLICK',
                  slotId: widget.slotId,
                  metadata: {
                    'ad_type': adType,
                    'election_id': adContent.electionId,
                  },
                );
              },
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.voteCasting,
                  arguments: adContent.electionId,
                );
              },
            );
          }
        } else if (adContent is AppLovinMaxAdContent) {
          // AppLovin MAX placeholder – replace with actual AppLovin widget when SDK is integrated.
          return Container(
            height: 6.h,
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.blueGrey.shade100),
            ),
            child: Center(
              child: Text(
                'AppLovin MAX Ad',
                style: TextStyle(fontSize: 10.sp, color: Colors.blueGrey[400]),
              ),
            ),
          );
        } else if (adContent is AdMobAdContent) {
          // AdMob placeholder – replace with actual google_mobile_ads BannerAd/NativeAd when integrated.
          return Container(
            height: 6.h,
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                'AdMob Advertisement',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[400]),
              ),
            ),
          );
        } else if (adContent is AdSenseAdContent) {
          // AdSense placeholder (web-style ads; mobile uses generic fallback here).
          return Container(
            height: 6.h,
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                'Advertisement',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[400]),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
