import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/team_incident_war_room_service.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/war_room_chat_widget.dart';
import './widgets/investigation_board_widget.dart';
import './widgets/team_panel_widget.dart';
import './widgets/activity_timeline_widget.dart';

class TeamIncidentWarRoom extends StatefulWidget {
  final String? roomId;
  final String? incidentId;

  const TeamIncidentWarRoom({super.key, this.roomId, this.incidentId});

  @override
  State<TeamIncidentWarRoom> createState() => _TeamIncidentWarRoomState();
}

class _TeamIncidentWarRoomState extends State<TeamIncidentWarRoom>
    with SingleTickerProviderStateMixin {
  final _warRoomService = TeamIncidentWarRoomService.instance;
  final _authService = AuthService.instance;
  final _client = SupabaseService.instance.client;

  bool _isLoading = true;
  String? _currentRoomId;
  Map<String, dynamic>? _warRoomData;
  List<Map<String, dynamic>> _teamMembers = [];
  final int _activeTab = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeWarRoom();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeWarRoom() async {
    setState(() => _isLoading = true);

    try {
      if (widget.roomId != null) {
        _currentRoomId = widget.roomId;
        await _loadWarRoomData();
      } else if (widget.incidentId != null) {
        // Create new war room for incident
        final result = await _warRoomService.createWarRoom(
          incidentId: widget.incidentId!,
          incidentType: 'critical',
        );

        if (result['success'] == true) {
          _currentRoomId = result['room_id'];
          await _loadWarRoomData();
        }
      }
    } catch (e) {
      debugPrint('Initialize war room error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWarRoomData() async {
    if (_currentRoomId == null) return;

    try {
      // Load war room details
      final warRoom = await _client
          .from('war_rooms')
          .select()
          .eq('room_id', _currentRoomId!)
          .single();

      // Load team members
      final members = await _client
          .from('war_room_members')
          .select()
          .eq('room_id', _currentRoomId!);

      setState(() {
        _warRoomData = warRoom;
        _teamMembers = List<Map<String, dynamic>>.from(members);
      });
    } catch (e) {
      debugPrint('Load war room data error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'TeamIncidentWarRoom',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: _warRoomData?['room_name'] ?? 'War Room',
          actions: [
            // War room status indicator
            Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: _warRoomData?['status'] == 'active'
                    ? Colors.red.withAlpha(51)
                    : Colors.green.withAlpha(51),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _warRoomData?['status'] == 'active'
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _warRoomData?['status']?.toUpperCase() ?? 'LOADING',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: _warRoomData?['status'] == 'active'
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            // Close war room button
            if (_warRoomData?['status'] == 'active')
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: _showCloseWarRoomDialog,
                tooltip: 'Close War Room',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentRoomId == null
            ? _buildErrorState()
            : Column(
                children: [
                  // War room metrics header
                  _buildMetricsHeader(),
                  // Tab bar
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryLight,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppTheme.primaryLight,
                      tabs: const [
                        Tab(icon: Icon(Icons.chat), text: 'Chat'),
                        Tab(icon: Icon(Icons.dashboard), text: 'Board'),
                        Tab(icon: Icon(Icons.people), text: 'Team'),
                        Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
                      ],
                    ),
                  ),
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        WarRoomChatWidget(roomId: _currentRoomId!),
                        InvestigationBoardWidget(roomId: _currentRoomId!),
                        TeamPanelWidget(
                          roomId: _currentRoomId!,
                          teamMembers: _teamMembers,
                        ),
                        ActivityTimelineWidget(roomId: _currentRoomId!),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMetricsHeader() {
    final createdAt = _warRoomData?['created_at'] != null
        ? DateTime.parse(_warRoomData!['created_at'])
        : DateTime.now();
    final elapsed = DateTime.now().difference(createdAt);

    return Container(
      padding: EdgeInsets.all(2.w),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            icon: Icons.timer,
            label: 'Elapsed',
            value: _formatDuration(elapsed),
            color: Colors.orange,
          ),
          _buildMetricItem(
            icon: Icons.people,
            label: 'Team',
            value: '${_teamMembers.length}',
            color: Colors.blue,
          ),
          _buildMetricItem(
            icon: Icons.message,
            label: 'Messages',
            value: '0', // Will be updated with real count
            color: Colors.green,
          ),
          _buildMetricItem(
            icon: Icons.task,
            label: 'Tasks',
            value: '0', // Will be updated with real count
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60.sp, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'Failed to load war room',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: _initializeWarRoom,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showCloseWarRoomDialog() {
    final resolutionController = TextEditingController();
    final lessonsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close War Room'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: resolutionController,
                decoration: const InputDecoration(
                  labelText: 'Resolution Summary *',
                  hintText: 'Describe how the incident was resolved',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: lessonsController,
                decoration: const InputDecoration(
                  labelText: 'Lessons Learned',
                  hintText: 'What did we learn from this incident?',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (resolutionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Resolution summary is required'),
                  ),
                );
                return;
              }

              final success = await _warRoomService.closeWarRoom(
                roomId: _currentRoomId!,
                resolutionSummary: resolutionController.text,
                lessonsLearned: lessonsController.text.isNotEmpty
                    ? lessonsController.text
                    : null,
              );

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('War room closed successfully')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Close War Room'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
