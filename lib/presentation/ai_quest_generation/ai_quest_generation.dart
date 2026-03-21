import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/auth_service.dart';
import '../../services/openai_quest_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/ai_configuration_widget.dart';
import './widgets/ai_processing_indicator_widget.dart';
import './widgets/generated_quest_card_widget.dart';
import './widgets/quest_parameters_widget.dart';

/// AI Quest Generation Screen
/// Enables administrators to create personalized voting quests using OpenAI GPT-5
class AIQuestGeneration extends StatefulWidget {
  const AIQuestGeneration({super.key});

  @override
  State<AIQuestGeneration> createState() => _AIQuestGenerationState();
}

class _AIQuestGenerationState extends State<AIQuestGeneration> {
  final OpenAIQuestService _questService = OpenAIQuestService.instance;
  final AuthService _auth = AuthService.instance;

  String _selectedQuestType = 'daily';
  String _selectedDifficulty = 'medium';
  int _vpReward = 200;
  int _questCount = 3;
  String _selectedModel = 'gpt-5-mini';
  double _creativity = 0.7;
  bool _behavioralAnalysis = true;

  bool _isGenerating = false;
  List<Map<String, dynamic>> _generatedQuests = [];
  String? _errorMessage;

  // Remove this method - it's causing the error
  // Future<void> _loadQuests() async {
  //   await _generateQuests();
  // }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AIQuestGeneration',
      onRetry: _generateQuests,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'AI Quest Generation',
            variant: CustomAppBarVariant.standard,
            leading: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                color: Theme.of(context).appBarTheme.foregroundColor!,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'info',
                  color: Theme.of(context).appBarTheme.foregroundColor!,
                  size: 24,
                ),
                onPressed: () => _showInfoDialog(context),
              ),
            ],
          ),
        ),
        body: _isGenerating
            ? const SkeletonList(itemCount: 5)
            : _generatedQuests.isEmpty
            ? NoDataEmptyState(
                title: 'No Generated Quests',
                description:
                    'Use AI to generate personalized quests based on your interests.',
                onRefresh: _generateQuests,
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isGenerating) AIProcessingIndicatorWidget(),
                    SizedBox(height: 2.h),
                    _buildHeader(context),
                    SizedBox(height: 2.h),
                    QuestParametersWidget(
                      selectedQuestType: _selectedQuestType,
                      selectedDifficulty: _selectedDifficulty,
                      vpReward: _vpReward,
                      questCount: _questCount,
                      onQuestTypeChanged: (value) {
                        setState(() => _selectedQuestType = value);
                      },
                      onDifficultyChanged: (value) {
                        setState(() => _selectedDifficulty = value);
                      },
                      onVPRewardChanged: (value) {
                        setState(() => _vpReward = value.round());
                      },
                      onQuestCountChanged: (value) {
                        setState(() => _questCount = value.round());
                      },
                    ),
                    SizedBox(height: 2.h),
                    AIConfigurationWidget(
                      selectedModel: _selectedModel,
                      creativity: _creativity,
                      behavioralAnalysis: _behavioralAnalysis,
                      onModelChanged: (value) {
                        setState(() => _selectedModel = value);
                      },
                      onCreativityChanged: (value) {
                        setState(() => _creativity = value);
                      },
                      onBehavioralAnalysisChanged: (value) {
                        setState(() => _behavioralAnalysis = value);
                      },
                    ),
                    SizedBox(height: 2.h),
                    _buildActionButtons(context),
                    SizedBox(height: 2.h),
                    if (_errorMessage != null) _buildErrorMessage(context),
                    if (_generatedQuests.isNotEmpty)
                      _buildGeneratedQuests(context),
                    SizedBox(height: 3.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'psychology',
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quest Creation Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'OpenAI GPT-5 • Behavioral Analysis',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Active',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateQuests,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isGenerating)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  else
                    CustomIconWidget(
                      iconName: 'auto_awesome',
                      color: theme.colorScheme.onPrimary,
                      size: 24,
                    ),
                  SizedBox(width: 2.w),
                  Text(
                    _isGenerating ? 'Generating...' : 'Generate Quests',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _generatedQuests.isEmpty
                      ? null
                      : () => _showQuestPreviewDialog(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Preview'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: _generatedQuests.isEmpty
                      ? null
                      : () => _saveQuestTemplate(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Save Template'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'error',
              color: const Color(0xFFEF4444),
              size: 24,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedQuests(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generated Quests (${_generatedQuests.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ..._generatedQuests.map(
            (quest) => GeneratedQuestCardWidget(
              quest: quest,
              onEdit: () => _editQuest(context, quest),
              onPublish: () => _publishQuest(context, quest),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateQuests() async {
    if (!_auth.isAuthenticated) {
      setState(() {
        _errorMessage = 'Authentication required to generate quests';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedQuests = [];
    });

    try {
      final quests = await _questService.generatePersonalizedQuests(
        userId: _auth.currentUser!.id,
        questType: _selectedQuestType,
      );

      setState(() {
        _generatedQuests = quests;
        _isGenerating = false;
      });

      if (quests.isEmpty) {
        setState(() {
          _errorMessage = 'No quests generated. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Failed to generate quests: ${e.toString()}';
      });
    }
  }

  void _showInfoDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AI Quest Generation'),
        content: Text(
          'Generate personalized voting quests using OpenAI GPT-5 with behavioral analysis and difficulty scaling. Quests are tailored to user voting history and engagement patterns.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showQuestPreviewDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.all(4.w),
          itemCount: _generatedQuests.length,
          itemBuilder: (context, index) {
            final q = _generatedQuests[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(q['title']?.toString() ?? 'Untitled Quest'),
              subtitle: Text(q['description']?.toString() ?? ''),
              trailing: Text('${q['vp_reward'] ?? 0} VP'),
            );
          },
        ),
      ),
    );
  }

  void _saveQuestTemplate(BuildContext context) {
    if (!_auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in required to save template')),
      );
      return;
    }
    final template = {
      'quest_type': _selectedQuestType,
      'difficulty': _selectedDifficulty,
      'quest_count': _questCount,
      'vp_reward': _vpReward,
      'model': _selectedModel,
      'creativity': _creativity,
      'behavioral_analysis': _behavioralAnalysis,
      'saved_at': DateTime.now().toIso8601String(),
    };
    _questService
        .saveQuestTemplate(userId: _auth.currentUser!.id, template: template)
        .then((saved) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                saved
                    ? 'Template saved: ${template['quest_type']} / ${template['difficulty']}'
                    : 'Could not save template',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
  }

  Future<void> _editQuest(BuildContext context, Map<String, dynamic> quest) async {
    final titleController = TextEditingController(
      text: quest['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: quest['description']?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Quest'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final nextTitle = titleController.text.trim();
              final nextDescription = descriptionController.text.trim();
              var saved = true;
              if (quest['id'] != null) {
                saved = await _questService.updateQuestById(
                  questId: quest['id'].toString(),
                  updates: {
                    'title': nextTitle,
                    'description': nextDescription,
                  },
                );
              }
              if (!context.mounted) return;
              if (saved) {
                setState(() {
                  quest['title'] = nextTitle;
                  quest['description'] = nextDescription;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not save quest edits')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
  }

  void _publishQuest(BuildContext context, Map<String, dynamic> quest) {
    final id = quest['id']?.toString();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quest must be generated before publishing')),
      );
      return;
    }
    _questService.publishQuestById(id).then((published) {
      if (!context.mounted) return;
      if (published) {
        setState(() {
          quest['status'] = 'active';
          quest['published_at'] = DateTime.now().toIso8601String();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            published
                ? 'Published quest: ${quest['title'] ?? 'Untitled Quest'}'
                : 'Could not publish quest',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}
