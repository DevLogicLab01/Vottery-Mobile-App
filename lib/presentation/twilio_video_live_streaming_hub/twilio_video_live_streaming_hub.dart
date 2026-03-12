import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/broadcast_controls_widget.dart';
import './widgets/interactive_qa_widget.dart';
import './widgets/participant_management_widget.dart';
import './widgets/recording_management_widget.dart';
import './widgets/stream_analytics_widget.dart';
import './widgets/viewer_count_widget.dart';

class TwilioVideoLiveStreamingHub extends StatefulWidget {
  const TwilioVideoLiveStreamingHub({super.key});

  @override
  State<TwilioVideoLiveStreamingHub> createState() =>
      _TwilioVideoLiveStreamingHubState();
}

class _TwilioVideoLiveStreamingHubState
    extends State<TwilioVideoLiveStreamingHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Room? _room;
  bool _isConnecting = false;
  bool _isStreaming = false;
  int _viewerCount = 0;
  final List<Map<String, dynamic>> _qaMessages = [];
  List<Participant> _participants = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _setupRoomListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _room?.disconnect();
    super.dispose();
  }

  void _setupRoomListeners() {
    // Room listeners will be set up when room is created
  }

  Future<void> _startStream() async {
    setState(() => _isConnecting = true);

    try {
      // In production, get token from your backend
      const token = String.fromEnvironment(
        'LIVEKIT_TOKEN',
        defaultValue: 'demo-token',
      );
      const url = String.fromEnvironment(
        'LIVEKIT_URL',
        defaultValue: 'wss://your-livekit-server.com',
      );

      _room = Room();
      await _room?.connect(
        url,
        token,
        connectOptions: const ConnectOptions(),
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );

      _room?.addListener(_onRoomUpdate);

      // Enable camera and microphone
      await _room?.localParticipant?.setCameraEnabled(true);
      await _room?.localParticipant?.setMicrophoneEnabled(true);

      setState(() {
        _isStreaming = true;
        _isConnecting = false;
        _participants = _room?.remoteParticipants.values.toList() ?? [];
      });
    } catch (e) {
      setState(() => _isConnecting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start stream: $e')));
      }
    }
  }

  Future<void> _stopStream() async {
    await _room?.disconnect();
    setState(() {
      _isStreaming = false;
      _viewerCount = 0;
      _participants.clear();
    });
  }

  void _onRoomUpdate() {
    setState(() {
      _participants = _room?.remoteParticipants.values.toList() ?? [];
      _viewerCount = _participants.length;
    });
  }

  void _addQAMessage(String question) {
    setState(() {
      _qaMessages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'question': question,
        'timestamp': DateTime.now(),
        'answered': false,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'TwilioVideoLiveStreamingHub',
      onRetry: () {},
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Live Streaming Hub',
          actions: [
            ViewerCountWidget(count: _viewerCount),
            SizedBox(width: 2.w),
          ],
        ),
        body: Column(
          children: [
            _buildStreamPreview(),
            _buildControlBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  BroadcastControlsWidget(
                    isStreaming: _isStreaming,
                    onStartStream: _startStream,
                    onStopStream: _stopStream,
                    room: _room,
                  ),
                  InteractiveQAWidget(
                    messages: _qaMessages,
                    onAddMessage: _addQAMessage,
                  ),
                  ParticipantManagementWidget(
                    participants: _participants,
                    room: _room,
                  ),
                  RecordingManagementWidget(
                    isStreaming: _isStreaming,
                    room: _room,
                  ),
                  StreamAnalyticsWidget(
                    viewerCount: _viewerCount,
                    isStreaming: _isStreaming,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamPreview() {
    return Container(
      height: 30.h,
      color: Colors.black,
      child: _isStreaming && _room != null
          ? Stack(
              children: [
                // Video preview would go here
                Center(
                  child: Icon(
                    Icons.videocam,
                    size: 15.w,
                    color: Colors.white.withAlpha(128),
                  ),
                ),
                Positioned(
                  top: 2.h,
                  left: 4.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 2.w,
                          height: 2.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    size: 15.w,
                    color: Colors.white.withAlpha(128),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _isConnecting ? 'Connecting...' : 'Stream Offline',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isStreaming ? Icons.stop : Icons.play_arrow,
            label: _isStreaming ? 'Stop' : 'Start',
            color: _isStreaming ? AppTheme.errorLight : AppTheme.accentLight,
            onTap: _isStreaming ? _stopStream : _startStream,
          ),
          _buildControlButton(
            icon: Icons.mic,
            label: 'Audio',
            color: AppTheme.primaryLight,
            onTap: () async {
              final enabled =
                  _room?.localParticipant?.isMicrophoneEnabled() ?? false;
              await _room?.localParticipant?.setMicrophoneEnabled(!enabled);
            },
          ),
          _buildControlButton(
            icon: Icons.videocam,
            label: 'Video',
            color: AppTheme.secondaryLight,
            onTap: () async {
              final enabled =
                  _room?.localParticipant?.isCameraEnabled() ?? false;
              await _room?.localParticipant?.setCameraEnabled(!enabled);
            },
          ),
          _buildControlButton(
            icon: Icons.screen_share,
            label: 'Share',
            color: AppTheme.warningLight,
            onTap: () async {
              await _room?.localParticipant?.setScreenShareEnabled(true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 6.w, color: color),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Controls'),
          Tab(text: 'Q&A'),
          Tab(text: 'Participants'),
          Tab(text: 'Recording'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }
}
