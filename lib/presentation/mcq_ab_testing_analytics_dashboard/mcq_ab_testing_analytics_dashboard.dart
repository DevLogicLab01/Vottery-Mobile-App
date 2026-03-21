import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/ab_testing_service.dart';
import '../../widgets/custom_app_bar.dart';

class McqABTestingAnalyticsDashboard extends StatefulWidget {
  const McqABTestingAnalyticsDashboard({super.key});

  @override
  State<McqABTestingAnalyticsDashboard> createState() =>
      _McqABTestingAnalyticsDashboardState();
}

class _McqABTestingAnalyticsDashboardState
    extends State<McqABTestingAnalyticsDashboard> {
  bool _loading = false;
  List<Map<String, dynamic>> _experiments = const [];
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final experiments = await ABTestingService.instance.getExperiments();
      if (experiments.isEmpty) {
        if (!mounted) return;
        setState(() {
          _experiments = const [];
          _stats = null;
        });
        return;
      }

      Map<String, dynamic>? stats;
      final id = (experiments.first['id'] ?? '').toString();
      if (id.isNotEmpty) {
        stats = await ABTestingService.instance.calculateStatisticalSignificance(
          id,
        );
      }
      if (!mounted) return;
      setState(() {
        _experiments = experiments;
        _stats = stats;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load A/B testing analytics.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'MCQ A/B Testing Analytics',
        leading: Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (!_loading && _experiments.isEmpty)
            const Text('No A/B experiments found yet.'),
          if (_experiments.isNotEmpty)
            ..._experiments.take(10).map(
                  (e) => Card(
                    child: ListTile(
                      title: Text((e['name'] ?? 'Experiment').toString()),
                      subtitle: Text((e['description'] ?? '').toString()),
                      trailing: Text((e['status'] ?? 'unknown').toString()),
                    ),
                  ),
                ),
          SizedBox(height: 2.h),
          if (_stats != null) ...[
            Text(
              'Latest Statistical Summary',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text('Sample Size: ${_stats!['sample_size'] ?? 0}'),
            Text('p-value: ${_stats!['p_value'] ?? 'n/a'}'),
            Text('Significant: ${_stats!['is_significant'] == true ? 'Yes' : 'No'}'),
            Text('Winner Variant: ${_stats!['winner_id'] ?? 'n/a'}'),
            Text(
              'Improvement: ${((_stats!['improvement_percentage'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}%',
            ),
          ],
        ],
      ),
    );
  }
}
