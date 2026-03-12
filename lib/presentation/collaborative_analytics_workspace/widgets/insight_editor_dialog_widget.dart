import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class InsightEditorDialogWidget extends StatefulWidget {
  final String workspaceId;
  final Function(Map<String, dynamic>) onSubmit;

  const InsightEditorDialogWidget({
    super.key,
    required this.workspaceId,
    required this.onSubmit,
  });

  @override
  State<InsightEditorDialogWidget> createState() =>
      _InsightEditorDialogWidgetState();
}

class _InsightEditorDialogWidgetState extends State<InsightEditorDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _category = 'performance';
  String _confidenceLevel = 'medium';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _category,
        'confidence_level': _confidenceLevel,
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
                  'Document Insight',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Insight Title',
                    hintText: 'e.g., User engagement increased 25%',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 2.h),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  items:
                      [
                        'performance',
                        'security',
                        'revenue',
                        'user_behavior',
                        'engagement',
                        'technical',
                      ].map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.replaceAll('_', ' ').toUpperCase()),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'Insight Content',
                    hintText: 'Describe your findings...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter insight content';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 2.h),
                Text('Confidence Level', style: theme.textTheme.titleSmall),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  children: ['low', 'medium', 'high'].map((level) {
                    final isSelected = level == _confidenceLevel;
                    return ChoiceChip(
                      label: Text(level.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _confidenceLevel = level);
                        }
                      },
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
                      child: const Text('Save Insight'),
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
