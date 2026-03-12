import 'package:flutter/material.dart';

class AIConfigurationWidget extends StatelessWidget {
  final String selectedModel;
  final double creativity;
  final bool behavioralAnalysis;
  final Function(String) onModelChanged;
  final Function(double) onCreativityChanged;
  final Function(bool) onBehavioralAnalysisChanged;

  const AIConfigurationWidget({
    super.key,
    required this.selectedModel,
    required this.creativity,
    required this.behavioralAnalysis,
    required this.onModelChanged,
    required this.onCreativityChanged,
    required this.onBehavioralAnalysisChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
            Text(
              'AI Configuration',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'GPT Model',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8.0),
            DropdownButtonFormField<String>(
              initialValue: selectedModel,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'gpt-5',
                  child: Text('GPT-5 (Best Quality)'),
                ),
                DropdownMenuItem(
                  value: 'gpt-5-mini',
                  child: Text('GPT-5 Mini (Balanced)'),
                ),
                DropdownMenuItem(
                  value: 'gpt-5-nano',
                  child: Text('GPT-5 Nano (Fast)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) onModelChanged(value);
              },
            ),
            const SizedBox(height: 16.0),
            Text(
              'Creativity: ${(creativity * 100).toInt()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Slider(
              value: creativity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(creativity * 100).toInt()}%',
              onChanged: onCreativityChanged,
            ),
            const SizedBox(height: 8.0),
            SwitchListTile(
              title: Text(
                'Behavioral Analysis',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Analyze user voting history for personalization',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: behavioralAnalysis,
              onChanged: onBehavioralAnalysisChanged,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
