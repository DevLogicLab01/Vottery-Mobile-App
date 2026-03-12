import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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
  final bool _isLoading = false;

  final List<Map<String, dynamic>> _activeQuests = [
    {
      'id': 'quest_1',
      'title': 'Vote in 3 Elections',
      'type': 'voting',
      'difficulty': 'easy',
      'vp_reward': 150,
      'progress': 2,
      'target': 3,
      'assigned_users': 45,
      'completion_rate': 68.5,
    },
  ];

  Future<void> _loadQuests() async {
    // TODO: Implement quest loading logic
    setState(() {});
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
                      subtitle: Text('${_activeQuests[index]['vp_reward']} VP'),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
