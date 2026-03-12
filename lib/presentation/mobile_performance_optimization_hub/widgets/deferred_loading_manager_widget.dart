import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class DeferredLoadingManagerWidget extends StatefulWidget {
  const DeferredLoadingManagerWidget({super.key});

  @override
  State<DeferredLoadingManagerWidget> createState() =>
      _DeferredLoadingManagerWidgetState();
}

class _DeferredLoadingManagerWidgetState
    extends State<DeferredLoadingManagerWidget> {
  final Map<String, bool> _loadedLibraries = {
    'horizontal_carousel': false,
    'vertical_carousel': false,
    'gradient_carousel': false,
  };

  final Map<String, bool> _loadingLibraries = {
    'horizontal_carousel': false,
    'vertical_carousel': false,
    'gradient_carousel': false,
  };

  Future<void> _simulateLibraryLoad(String libraryKey) async {
    setState(() => _loadingLibraries[libraryKey] = true);
    // Simulate deferred loading
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _loadingLibraries[libraryKey] = false;
      _loadedLibraries[libraryKey] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers, color: const Color(0xFF3B82F6), size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Deferred Loading Manager',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Carousel libraries loaded on-demand to reduce initial bundle size',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildLibraryCard(
            theme,
            key: 'horizontal_carousel',
            name: 'Horizontal Snap Carousel',
            description: 'horizontal_snap_carousel_widget.dart',
            icon: Icons.view_carousel,
            color: const Color(0xFF3B82F6),
          ),
          SizedBox(height: 1.h),
          _buildLibraryCard(
            theme,
            key: 'vertical_carousel',
            name: 'Vertical Card Stack',
            description: 'vertical_card_stack_widget.dart',
            icon: Icons.view_agenda,
            color: const Color(0xFF8B5CF6),
          ),
          SizedBox(height: 1.h),
          _buildLibraryCard(
            theme,
            key: 'gradient_carousel',
            name: 'Gradient Flow Carousel',
            description: 'gradient_flow_carousel_widget.dart',
            icon: Icons.gradient,
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryCard(
    ThemeData theme, {
    required String key,
    required String name,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isLoaded = _loadedLibraries[key] ?? false;
    final isLoading = _loadingLibraries[key] ?? false;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isLoaded
              ? color.withAlpha(77)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 5.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 4.w,
                  height: 4.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                SizedBox(width: 1.w),
                Text(
                  'Loading...',
                  style: GoogleFonts.inter(fontSize: 9.sp, color: color),
                ),
              ],
            )
          else if (isLoaded)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: color, size: 4.w),
                SizedBox(width: 1.w),
                Text(
                  'Loaded',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            )
          else
            TextButton(
              onPressed: () => _simulateLibraryLoad(key),
              style: TextButton.styleFrom(foregroundColor: color),
              child: Text(
                'Load',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
