import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/location_voting_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Location-based Voting screen with geolocation detection and nearby votes map
class LocationVoting extends StatefulWidget {
  const LocationVoting({super.key});

  @override
  State<LocationVoting> createState() => _LocationVotingState();
}

class _LocationVotingState extends State<LocationVoting> {
  final LocationVotingService _locationService = LocationVotingService.instance;

  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<Map<String, dynamic>> _nearbyElections = [];
  Map<String, dynamic>? _regionalStats;
  bool _isLoading = true;
  String? _errorMessage;
  final double _radiusKm = 50.0;
  String? _selectedCategory;
  Set<Marker> _markers = {};

  final List<String> _categories = [
    'All',
    'Politics',
    'Community',
    'Education',
    'Environment',
    'Healthcare',
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hasPermission = await _locationService.checkLocationPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Location permission denied';
          _isLoading = false;
        });
        return;
      }

      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        setState(() {
          _errorMessage = 'Unable to get current location';
          _isLoading = false;
        });
        return;
      }

      setState(() => _currentPosition = position);
      await _loadNearbyElections();
      await _loadRegionalStats();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNearbyElections() async {
    if (_currentPosition == null) return;

    try {
      final elections = await _locationService.getLocationFilteredElections(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        radiusKm: _radiusKm,
      );

      setState(() {
        _nearbyElections = elections;
        _updateMarkers();
      });
    } catch (e) {
      debugPrint('Load nearby elections error: $e');
    }
  }

  Future<void> _loadRegionalStats() async {
    if (_currentPosition == null) return;

    try {
      final stats = await _locationService.getRegionalStats(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: _radiusKm,
      );

      setState(() {
        _regionalStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Load regional stats error: $e');
    }
  }

  Future<void> _loadData() async {
    await _initializeLocation();
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Add election markers
    for (var election in _nearbyElections) {
      final locations = election['election_locations'] as List?;
      if (locations != null && locations.isNotEmpty) {
        final location = locations.first;
        final lat = location['latitude'] as double?;
        final lon = location['longitude'] as double?;
        if (lat != null && lon != null) {
          markers.add(
            Marker(
              markerId: MarkerId(election['id']),
              position: LatLng(lat, lon),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(
                title: election['title'],
                snippet: election['category'] ?? 'Election',
              ),
              onTap: () => _showElectionDetails(election),
            ),
          );
        }
      }
    }

    setState(() => _markers = markers);
  }

  void _showElectionDetails(Map<String, dynamic> election) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildElectionDetailsSheet(election),
    );
  }

  Widget _buildElectionDetailsSheet(Map<String, dynamic> election) {
    final theme = Theme.of(context);
    final locations = election['election_locations'] as List?;
    double? distance;

    if (_currentPosition != null && locations != null && locations.isNotEmpty) {
      final location = locations.first;
      final lat = location['latitude'] as double?;
      final lon = location['longitude'] as double?;
      if (lat != null && lon != null) {
        distance = _locationService.calculateDistance(
          fromLat: _currentPosition!.latitude,
          fromLon: _currentPosition!.longitude,
          toLat: lat,
          toLon: lon,
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.dialogBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
      padding: EdgeInsets.all(6.w),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    election['title'] ?? 'Election',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (distance != null)
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'location_on',
                    color: theme.colorScheme.primary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '${distance.toStringAsFixed(1)} km away',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            SizedBox(height: 2.h),
            Text(
              election['description'] ?? 'No description available',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.voteCasting,
                    arguments: election['id'],
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                ),
                child: Text(
                  'View Election',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'LocationVoting',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Location-Based Voting',
          variant: CustomAppBarVariant.withBack,
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 6)
            : _nearbyElections.isEmpty
            ? NoDataEmptyState(
                title: 'No Nearby Elections',
                description: 'Elections in your area will appear here.',
                onRefresh: _loadData,
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: Column(
                  children: [
                    // Regional stats
                    if (_regionalStats != null)
                      Container(
                        padding: EdgeInsets.all(4.w),
                        color: theme.colorScheme.surface,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Elections',
                              _regionalStats!['total_elections'].toString(),
                              Icons.how_to_vote,
                            ),
                            _buildStatItem(
                              'Votes',
                              _regionalStats!['total_votes'].toString(),
                              Icons.check_circle,
                            ),
                            _buildStatItem(
                              'Voters',
                              _regionalStats!['active_voters'].toString(),
                              Icons.people,
                            ),
                          ],
                        ),
                      ),

                    // Category filter
                    Container(
                      height: 6.h,
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected =
                              _selectedCategory == category ||
                              (_selectedCategory == null && category == 'All');
                          return Padding(
                            padding: EdgeInsets.only(right: 2.w),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = category == 'All'
                                      ? null
                                      : category;
                                });
                                _loadNearbyElections();
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Map
                    Expanded(
                      child: _currentPosition == null
                          ? Center(child: Text('Loading map...'))
                          : GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                zoom: 11,
                              ),
                              markers: _markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              onMapCreated: (controller) {
                                _mapController = controller;
                              },
                            ),
                    ),

                    // Nearby elections list
                    Container(
                      height: 20.h,
                      color: theme.colorScheme.surface,
                      child: _nearbyElections.isEmpty
                          ? Center(
                              child: Text(
                                'No elections found nearby',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(2.w),
                              itemCount: _nearbyElections.length,
                              itemBuilder: (context, index) {
                                final election = _nearbyElections[index];
                                return Card(
                                  margin: EdgeInsets.only(bottom: 2.w),
                                  child: ListTile(
                                    leading: CustomIconWidget(
                                      iconName: 'how_to_vote',
                                      color: theme.colorScheme.primary,
                                      size: 8.w,
                                    ),
                                    title: Text(
                                      election['title'] ?? 'Election',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      election['category'] ?? 'General',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 4.w,
                                    ),
                                    onTap: () => _showElectionDetails(election),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 6.w),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}