import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:file_picker/file_picker.dart';

class TicketSubmissionFormWidget extends StatefulWidget {
  final Function(
    String category,
    String priority,
    String subject,
    String description,
  )
  onSubmit;

  const TicketSubmissionFormWidget({super.key, required this.onSubmit});

  @override
  State<TicketSubmissionFormWidget> createState() =>
      _TicketSubmissionFormWidgetState();
}

class _TicketSubmissionFormWidgetState
    extends State<TicketSubmissionFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'technical';
  String _selectedPriority = 'medium';
  final List<PlatformFile> _attachments = [];

  final List<Map<String, dynamic>> _categories = [
    {'value': 'technical', 'label': 'Technical', 'icon': Icons.computer},
    {'value': 'billing', 'label': 'Billing', 'icon': Icons.payment},
    {'value': 'election', 'label': 'Election', 'icon': Icons.how_to_vote},
    {'value': 'fraud', 'label': 'Fraud', 'icon': Icons.security},
    {'value': 'account', 'label': 'Account', 'icon': Icons.person},
    {'value': 'other', 'label': 'Other', 'icon': Icons.help},
  ];

  final List<Map<String, dynamic>> _priorities = [
    {'value': 'low', 'label': 'Low', 'color': Colors.blue},
    {'value': 'medium', 'label': 'Medium', 'color': Colors.orange},
    {'value': 'high', 'label': 'High', 'color': Colors.deepOrange},
    {'value': 'urgent', 'label': 'Urgent', 'color': Colors.red},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'mp4', 'mov'],
        allowMultiple: true,
      );

      if (result != null) {
        for (var file in result.files) {
          // Check file size (max 10MB)
          if (file.size > 10 * 1024 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${file.name} exceeds 10MB limit'),
                backgroundColor: Colors.red,
              ),
            );
            continue;
          }
          setState(() => _attachments.add(file));
        }
      }
    } catch (e) {
      debugPrint('Pick files error: $e');
    }
  }

  void _removeAttachment(int index) {
    setState(() => _attachments.removeAt(index));
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _selectedCategory,
        _selectedPriority,
        _subjectController.text,
        _descriptionController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Submit Support Ticket',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // Category Selection
              Text(
                'Category',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 2.h,
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['value'] as String,
                    child: Row(
                      children: [
                        Icon(category['icon'] as IconData, size: 5.w),
                        SizedBox(width: 2.w),
                        Text(category['label'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              SizedBox(height: 2.h),

              // Priority Selection
              Text(
                'Priority',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedPriority,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 2.h,
                  ),
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem<String>(
                    value: priority['value'] as String,
                    child: Row(
                      children: [
                        Container(
                          width: 3.w,
                          height: 3.w,
                          decoration: BoxDecoration(
                            color: priority['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(priority['label'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPriority = value!);
                },
              ),
              SizedBox(height: 2.h),

              // Subject
              Text(
                'Subject',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: 'Brief summary of your issue',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 2.h,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject';
                  }
                  if (value.length < 10) {
                    return 'Subject must be at least 10 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),

              // Description
              Text(
                'Description',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Provide detailed information about your issue',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 2.h,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),

              // File Attachments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attachments (Optional)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add Files'),
                  ),
                ],
              ),
              if (_attachments.isNotEmpty) ...[
                SizedBox(height: 1.h),
                ...List.generate(_attachments.length, (index) {
                  final file = _attachments[index];
                  return ListTile(
                    leading: Icon(Icons.insert_drive_file, size: 6.w),
                    title: Text(
                      file.name,
                      style: TextStyle(fontSize: 12.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${(file.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _removeAttachment(index),
                    ),
                  );
                }),
              ],
              SizedBox(height: 3.h),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    'Submit Ticket',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
