import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AnnotationDialogWidget extends StatefulWidget {
  final Map<String, dynamic> dataPoint;
  final String chartId;
  final String dashboardId;

  const AnnotationDialogWidget({
    super.key,
    required this.dataPoint,
    required this.chartId,
    required this.dashboardId,
  });

  @override
  State<AnnotationDialogWidget> createState() => _AnnotationDialogWidgetState();
}

class _AnnotationDialogWidgetState extends State<AnnotationDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  String _annotationType = 'insight';
  String _priority = 'medium';
  Color _selectedColor = const Color(0xFFFF6B6B);

  final List<Map<String, dynamic>> _annotationTypes = [
    {'value': 'insight', 'label': 'Insight', 'icon': Icons.lightbulb_outline},
    {'value': 'question', 'label': 'Question', 'icon': Icons.help_outline},
    {
      'value': 'decision',
      'label': 'Decision',
      'icon': Icons.check_circle_outline,
    },
    {'value': 'action_item', 'label': 'Action Item', 'icon': Icons.task_alt},
    {'value': 'warning', 'label': 'Warning', 'icon': Icons.warning_amber},
  ];

  final List<Map<String, dynamic>> _priorities = [
    {'value': 'low', 'label': 'Low', 'color': Colors.green},
    {'value': 'medium', 'label': 'Medium', 'color': Colors.orange},
    {'value': 'high', 'label': 'High', 'color': Colors.red},
    {'value': 'critical', 'label': 'Critical', 'color': Colors.purple},
  ];

  final List<Color> _colors = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFE66D),
    const Color(0xFF95E1D3),
    const Color(0xFFF38181),
    const Color(0xFFAA96DA),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'annotation_text': _textController.text.trim(),
        'annotation_type': _annotationType,
        'priority': _priority,
        'color': '#${_selectedColor.value.toRadixString(16).substring(2)}',
        'data_point_identifier': widget.dataPoint,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        padding: EdgeInsets.all(6.w),
        constraints: BoxConstraints(maxHeight: 80.h),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Annotation',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                Text('Annotation Type', style: theme.textTheme.titleSmall),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: _annotationTypes.map((type) {
                    final isSelected = type['value'] == _annotationType;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            size: 4.w,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 1.w),
                          Text(type['label'] as String),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                            () => _annotationType = type['value'] as String,
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 3.h),
                TextFormField(
                  controller: _textController,
                  decoration: InputDecoration(
                    labelText: 'Annotation Text',
                    hintText: 'Describe your observation...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter annotation text';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 3.h),
                Text('Priority', style: theme.textTheme.titleSmall),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: _priorities.map((priority) {
                    final isSelected = priority['value'] == _priority;
                    return ChoiceChip(
                      label: Text(priority['label'] as String),
                      selected: isSelected,
                      selectedColor: priority['color'] as Color,
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                            () => _priority = priority['value'] as String,
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 3.h),
                Text('Marker Color', style: theme.textTheme.titleSmall),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: _colors.map((color) {
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: Colors.white, size: 5.w)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 3.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    SizedBox(width: 2.w),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Add Annotation'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
