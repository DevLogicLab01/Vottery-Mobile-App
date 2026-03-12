import 'package:flutter/material.dart';
import '../../../widgets/custom_icon_widget.dart';

class GeneratedQuestCardWidget extends StatelessWidget {
  final Map<String, dynamic> quest;
  final VoidCallback onEdit;
  final VoidCallback onPublish;

  const GeneratedQuestCardWidget({
    super.key,
    required this.quest,
    required this.onEdit,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = quest['title'] as String? ?? 'Untitled Quest';
    final description = quest['description'] as String? ?? '';
    final difficulty = quest['difficulty'] as String? ?? 'medium';
    final vpReward = quest['vp_reward'] as int? ?? 0;
    final questType = quest['type'] as String? ?? 'voting';

    Color difficultyColor;
    switch (difficulty) {
      case 'easy':
        difficultyColor = Color(0xFF10B981);
        break;
      case 'hard':
        difficultyColor = Color(0xFFEF4444);
        break;
      default:
        difficultyColor = Color(0xFFF59E0B);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: difficultyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  difficulty.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: difficultyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  questType.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'stars',
                    color: Color(0xFFF59E0B),
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '$vpReward VP',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: CustomIconWidget(
                    iconName: 'edit',
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  label: Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPublish,
                  icon: CustomIconWidget(
                    iconName: 'publish',
                    color: theme.colorScheme.onPrimary,
                    size: 18,
                  ),
                  label: Text('Publish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
