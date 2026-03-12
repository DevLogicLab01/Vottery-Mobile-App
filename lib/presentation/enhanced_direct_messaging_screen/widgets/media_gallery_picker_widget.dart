import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MediaGalleryPickerWidget extends StatefulWidget {
  final Function(List<String> mediaUrls) onMediaSelected;

  const MediaGalleryPickerWidget({super.key, required this.onMediaSelected});

  @override
  State<MediaGalleryPickerWidget> createState() =>
      _MediaGalleryPickerWidgetState();
}

class _MediaGalleryPickerWidgetState extends State<MediaGalleryPickerWidget> {
  List<String> _selectedMedia = [];
  bool _isLoading = false;

  Future<void> _pickMedia() async {
    setState(() => _isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: true,
      );

      if (result != null) {
        final mediaUrls = result.files.map((file) {
          if (kIsWeb) {
            return 'data:image/jpeg;base64,${file.bytes}';
          } else {
            return file.path ?? '';
          }
        }).toList();

        setState(() => _selectedMedia = mediaUrls);
      }
    } catch (e) {
      debugPrint('Pick media error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 70.h,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.dialogBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(1.w),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Media Gallery',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedMedia.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildMediaGrid(theme),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickMedia,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Select Media'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
                if (_selectedMedia.isNotEmpty) ...[
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onMediaSelected(_selectedMedia),
                      icon: const Icon(Icons.send),
                      label: Text('Send (${_selectedMedia.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 20.w,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'No media selected',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Tap "Select Media" to choose images or videos',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(ThemeData theme) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.w,
      ),
      itemCount: _selectedMedia.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3.w),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 10.w,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Positioned(
              top: 1.w,
              right: 1.w,
              child: IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.error),
                onPressed: () {
                  setState(() => _selectedMedia.removeAt(index));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
