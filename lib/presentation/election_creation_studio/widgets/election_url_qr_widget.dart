import 'dart:io' show File;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';
import 'package:universal_html/html.dart' as universal_html;
import 'package:flutter/rendering.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Widget for displaying election URL and QR code with sharing options
class ElectionUrlQrWidget extends StatefulWidget {
  final String electionId;
  final String electionTitle;
  final String? logoUrl;

  const ElectionUrlQrWidget({
    super.key,
    required this.electionId,
    required this.electionTitle,
    this.logoUrl,
  });

  @override
  State<ElectionUrlQrWidget> createState() => _ElectionUrlQrWidgetState();
}

class _ElectionUrlQrWidgetState extends State<ElectionUrlQrWidget> {
  late String _electionUrl;
  bool _isGenerating = false;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _electionUrl = 'https://vottery.com/election/${widget.electionId}';
  }

  Future<void> _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: _electionUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL copied to clipboard'),
          backgroundColor: AppTheme.accentLight,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareUrl() async {
    try {
      await Share.share(
        'Vote on "${widget.electionTitle}" at Vottery!\n\n$_electionUrl',
        subject: 'Join Election: ${widget.electionTitle}',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  Future<void> _downloadQrCode() async {
    try {
      setState(() => _isGenerating = true);

      // Capture QR code widget as image
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Failed to capture QR code');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Trigger download
      final blob = universal_html.Blob([bytes]);
      final url = universal_html.Url.createObjectUrlFromBlob(blob);
      universal_html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'vottery_election_${widget.electionId}_qr.png',
        )
        ..click();
      universal_html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR code downloaded successfully'),
            backgroundColor: AppTheme.accentLight,
          ),
        );
      }
    } catch (e) {
      debugPrint('Download QR code error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download QR code'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Share Your Election',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Share this URL or QR code on social media platforms',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          _buildUrlSection(),
          SizedBox(height: 3.h),
          _buildQrCodeSection(),
          SizedBox(height: 3.h),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildUrlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Election URL',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _electionUrl,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.accentLight,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 2.w),
              InkWell(
                onTap: _copyUrl,
                child: Icon(
                  Icons.copy,
                  color: AppTheme.primaryLight,
                  size: 5.w,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QR Code',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        Center(
          child: _isGenerating
              ? SizedBox(
                  width: 50.w,
                  height: 50.w,
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.accentLight),
                  ),
                )
              : RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      border:
                          Border.all(color: Colors.grey.shade300, width: 2.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 50.w,
                          height: 50.w,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PrettyQrView.data(
                                data: _electionUrl,
                                errorCorrectLevel: QrErrorCorrectLevel.H,
                                decoration: const PrettyQrDecoration(
                                  shape: PrettyQrSmoothSymbol(
                                    color: AppTheme.primaryLight,
                                  ),
                                ),
                              ),
                              const _VotteryQrCenterMark(),
                            ],
                          ),
                        ),
                        if (widget.logoUrl != null &&
                            widget.logoUrl!.isNotEmpty) ...[
                          SizedBox(height: 1.5.h),
                          Text(
                            'ELECTION BRAND',
                            style: TextStyle(
                              fontSize: 9.sp,
                              letterSpacing: 0.6,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 0.6.h),
                          _ElectionBrandLogo(logoPathOrUrl: widget.logoUrl!),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Social preview',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'See how your QR will look on Instagram, TikTok, and YouTube thumbnails. Use this as a guide when designing your covers.',
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 1.5.h),
        Row(
          children: [
            _SocialPreviewCard(
              label: 'Instagram Reel',
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            SizedBox(width: 2.w),
            _SocialPreviewCard(
              label: 'TikTok Video',
              gradient: const LinearGradient(
                colors: [Color(0xFF111827), Color(0xFF1F2937)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            SizedBox(width: 2.w),
            _SocialPreviewCard(
              label: 'YouTube Thumb',
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _shareUrl,
            icon: Icon(Icons.share, size: 5.w),
            label: Text('Share', style: TextStyle(fontSize: 13.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentLight,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isGenerating ? null : _downloadQrCode,
            icon: _isGenerating
                ? SizedBox(
                    width: 5.w,
                    height: 5.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryLight,
                    ),
                  )
                : Icon(Icons.download, size: 5.w),
            label: Text('Download QR', style: TextStyle(fontSize: 13.sp)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryLight,
              side: BorderSide(color: AppTheme.primaryLight),
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Vottery app-style mark in the QR center (blue + gold stroke + check).
class _VotteryQrCenterMark extends StatelessWidget {
  const _VotteryQrCenterMark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 18.w,
        height: 18.w,
        constraints: const BoxConstraints(maxWidth: 72, maxHeight: 72),
        decoration: BoxDecoration(
          color: const Color(0xFF0F5FFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4AF37), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '✓',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            Text(
              '⌁',
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 10.sp,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ElectionBrandLogo extends StatelessWidget {
  final String logoPathOrUrl;

  const _ElectionBrandLogo({required this.logoPathOrUrl});

  @override
  Widget build(BuildContext context) {
    final lower = logoPathOrUrl.toLowerCase();
    final isHttp =
        lower.startsWith('http://') || lower.startsWith('https://');
    final box = Container(
      width: 22.w,
      height: 22.w,
      constraints: const BoxConstraints(maxWidth: 96, maxHeight: 96),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: isHttp
          ? Image.network(
              logoPathOrUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported,
                  color: Colors.grey.shade400),
            )
          : (!kIsWeb && File(logoPathOrUrl).existsSync())
              ? Image.file(
                  File(logoPathOrUrl),
                  fit: BoxFit.contain,
                )
              : Icon(Icons.business, color: Colors.grey.shade500, size: 8.w),
    );
    return box;
  }
}

class _SocialPreviewCard extends StatelessWidget {
  final String label;
  final Gradient gradient;

  const _SocialPreviewCard({
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 11.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  gradient: gradient,
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: EdgeInsets.all(1.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 1.2.w, vertical: 0.4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4.w,
                          height: 4.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(color: Colors.grey.shade300, width: 0.5),
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Vottery',
                          style: TextStyle(
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 1.8.w, vertical: 0.6.h),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
