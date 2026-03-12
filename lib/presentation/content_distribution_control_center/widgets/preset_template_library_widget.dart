import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PresetTemplateLibraryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> templates;
  final Function(Map<String, dynamic>) onTemplateApplied;

  const PresetTemplateLibraryWidget({
    super.key,
    required this.templates,
    required this.onTemplateApplied,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _buildHeader(context),
        SizedBox(height: 2.h),
        ...templates.map((template) => _buildTemplateCard(context, template)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preset Template Library',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Apply optimized content distribution configurations with one click',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    Map<String, dynamic> template,
  ) {
    final theme = Theme.of(context);
    final color = template['color'] as Color;

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => onTemplateApplied(template),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      template['icon'] as IconData,
                      color: color,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template['name'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          template['description'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _buildDistributionPreview(
                context,
                template['election'].toDouble(),
                template['social'].toDouble(),
                template['ad'].toDouble(),
              ),
              SizedBox(height: 1.5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPercentageChip(
                    'Election',
                    template['election'].toDouble(),
                    Colors.purple,
                  ),
                  _buildPercentageChip(
                    'Social',
                    template['social'].toDouble(),
                    Colors.blue,
                  ),
                  _buildPercentageChip(
                    'Ads',
                    template['ad'].toDouble(),
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistributionPreview(
    BuildContext context,
    double election,
    double social,
    double ad,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribution Preview',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Row(
            children: [
              if (election > 0)
                Expanded(
                  flex: election.toInt(),
                  child: Container(height: 24, color: Colors.purple),
                ),
              if (social > 0)
                Expanded(
                  flex: social.toInt(),
                  child: Container(height: 24, color: Colors.blue),
                ),
              if (ad > 0)
                Expanded(
                  flex: ad.toInt(),
                  child: Container(height: 24, color: Colors.green),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageChip(String label, double percentage, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 1.w),
          Text(
            '$label ${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
