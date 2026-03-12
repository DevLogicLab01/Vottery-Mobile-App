import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/error_recovery_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';

enum ErrorType {
  network,
  server,
  authentication,
  validation,
  notFound,
  permission,
}

class GlobalErrorRecoveryCenter extends StatefulWidget {
  const GlobalErrorRecoveryCenter({super.key});

  @override
  State<GlobalErrorRecoveryCenter> createState() =>
      _GlobalErrorRecoveryCenterState();
}

class _GlobalErrorRecoveryCenterState extends State<GlobalErrorRecoveryCenter> {
  final ErrorRecoveryService _errorRecovery = ErrorRecoveryService();
  bool _hasNetworkConnection = true;
  bool _isCheckingConnection = false;

  @override
  void initState() {
    super.initState();
    _checkNetworkStatus();
  }

  Future<void> _checkNetworkStatus() async {
    setState(() => _isCheckingConnection = true);
    // Simulate network check - replace with actual implementation
    await Future.delayed(Duration(seconds: 1));
    final hasConnection = true; // Replace with actual network check logic
    setState(() {
      _hasNetworkConnection = hasConnection;
      _isCheckingConnection = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'GlobalErrorRecoveryCenter',
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Error Recovery Center',
            variant: CustomAppBarVariant.standard,
            leading: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                color: theme.appBarTheme.foregroundColor!,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Network Status Card
              _buildNetworkStatusCard(theme),
              SizedBox(height: 2.h),

              // Error States Section
              Text(
                'Common Error States',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 1.h),

              // Error State Examples
              _buildErrorStateCard(
                theme,
                ErrorType.network,
                Icons.wifi_off,
                Colors.orange,
              ),
              SizedBox(height: 1.h),
              _buildErrorStateCard(
                theme,
                ErrorType.server,
                Icons.cloud_off,
                Colors.red,
              ),
              SizedBox(height: 1.h),
              _buildErrorStateCard(
                theme,
                ErrorType.authentication,
                Icons.lock_outline,
                Colors.purple,
              ),
              SizedBox(height: 1.h),
              _buildErrorStateCard(
                theme,
                ErrorType.validation,
                Icons.warning_amber,
                Colors.amber,
              ),
              SizedBox(height: 1.h),
              _buildErrorStateCard(
                theme,
                ErrorType.notFound,
                Icons.search_off,
                Colors.grey,
              ),
              SizedBox(height: 1.h),
              _buildErrorStateCard(
                theme,
                ErrorType.permission,
                Icons.block,
                Colors.red.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatusCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _hasNetworkConnection ? Icons.wifi : Icons.wifi_off,
                  color: _hasNetworkConnection ? Colors.green : Colors.red,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Network Status',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isCheckingConnection)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20),
                    onPressed: _checkNetworkStatus,
                  ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              _hasNetworkConnection
                  ? 'Connected to internet'
                  : 'No internet connection',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
            if (!_hasNetworkConnection) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Using cached data. Some features may be limited.',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorStateCard(
    ThemeData theme,
    ErrorType errorType,
    IconData icon,
    Color color,
  ) {
    // Get user-friendly message based on error type
    final message = _getUserFriendlyMessage(errorType);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorType.toString().split('.').last.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUserFriendlyMessage(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
        return 'Unable to connect to the network. Please check your internet connection.';
      case ErrorType.server:
        return 'Server error occurred. Please try again later.';
      case ErrorType.authentication:
        return 'Authentication failed. Please login again.';
      case ErrorType.validation:
        return 'Validation error. Please check your input.';
      case ErrorType.notFound:
        return 'The requested resource was not found.';
      case ErrorType.permission:
        return 'You do not have permission to access this resource.';
    }
  }
}
