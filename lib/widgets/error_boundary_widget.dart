import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      }
    };
  }

  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }
      return FallbackErrorScreen(error: _error!, onRetry: _retry);
    }

    return widget.child;
  }
}

class FallbackErrorScreen extends StatefulWidget {
  final Object error;
  final VoidCallback onRetry;

  const FallbackErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  State<FallbackErrorScreen> createState() => _FallbackErrorScreenState();
}

class _FallbackErrorScreenState extends State<FallbackErrorScreen> {
  int _retryCount = 0;
  bool _isRetrying = false;

  Future<void> _handleRetryWithBackoff() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    widget.onRetry();
    await Future.delayed(Duration(seconds: 1 + (_retryCount.clamp(0, 3))));
    if (mounted) {
      setState(() {
        _retryCount++;
        _isRetrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 3.h),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                "We're working to fix this. Please try again.",
                style: TextStyle(fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                'Offline or degraded network? Check your connection.',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: _isRetrying ? null : _handleRetryWithBackoff,
                icon: _isRetrying
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isRetrying ? 'Retrying...' : 'Retry'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                ),
              ),
              SizedBox(height: 2.h),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}