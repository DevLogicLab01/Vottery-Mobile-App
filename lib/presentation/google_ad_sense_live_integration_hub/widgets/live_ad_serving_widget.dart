import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class LiveAdServingWidget extends StatefulWidget {
  final bool isAdSdkInitialized;
  final VoidCallback onRefresh;

  const LiveAdServingWidget({
    super.key,
    required this.isAdSdkInitialized,
    required this.onRefresh,
  });

  @override
  State<LiveAdServingWidget> createState() => _LiveAdServingWidgetState();
}

class _LiveAdServingWidgetState extends State<LiveAdServingWidget> {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isAdSdkInitialized) {
      _loadBannerAd();
      _loadInterstitialAd();
      _loadRewardedAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ad unit
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isBannerLoaded = true);
          debugPrint('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ad unit
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          setState(() => _isInterstitialLoaded = true);
          debugPrint('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test ad unit
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          setState(() => _isRewardedLoaded = true);
          debugPrint('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      setState(() => _isInterstitialLoaded = false);
      _loadInterstitialAd();
    }
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        },
      );
      _rewardedAd = null;
      setState(() => _isRewardedLoaded = false);
      _loadRewardedAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAdSdkInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
            SizedBox(height: 2.h),
            Text(
              'Ad SDK Not Initialized',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'Please restart the app to initialize ads',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Ad Serving',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          _buildAdTypeCard(
            'Banner Ad',
            'Display banner ads in content feeds',
            _isBannerLoaded,
            Icons.view_carousel,
            Colors.blue,
            null,
          ),
          SizedBox(height: 2.h),
          if (_isBannerLoaded && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          SizedBox(height: 2.h),
          _buildAdTypeCard(
            'Interstitial Ad',
            'Full-screen ads between content',
            _isInterstitialLoaded,
            Icons.fullscreen,
            Colors.orange,
            _showInterstitialAd,
          ),
          SizedBox(height: 2.h),
          _buildAdTypeCard(
            'Rewarded Ad',
            'Reward users for watching ads',
            _isRewardedLoaded,
            Icons.card_giftcard,
            Colors.green,
            _showRewardedAd,
          ),
          SizedBox(height: 3.h),
          _buildRealTimeMetrics(),
        ],
      ),
    );
  }

  Widget _buildAdTypeCard(
    String title,
    String description,
    bool isLoaded,
    IconData icon,
    Color color,
    VoidCallback? onShow,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isLoaded ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    isLoaded ? 'Loaded' : 'Loading',
                    style: TextStyle(fontSize: 10.sp, color: Colors.white),
                  ),
                ),
                if (onShow != null && isLoaded) ...[
                  SizedBox(height: 1.h),
                  ElevatedButton(
                    onPressed: onShow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                    ),
                    child: Text(
                      'Show',
                      style: TextStyle(fontSize: 11.sp, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeMetrics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-Time Metrics',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildMetricRow('Impressions Today', '1,247', Icons.visibility),
            Divider(height: 2.h),
            _buildMetricRow('Clicks Today', '89', Icons.touch_app),
            Divider(height: 2.h),
            _buildMetricRow('Revenue Today', '\$23.45', Icons.attach_money),
            Divider(height: 2.h),
            _buildMetricRow('Fill Rate', '98.5%', Icons.pie_chart),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: Colors.grey),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
