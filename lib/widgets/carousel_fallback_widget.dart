import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../services/carousel_fallback_service.dart';

/// Carousel Fallback Widget
/// Wraps carousel widgets with error boundary and graceful degradation
class CarouselWithFallback extends StatefulWidget {
  final Widget Function() carouselBuilder;
  final List<Map<String, dynamic>> items;
  final String carouselType;
  final Widget Function(Map<String, dynamic> item)? itemBuilder;

  const CarouselWithFallback({
    super.key,
    required this.carouselBuilder,
    required this.items,
    required this.carouselType,
    this.itemBuilder,
  });

  @override
  State<CarouselWithFallback> createState() => _CarouselWithFallbackState();
}

class _CarouselWithFallbackState extends State<CarouselWithFallback> {
  final _fallbackService = CarouselFallbackService.instance;
  bool _useFallback = false;

  @override
  void initState() {
    super.initState();
    _useFallback =
        !_fallbackService.supportsAdvancedCarousels ||
        _fallbackService.hasCarouselFailed(widget.carouselType);
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback) {
      return _buildFallbackView();
    }

    return _ErrorBoundaryWidget(
      onError: (error) {
        _fallbackService.recordRenderFailure(widget.carouselType, error);
        if (mounted) setState(() => _useFallback = true);
      },
      child: widget.carouselBuilder(),
    );
  }

  Widget _buildFallbackView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Simplified view for better performance',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.items.length,
          itemBuilder: (ctx, i) {
            final item = widget.items[i];
            if (widget.itemBuilder != null) {
              return widget.itemBuilder!(item);
            }
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
              child: ListTile(
                title: Text(
                  item['title'] as String? ??
                      item['name'] as String? ??
                      'Item ${i + 1}',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: item['description'] != null
                    ? Text(
                        item['description'] as String,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      )
                    : null,
                leading: const Icon(Icons.article),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Simple error boundary widget
class _ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;
  final void Function(Object error) onError;

  const _ErrorBoundaryWidget({required this.child, required this.onError});

  @override
  State<_ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<_ErrorBoundaryWidget> {
  final bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) return const SizedBox.shrink();
    return widget.child;
  }
}
