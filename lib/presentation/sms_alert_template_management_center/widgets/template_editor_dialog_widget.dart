import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TemplateEditorDialogWidget extends StatefulWidget {
  final Map<String, dynamic>? template;
  final Function(Map<String, dynamic>) onSave;

  const TemplateEditorDialogWidget({
    super.key,
    this.template,
    required this.onSave,
  });

  @override
  State<TemplateEditorDialogWidget> createState() =>
      _TemplateEditorDialogWidgetState();
}

class _TemplateEditorDialogWidgetState
    extends State<TemplateEditorDialogWidget> {
  late TextEditingController _nameController;
  late TextEditingController _messageController;
  String _selectedCategory = 'fraud';
  String _selectedPriority = 'medium';
  final List<String> _availableVariables = [
    '{system_name}',
    '{user_id}',
    '{confidence}',
    '{amount}',
    '{percentage}',
    '{metric_name}',
    '{current_value}',
    '{baseline_value}',
    '{eta_minutes}',
    '{dashboard_url}',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.template?['template_name'] as String? ?? '',
    );
    _messageController = TextEditingController(
      text: widget.template?['message_body'] as String? ?? '',
    );
    _selectedCategory = widget.template?['category'] as String? ?? 'fraud';
    _selectedPriority = widget.template?['priority'] as String? ?? 'medium';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _insertVariable(String variable) {
    final currentText = _messageController.text;
    final selection = _messageController.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      variable,
    );
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + variable.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 90.w,
        constraints: BoxConstraints(maxHeight: 80.h),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.template == null ? 'New Template' : 'Edit Template',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Template Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                                'fraud',
                                'system_outage',
                                'performance_degradation',
                                'anomaly_detection',
                                'security',
                                'operational',
                              ]
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(
                                    cat.replaceAll('_', ' ').toUpperCase(),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value!);
                      },
                    ),
                    SizedBox(height: 2.h),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: ['critical', 'high', 'medium', 'low']
                          .map(
                            (pri) => DropdownMenuItem(
                              value: pri,
                              child: Text(pri.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedPriority = value!);
                      },
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Message Body',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextField(
                      controller: _messageController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Enter message with {variables}',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Available Variables (tap to insert)',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: _availableVariables
                          .map(
                            (variable) => ActionChip(
                              label: Text(
                                variable,
                                style: TextStyle(fontSize: 10.sp),
                              ),
                              onPressed: () => _insertVariable(variable),
                              backgroundColor: Colors.blue.withAlpha(26),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                SizedBox(width: 2.w),
                ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isEmpty ||
                        _messageController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    widget.onSave({
                      'template_name': _nameController.text,
                      'category': _selectedCategory,
                      'message_body': _messageController.text,
                      'priority': _selectedPriority,
                      'variables': [],
                    });
                  },
                  child: const Text('Save Template'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
