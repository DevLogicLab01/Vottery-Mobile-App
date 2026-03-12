import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DecisionFormDialogWidget extends StatefulWidget {
  final String workspaceId;
  final Function(Map<String, dynamic>) onSubmit;

  const DecisionFormDialogWidget({
    super.key,
    required this.workspaceId,
    required this.onSubmit,
  });

  @override
  State<DecisionFormDialogWidget> createState() =>
      _DecisionFormDialogWidgetState();
}

class _DecisionFormDialogWidgetState extends State<DecisionFormDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contextController = TextEditingController();
  final _impactController = TextEditingController();
  DateTime? _targetDate;
  bool _approvalRequired = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contextController.dispose();
    _impactController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit({
        'title': _titleController.text.trim(),
        'context': _contextController.text.trim(),
        'expected_impact': _impactController.text.trim(),
        'target_date': _targetDate?.toIso8601String(),
        'approval_required': _approvalRequired,
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
                  'Add Decision',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Decision Title',
                    hintText: 'e.g., Implement new analytics feature',
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
                TextFormField(
                  controller: _contextController,
                  decoration: InputDecoration(
                    labelText: 'Decision Context',
                    hintText: 'Explain the situation...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: _impactController,
                  decoration: InputDecoration(
                    labelText: 'Expected Impact',
                    hintText: 'Describe anticipated outcomes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 2.h),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Target Date'),
                  subtitle: Text(
                    _targetDate != null
                        ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                        : 'Not set',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _targetDate = date);
                      }
                    },
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Approval Required'),
                  value: _approvalRequired,
                  onChanged: (value) {
                    setState(() => _approvalRequired = value ?? false);
                  },
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
                      child: const Text('Submit for Review'),
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
