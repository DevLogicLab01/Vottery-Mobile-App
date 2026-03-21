import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/openai_quest_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Quest Management Dashboard for creating, assigning, and tracking quests
class QuestManagementDashboard extends StatefulWidget {
  const QuestManagementDashboard({super.key});

  @override
  State<QuestManagementDashboard> createState() =>
      _QuestManagementDashboardState();
}

class _QuestManagementDashboardState extends State<QuestManagementDashboard>
    with SingleTickerProviderStateMixin {
  final OpenAIQuestService _questService = OpenAIQuestService.instance;
  late TabController _tabController;
  bool _isLoading = false;

  List<Map<String, dynamic>> _activeQuests = [];

  Future<void> _loadQuests() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _activeQuests = []);
        return;
      }

      final quests = await Supabase.instance.client
          .from('user_quests')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      setState(() {
        _activeQuests = List<Map<String, dynamic>>.from(quests);
      });
    } catch (_) {
      // Fallback to AI-generated quests so the dashboard is never empty.
      final user = Supabase.instance.client.auth.currentUser;
      final fallback = user == null
          ? <Map<String, dynamic>>[]
          : await _questService.generatePersonalizedQuests(userId: user.id);
      setState(() => _activeQuests = fallback);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'QuestManagementDashboard',
      onRetry: _loadQuests,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Quest Management',
          variant: CustomAppBarVariant.withBack,
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 6)
            : _activeQuests.isEmpty
            ? NoDataEmptyState(
                title: 'No Quests Available',
                description:
                    'Complete quests to earn rewards and level up your profile!',
                onRefresh: _loadQuests,
              )
            : RefreshIndicator(
                onRefresh: _loadQuests,
                child: ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _activeQuests.length,
                  itemBuilder: (context, index) => Card(
                    child: ListTile(
                      title: Text(_activeQuests[index]['title']),
                      subtitle: Text(
                        '${_activeQuests[index]['vp_reward'] ?? 0} VP • ${_activeQuests[index]['difficulty'] ?? 'easy'}',
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
