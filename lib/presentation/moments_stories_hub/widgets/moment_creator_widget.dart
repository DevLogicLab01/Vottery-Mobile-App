import 'dart:io' show File;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/moments_service.dart';
import '../../../services/moments_viral_scoring_service.dart';
import '../../../theme/app_theme.dart';
import 'viral_score_widget.dart';

/// Moment creator with camera integration, filters, text overlays
class MomentCreatorWidget extends StatefulWidget {
  final List<CameraDescription> cameras;
  final VoidCallback onClose;

  const MomentCreatorWidget({
    super.key,
    required this.cameras,
    required this.onClose,
  });

  @override
  State<MomentCreatorWidget> createState() => _MomentCreatorWidgetState();
}

class _MomentCreatorWidgetState extends State<MomentCreatorWidget> {
  final MomentsService _momentsService = MomentsService.instance;
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isUploading = false;
  String? _capturedImagePath;
  final TextEditingController _captionController = TextEditingController();
  bool _viralLoading = false;
  Map<String, dynamic>? _viralPayload;
  String? _viralError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() => _isInitialized = false);
      return;
    }

    try {
      final camera = kIsWeb
          ? widget.cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => widget.cameras.first,
            )
          : widget.cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => widget.cameras.first,
            );

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      );

      await _cameraController!.initialize();

      if (!kIsWeb) {
        try {
          await _cameraController!.setFocusMode(FocusMode.auto);
          await _cameraController!.setFlashMode(FlashMode.auto);
        } catch (e) {
          debugPrint('Camera settings error: $e');
        }
      }

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Initialize camera error: $e');
      setState(() => _isInitialized = false);
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      setState(() => _capturedImagePath = image.path);
    } catch (e) {
      debugPrint('Capture photo error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture photo')));
      }
    }
  }

  Future<void> _analyzeViralScore() async {
    if (_capturedImagePath == null) return;
    setState(() {
      _viralLoading = true;
      _viralError = null;
    });
    try {
      final cap = _captionController.text.trim();
      final result =
          await MomentsViralScoringService.instance.analyzeMomentComposition(
        mediaCount: 1,
        filterCount: 0,
        textStickerCount: cap.isEmpty ? 0 : 1,
        interactiveElementCount: 0,
        caption: cap,
      );
      if (!mounted) return;
      if (result['error'] != null) {
        setState(() {
          _viralLoading = false;
          _viralError = result['error'].toString();
          _viralPayload = null;
        });
        return;
      }
      setState(() {
        _viralLoading = false;
        _viralPayload = result;
        _viralError = null;
      });
    } catch (e) {
      debugPrint('Viral score error: $e');
      if (mounted) {
        setState(() {
          _viralLoading = false;
          _viralError = 'Unable to analyze viral potential right now.';
          _viralPayload = null;
        });
      }
    }
  }

  Future<void> _publishMoment() async {
    if (_capturedImagePath == null) return;

    setState(() => _isUploading = true);

    try {
      // In production, upload to storage first
      final mediaUrl = _capturedImagePath!;

      final momentId = await _momentsService.createMoment(
        mediaUrl: mediaUrl,
        mediaType: 'image',
        caption: _captionController.text.trim(),
        durationSeconds: 5,
      );

      if (momentId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moment published! +10 VP earned'),
            backgroundColor: AppTheme.accentLight,
          ),
        );
        widget.onClose();
      }
    } catch (e) {
      debugPrint('Publish moment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to publish moment')));
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _capturedImagePath != null ? _buildPreview() : _buildCamera(),
      ),
    );
  }

  Widget _buildCamera() {
    if (!_isInitialized || _cameraController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.vibrantYellow),
            SizedBox(height: 2.h),
            Text(
              'Initializing camera...',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(_cameraController!)),
        Positioned(
          top: 2.h,
          left: 4.w,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 7.w),
            onPressed: widget.onClose,
          ),
        ),
        Positioned(
          bottom: 5.h,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _capturePhoto,
              child: Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Container(
                  margin: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewImage() {
    final path = _capturedImagePath!;
    if (kIsWeb) {
      return Image.network(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }

  Widget _buildPreview() {
    final ot = _viralPayload?['optimalTiming'] as Map<String, dynamic>?;
    final suggestions = (_viralPayload?['improvementSuggestions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList() ??
        <String>[];

    return Stack(
      children: [
        Positioned.fill(
          child: _buildPreviewImage(),
        ),
        Positioned(
          top: 2.h,
          left: 4.w,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 7.w),
            onPressed: () => setState(() => _capturedImagePath = null),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            constraints: BoxConstraints(maxHeight: 55.h),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withAlpha(230), Colors.transparent],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_viralLoading)
                    Padding(
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 4.w,
                            height: 4.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.vibrantYellow,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Claude is scoring viral potential…',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_viralError != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Text(
                        _viralError!,
                        style: GoogleFonts.inter(
                          color: Colors.orangeAccent,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (_viralPayload != null && !_viralLoading) ...[
                    ViralScoreWidget(
                      viralScore: () {
                        final raw = _viralPayload!['overallScore'];
                        final v = raw is num
                            ? raw.toDouble()
                            : double.tryParse(raw?.toString() ?? '') ?? 0;
                        return v.clamp(0.0, 100.0).toDouble();
                      }(),
                      message:
                          'Confidence ${(_viralPayload!['confidence'] as num?)?.toStringAsFixed(0) ?? '0'}%',
                    ),
                    if (ot != null) ...[
                      SizedBox(height: 1.h),
                      Text(
                        'Best time: ${ot['bestDay'] ?? '—'} · ${ot['bestTime'] ?? '—'} (${ot['timezone'] ?? 'Local'})',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10.sp,
                        ),
                      ),
                      if ((ot['reasoning']?.toString() ?? '').isNotEmpty)
                        Text(
                          ot['reasoning'].toString(),
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 9.sp,
                          ),
                        ),
                    ],
                    if (suggestions.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        'Tips',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ...suggestions.take(4).map(
                            (s) => Text(
                              '• $s',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _viralLoading ? null : _analyzeViralScore,
                        child: Text(
                          'Refresh score',
                          style: GoogleFonts.inter(
                            color: AppTheme.vibrantYellow,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                  TextField(
                    controller: _captionController,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a caption...',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withAlpha(179),
                        fontSize: 14.sp,
                      ),
                      border: InputBorder.none,
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _publishMoment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.vibrantYellow,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                      ),
                      child: _isUploading
                          ? SizedBox(
                              height: 2.h,
                              width: 2.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'Share Moment',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
