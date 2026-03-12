import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../services/sentry_integration_service.dart';
import '../services/error_tracking_service.dart';

class ErrorBoundaryWrapper extends StatefulWidget {
  final Widget child;
  final String screenName;
  final VoidCallback? onRetry;

  const ErrorBoundaryWrapper({
    super.key,
    required this.child,
    required this.screenName,
    this.onRetry,
  });

  @override
  State<ErrorBoundaryWrapper> createState() => _ErrorBoundaryWrapperState();
}

class _ErrorBoundaryWrapperState extends State<ErrorBoundaryWrapper> {
  bool _hasError = false;
  String _errorMessage = '';
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack);
    };
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    setState(() {
      _hasError = true;
      _errorMessage = error.toString();
    });

    // Log to Sentry
    SentryIntegrationService.instance.trackErrorIncident(
      errorType: 'runtime_error',
      severity: 'high',
      errorMessage: error.toString(),
      affectedFeature: widget.screenName,
      stackTrace: stackTrace?.toString(),
      userContext: {'screen': widget.screenName},
    );

    ErrorTrackingService.instance.captureException(
      error.toString(),
      context: widget.screenName,
      extras: {'stack_trace': stackTrace?.toString()},
    );
  }

  Future<void> _retry() async {
    setState(() {
      _isRetrying = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isRetrying = false;
    });

    if (widget.onRetry != null) {
      widget.onRetry!();
    }
  }

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack);
      return const SizedBox.shrink();
    };

    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80.0,
                    color: Colors.red.shade400,
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'We\'ve logged this error and will fix it soon.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  ElevatedButton.icon(
                    onPressed: _isRetrying ? null : _retry,
                    icon: _isRetrying
                        ? SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(Icons.refresh),
                    label: Text(
                      _isRetrying ? 'Retrying...' : 'Try Again',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 1.5.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
