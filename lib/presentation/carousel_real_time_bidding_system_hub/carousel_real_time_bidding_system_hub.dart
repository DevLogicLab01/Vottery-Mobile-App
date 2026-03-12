import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/carousel_rtb_service.dart';
import '../../services/supabase_service.dart';

/// Carousel Real-Time Bidding System Hub
/// Dynamic sponsorship auctions with automated bidding strategies
class CarouselRealTimeBiddingSystemHub extends StatefulWidget {
  const CarouselRealTimeBiddingSystemHub({super.key});

  @override
  State<CarouselRealTimeBiddingSystemHub> createState() =>
      _CarouselRealTimeBiddingSystemHubState();
}

class _CarouselRealTimeBiddingSystemHubState
    extends State<CarouselRealTimeBiddingSystemHub>
    with SingleTickerProviderStateMixin {
  final CarouselRTBService _rtbService = CarouselRTBService.instance;

  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _adSlots = [];
  List<Map<String, dynamic>> _activeAuctions = [];
  List<Map<String, dynamic>> _campaigns = [];

  Timer? _auctionTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _startAuctionTimer();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      final adSlots = await _rtbService.getAvailableSlots();
      final activeAuctions = await _rtbService.getActiveAuctions();
      final campaigns = userId != null
          ? await _rtbService.getActiveAuctions()
          : <Map<String, dynamic>>[];

      setState(() {
        _adSlots = adSlots;
        _activeAuctions = activeAuctions;
        _campaigns = campaigns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startAuctionTimer() {
    _auctionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _auctionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Carousel RTB System',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Inventory'),
            Tab(text: 'Live Auctions'),
            Tab(text: 'Campaigns'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInventoryTab(),
                _buildAuctionsTab(),
                _buildCampaignsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCampaignDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Campaign'),
      ),
    );
  }

  Widget _buildInventoryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          Text(
            'Available Ad Slots',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          if (_adSlots.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(5.h),
                child: Text(
                  'No ad slots available',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
              ),
            )
          else
            ..._adSlots.map((slot) => _buildAdSlotCard(slot)),
        ],
      ),
    );
  }

  Widget _buildAdSlotCard(Map<String, dynamic> slot) {
    final carouselType = slot['carousel_type'] as String;
    final slotName = slot['slot_name'] as String;
    final estimatedImpressions = slot['estimated_daily_impressions'] as int?;
    final minBid = (slot['min_bid'] as num).toDouble();
    final status = slot['status'] as String;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slotName,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _formatCarouselType(carouselType),
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Divider(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Est. Impressions',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                    Text(
                      estimatedImpressions?.toString() ?? 'N/A',
                      style:
                          TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Min Bid',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                    Text(
                      '\$${minBid.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (status == 'available') ...[
              SizedBox(height: 1.h),
              ElevatedButton(
                onPressed: () => _startAuction(slot['inventory_id'], minBid),
                child: const Text('Start Auction'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Auctions',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8.sp, color: Colors.red),
                    SizedBox(width: 1.w),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_activeAuctions.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(5.h),
                child: Text(
                  'No active auctions',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
              ),
            )
          else
            ..._activeAuctions.map((auction) => _buildAuctionCard(auction)),
        ],
      ),
    );
  }

  Widget _buildAuctionCard(Map<String, dynamic> auction) {
    final auctionEnd = DateTime.parse(auction['auction_end']);
    final timeRemaining = auctionEnd.difference(DateTime.now());
    final reservePrice = (auction['reserve_price'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Auction #${auction['auction_id'].toString().substring(0, 8)}',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${timeRemaining.inSeconds}s remaining',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: timeRemaining.inSeconds < 10 ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: 1 - (timeRemaining.inSeconds / 60),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                timeRemaining.inSeconds < 10 ? Colors.red : Colors.orange,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reserve: \$${reservePrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                ElevatedButton(
                  onPressed: () => _showBidDialog(auction),
                  child: const Text('Place Bid'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          Text(
            'My Campaigns',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          if (_campaigns.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(5.h),
                child: Column(
                  children: [
                    Icon(Icons.campaign, size: 48.sp, color: Colors.grey),
                    SizedBox(height: 2.h),
                    Text(
                      'No campaigns yet',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                    SizedBox(height: 1.h),
                    ElevatedButton(
                      onPressed: _showCreateCampaignDialog,
                      child: const Text('Create Campaign'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._campaigns.map((campaign) => _buildCampaignCard(campaign)),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final name = campaign['campaign_name'] as String;
    final totalBudget = (campaign['total_budget'] as num).toDouble();
    final budgetSpent = (campaign['budget_spent'] as num).toDouble();
    final status = campaign['status'] as String;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget: \$${totalBudget.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                Text(
                  'Spent: \$${budgetSpent.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: budgetSpent / totalBudget,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                budgetSpent / totalBudget > 0.8 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCarouselType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'reserved':
        return Colors.orange;
      case 'occupied':
        return Colors.red;
      case 'paused':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _startAuction(String slotId, double reservePrice) async {
    try {
      final auctionId = await _rtbService.createAuction(
        slotId: slotId,
        reservePrice: reservePrice,
        durationSeconds: 60,
      );

      if (auctionId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auction started successfully')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showBidDialog(Map<String, dynamic> auction) async {
    final bidController = TextEditingController();
    final reservePrice = (auction['reserve_price'] as num?)?.toDouble() ?? 0.0;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Place Bid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Minimum bid: \$${reservePrice.toStringAsFixed(2)}'),
            SizedBox(height: 2.h),
            TextField(
              controller: bidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bid Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final bidAmount = double.tryParse(bidController.text);
              if (bidAmount != null && bidAmount >= reservePrice) {
                Navigator.pop(context);
                await _submitBid(auction, bidAmount);
              }
            },
            child: const Text('Submit Bid'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBid(
    Map<String, dynamic> auction,
    double bidAmount,
  ) async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final bidId = await _rtbService.submitBid(
        auctionId: auction['auction_id'],
        slotId: auction['slot_id'],
        bidAmount: bidAmount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showCreateCampaignDialog() async {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Campaign'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Campaign Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Budget',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text;
              final budget = double.tryParse(budgetController.text);
              if (name.isNotEmpty && budget != null && budget > 0) {
                Navigator.pop(context);
                await _createCampaign(name, budget);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCampaign(String name, double budget) async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final campaignId = await _rtbService.createCampaign(
        campaignName: name,
        totalBudget: budget,
        autoBiddingStrategy: 'maximum_cpe',
      );

      if (campaignId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign created successfully')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}