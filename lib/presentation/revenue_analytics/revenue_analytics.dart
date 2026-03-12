import 'package:flutter/material.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

class RevenueAnalyticsScreen extends StatelessWidget {
  const RevenueAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'RevenueAnalytics',
      onRetry: () {}, // Fixed: Changed from _loadData to empty function
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Revenue Analytics',
          variant: CustomAppBarVariant.withBack,
        ),
        body: Center(child: Text('Revenue Analytics Dashboard')),
      ),
    );
  }
}
