import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/app_export.dart';
import '../../services/presentation_slides_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/slide_controls_widget.dart';
import './widgets/speaker_notes_widget.dart';
import './widgets/slide_thumbnails_widget.dart';
import './widgets/slide_upload_widget.dart';

/// Presentation Slides Viewer - Comprehensive slide deck support with PDF rendering
class PresentationSlidesViewer extends StatefulWidget {
  final String? electionId;

  const PresentationSlidesViewer({super.key, this.electionId});

  @override
  State<PresentationSlidesViewer> createState() =>
      _PresentationSlidesViewerState();
}

class _PresentationSlidesViewerState extends State<PresentationSlidesViewer> {
  final PresentationSlidesService _slidesService =
      PresentationSlidesService.instance;
  final AuthService _auth = AuthService.instance;
  final PdfViewerController _pdfController = PdfViewerController();

  bool _isLoading = true;
  String? _selectedElectionId;
  List<Map<String, dynamic>> _deckFiles = [];
  Map<String, dynamic>? _currentDeck;
  bool _showThumbnails = false;
  bool _showSpeakerNotes = false;
  bool _isFullscreen = false;
  int _currentPage = 1;
  int _totalPages = 0;
  final bool _autoAdvance = false;

  @override
  void initState() {
    super.initState();
    _selectedElectionId = widget.electionId;
    _loadDeckFiles();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _loadDeckFiles() async {
    setState(() => _isLoading = true);

    if (_selectedElectionId != null) {
      final files = await _slidesService.getDeckFiles(
        electionId: _selectedElectionId!,
      );

      setState(() {
        _deckFiles = files;
        if (files.isNotEmpty) {
          _currentDeck = files.first;
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadDeck() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final deck = await _slidesService.uploadDeckFile(
            electionId: _selectedElectionId!,
            fileName: file.name,
            fileBytes: file.bytes!,
            fileType: 'pdf',
          );

          if (deck != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Presentation uploaded successfully'),
                backgroundColor: AppTheme.accentLight,
              ),
            );
            await _loadDeckFiles();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload presentation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
    });
  }

  void _previousSlide() {
    if (_currentPage > 1) {
      _pdfController.previousPage();
    }
  }

  void _nextSlide() {
    if (_currentPage < _totalPages) {
      _pdfController.nextPage();
    }
  }

  void _jumpToSlide(int pageNumber) {
    _pdfController.jumpToPage(pageNumber);
    setState(() => _showThumbnails = false);
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'PresentationSlidesViewer',
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _isFullscreen
            ? null
            : CustomAppBar(
                title: 'Presentation Slides',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    onPressed: _uploadDeck,
                  ),
                ],
              ),
        body: _isLoading
            ? _buildLoadingState()
            : _selectedElectionId == null
            ? _buildNoElectionState()
            : _currentDeck == null
            ? SlideUploadWidget(
                electionId: _selectedElectionId!,
                onUploaded: _loadDeckFiles,
              )
            : _buildSlideViewer(theme),
      ),
    );
  }

  Widget _buildSlideViewer(ThemeData theme) {
    return Column(
      children: [
        // Progress indicator
        if (!_isFullscreen) _buildProgressIndicator(theme),

        // PDF Viewer
        Expanded(
          child: Stack(
            children: [
              SfPdfViewer.network(
                _currentDeck!['file_url'] as String,
                controller: _pdfController,
                onPageChanged: _onPageChanged,
                onDocumentLoaded: _onDocumentLoaded,
                pageLayoutMode: PdfPageLayoutMode.single,
                scrollDirection: PdfScrollDirection.horizontal,
              ),

              // Thumbnails overlay
              if (_showThumbnails)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 30.w,
                  child: SlideThumbnailsWidget(
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    onPageSelected: _jumpToSlide,
                    onClose: () => setState(() => _showThumbnails = false),
                  ),
                ),
            ],
          ),
        ),

        // Speaker notes
        if (_showSpeakerNotes && !_isFullscreen)
          SpeakerNotesWidget(
            slideId: 'slide_$_currentPage',
            onClose: () => setState(() => _showSpeakerNotes = false),
          ),

        // Controls
        if (!_isFullscreen)
          SlideControlsWidget(
            currentPage: _currentPage,
            totalPages: _totalPages,
            onPrevious: _previousSlide,
            onNext: _nextSlide,
            onToggleThumbnails: () =>
                setState(() => _showThumbnails = !_showThumbnails),
            onToggleSpeakerNotes: () =>
                setState(() => _showSpeakerNotes = !_showSpeakerNotes),
            onToggleFullscreen: _toggleFullscreen,
            showThumbnails: _showThumbnails,
            showSpeakerNotes: _showSpeakerNotes,
          ),
      ],
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentDeck!['file_name'] as String? ?? 'Presentation',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                LinearProgressIndicator(
                  value: _totalPages > 0 ? _currentPage / _totalPages : 0,
                  backgroundColor: theme.colorScheme.outline.withValues(
                    alpha: 0.2,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            '$_currentPage / $_totalPages',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 40.h,
            width: 80.w,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(height: 2.h),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildNoElectionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.slideshow_outlined,
            size: 48.sp,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 2.h),
          Text(
            'No election selected',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
