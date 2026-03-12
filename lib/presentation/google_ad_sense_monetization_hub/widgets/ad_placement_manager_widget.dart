import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/adsense_service.dart';
import './ad_placement_card_widget.dart';

class AdPlacementManagerWidget extends StatefulWidget {
  final List<Map<String, dynamic>> placements;
  final VoidCallback onRefresh;

  const AdPlacementManagerWidget({
    super.key,
    required this.placements,
    required this.onRefresh,
  });

  @override
  State<AdPlacementManagerWidget> createState() =>
      _AdPlacementManagerWidgetState();
}

class _AdPlacementManagerWidgetState extends State<AdPlacementManagerWidget> {
  final AdSenseService _adSenseService = AdSenseService.instance;
  String _selectedAdType = 'all';

  @override
  Widget build(BuildContext context) {
    final filteredPlacements = _selectedAdType == 'all'
        ? widget.placements
        : widget.placements
              .where((p) => p['ad_type'] == _selectedAdType)
              .toList();

    return Column(
      children: [
        _buildAdTypeFilter(),
        Expanded(
          child: filteredPlacements.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async => widget.onRefresh(),
                  child: ListView.builder(
                    padding: EdgeInsets.all(3.w),
                    itemCount: filteredPlacements.length,
                    itemBuilder: (context, index) {
                      return AdPlacementCardWidget(
                        placement: filteredPlacements[index],
                        onUpdate: widget.onRefresh,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAdTypeFilter() {
    return Container(
      padding: EdgeInsets.all(3.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            SizedBox(width: 2.w),
            _buildFilterChip('Banner', 'banner'),
            SizedBox(width: 2.w),
            _buildFilterChip('Interstitial', 'interstitial'),
            SizedBox(width: 2.w),
            _buildFilterChip('Rewarded', 'rewarded'),
            SizedBox(width: 2.w),
            _buildFilterChip('Native', 'native'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedAdType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedAdType = value);
      },
      selectedColor: const Color(0xFFFFC629),
      checkmarkColor: Colors.black,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ad_units, size: 60.sp, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'No ad placements found',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
