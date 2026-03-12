import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/ai_voice_service.dart';
import './widgets/voice_activation_button_widget.dart';
import './widgets/voice_command_library_widget.dart';
import './widgets/voice_settings_panel_widget.dart';
import './widgets/audio_visualization_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// AI Voice Interaction Hub Screen
/// Enables speech-to-text and text-to-speech for hands-free AI interactions
class AIVoiceInteractionHub extends StatefulWidget {
  const AIVoiceInteractionHub({super.key});

  @override
  State<AIVoiceInteractionHub> createState() => _AIVoiceInteractionHubState();
}

class _AIVoiceInteractionHubState extends State<AIVoiceInteractionHub>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _continuousListening = false;
  String _transcript = '';
  String _aiResponse = '';
  bool _isProcessing = false;
  double _audioLevel = 0.0;
  Timer? _audioLevelTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _initializeVoiceService() async {
    final isAvailable = await AIVoiceService.isSpeechAvailable();
    if (!isAvailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _transcript = '';
      _aiResponse = '';
    });

    _startAudioLevelSimulation();

    try {
      await AIVoiceService.voiceQueryAI(
        context: 'Mobile AI Voice Interaction',
        onResponse: (response) {
          if (mounted) {
            setState(() {
              _aiResponse = response;
              _isListening = false;
              _isSpeaking = true;
              _isProcessing = false;
            });
            _stopAudioLevelSimulation();

            // Stop speaking after response
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() => _isSpeaking = false);
              }
            });
          }
        },
        onTranscript: (transcript) {
          if (mounted) {
            setState(() {
              _transcript = transcript;
              if (transcript.isNotEmpty) {
                _isProcessing = true;
              }
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _isProcessing = false;
        });
        _stopAudioLevelSimulation();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice query failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopListening() async {
    await AIVoiceService.stopListening();
    setState(() {
      _isListening = false;
      _isProcessing = false;
    });
    _stopAudioLevelSimulation();
  }

  void _startAudioLevelSimulation() {
    _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (mounted) {
        setState(() {
          _audioLevel = Random().nextDouble() * 0.8 + 0.2;
        });
      }
    });
  }

  void _stopAudioLevelSimulation() {
    _audioLevelTimer?.cancel();
    setState(() => _audioLevel = 0.0);
  }

  @override
  void dispose() {
    _audioLevelTimer?.cancel();
    _pulseController.dispose();
    AIVoiceService.stopListening();
    AIVoiceService.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AIVoiceInteractionHub',
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'AI Voice Interaction Hub',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                _continuousListening ? Icons.mic : Icons.mic_off,
                color: _continuousListening ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                setState(() => _continuousListening = !_continuousListening);
              },
              tooltip: 'Continuous Listening',
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.grey),
              onPressed: () => _showSettingsPanel(),
              tooltip: 'Voice Settings',
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(),
                SizedBox(height: 2.h),
                AudioVisualizationWidget(
                  isActive: _isListening,
                  audioLevel: _audioLevel,
                ),
                SizedBox(height: 2.h),
                _buildTranscriptCard(),
                SizedBox(height: 2.h),
                _buildAIResponseCard(),
                SizedBox(height: 3.h),
                VoiceActivationButtonWidget(
                  isListening: _isListening,
                  onPressed: _isListening ? _stopListening : _startListening,
                  pulseAnimation: _pulseController,
                ),
                SizedBox(height: 3.h),
                VoiceCommandLibraryWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_isListening) {
      statusText = 'Listening...';
      statusColor = Colors.green;
      statusIcon = Icons.mic;
    } else if (_isProcessing) {
      statusText = 'Processing...';
      statusColor = Colors.orange;
      statusIcon = Icons.psychology;
    } else if (_isSpeaking) {
      statusText = 'AI Speaking...';
      statusColor = Colors.blue;
      statusIcon = Icons.volume_up;
    } else {
      statusText = 'Ready';
      statusColor = Colors.grey;
      statusIcon = Icons.mic_none;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 24.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Service Status',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            if (_isListening || _isProcessing)
              SizedBox(
                width: 20.sp,
                height: 20.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.record_voice_over, color: Colors.blue, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Your Voice Input',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              constraints: BoxConstraints(minHeight: 10.h),
              child: Text(
                _transcript.isEmpty
                    ? 'Tap the microphone button to start speaking...'
                    : _transcript,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: _transcript.isEmpty ? Colors.grey : Colors.black87,
                  fontStyle: _transcript.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIResponseCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'AI Response',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_aiResponse.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      _isSpeaking ? Icons.volume_up : Icons.volume_off,
                      size: 20.sp,
                    ),
                    onPressed: () async {
                      if (_isSpeaking) {
                        await AIVoiceService.stopSpeaking();
                        setState(() => _isSpeaking = false);
                      } else {
                        await AIVoiceService.speak(_aiResponse);
                        setState(() => _isSpeaking = true);
                      }
                    },
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8.0),
              ),
              constraints: BoxConstraints(minHeight: 10.h),
              child: Text(
                _aiResponse.isEmpty
                    ? 'AI response will appear here...'
                    : _aiResponse,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: _aiResponse.isEmpty ? Colors.grey : Colors.black87,
                  fontStyle: _aiResponse.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceSettingsPanelWidget(),
    );
  }
}
