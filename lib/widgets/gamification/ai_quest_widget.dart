import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/openai_service.dart';
import '../../services/vp_service.dart';
import '../../models/quest.dart';
import '../../widgets/custom_icon_widget.dart';
import './quest_tile_widget.dart';

class AIQuestWidget extends StatefulWidget {
  const AIQuestWidget({super.key});

  @override
  State<AIQuestWidget> createState() => _AIQuestWidgetState();
}

class _AIQuestWidgetState extends State<AIQuestWidget> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final VPService _vpService = VPService.instance;

  List<Quest> dailyQuests = [];
  List<Quest> weeklyQuests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersonalizedQuests();
  }

  Future<void> _loadPersonalizedQuests() async {
    setState(() => _isLoading = true);

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        final quests = await OpenAIService.generatePersonalizedQuests(
          userId: userId,
          difficulty: 'adaptive',
        );

        if (mounted) {
          setState(() {
            dailyQuests = quests.where((q) => q.type == 'daily').toList();
            weeklyQuests = quests.where((q) => q.type == 'weekly').toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading quests: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeQuest(Quest quest) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('user_quests')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', quest.id);

      await _vpService.awardChallengeVP(quest.vpReward, quest.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quest completed! +${quest.vpReward} VP earned'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPersonalizedQuests();
      }
    } catch (e) {
      debugPrint('Error completing quest: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete quest'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const CustomIconWidget(
              iconName: 'emoji_events',
              color: Color(0xFFFFD700),
              size: 28,
            ),
            title: Text(
              'AI-Generated Quests',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Personalized challenges powered by GPT-5',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              onPressed: _isLoading ? null : _loadPersonalizedQuests,
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8.w),
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          else
            _buildQuestTabs(theme),
        ],
      ),
    );
  }

  Widget _buildQuestTabs(ThemeData theme) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            tabs: [
              Tab(text: 'Daily (${dailyQuests.length})'),
              Tab(text: 'Weekly (${weeklyQuests.length})'),
            ],
          ),
          SizedBox(
            height: 50.h,
            child: TabBarView(
              children: [
                _buildQuestList(dailyQuests),
                _buildQuestList(weeklyQuests),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestList(List<Quest> quests) {
    if (quests.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CustomIconWidget(
                iconName: 'inbox',
                color: Colors.grey,
                size: 48,
              ),
              SizedBox(height: 2.h),
              Text(
                'No quests available',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
              SizedBox(height: 1.h),
              Text(
                'Check back later for new challenges',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        return QuestTileWidget(
          quest: quest,
          onComplete: () => _completeQuest(quest),
        );
      },
    );
  }
}
