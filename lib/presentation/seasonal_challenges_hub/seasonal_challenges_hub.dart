import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeasonalChallengesHub extends StatefulWidget {
  const SeasonalChallengesHub({super.key});

  @override
  State<SeasonalChallengesHub> createState() => _SeasonalChallengesHubState();
}

class _SeasonalChallengesHubState extends State<SeasonalChallengesHub> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _challenges = [];

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now().toIso8601String();
      final rows = await Supabase.instance.client
          .from('seasonal_challenges')
          .select()
          .eq('is_active', true)
          .lte('starts_at', now)
          .gte('ends_at', now)
          .order('vp_reward', ascending: false);
      setState(() => _challenges = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      setState(() => _challenges = []);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seasonal Challenges')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _challenges.isEmpty
          ? Center(
              child: Text(
                'No active seasonal challenges',
                style: TextStyle(fontSize: 12.sp),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadChallenges,
              child: ListView.builder(
                padding: EdgeInsets.all(4.w),
                itemCount: _challenges.length,
                itemBuilder: (context, index) {
                  final item = _challenges[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['title']?.toString() ?? 'Challenge'),
                      subtitle: Text(item['description']?.toString() ?? ''),
                      trailing: Text('${item['vp_reward'] ?? 0} VP'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
