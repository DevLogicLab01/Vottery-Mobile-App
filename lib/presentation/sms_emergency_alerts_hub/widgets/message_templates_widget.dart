import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/sms_alerts_service.dart';

class MessageTemplatesWidget extends StatefulWidget {
  final List<Map<String, dynamic>> templates;
  final VoidCallback onTemplatesChanged;

  const MessageTemplatesWidget({
    super.key,
    required this.templates,
    required this.onTemplatesChanged,
  });

  @override
  State<MessageTemplatesWidget> createState() => _MessageTemplatesWidgetState();
}

class _MessageTemplatesWidgetState extends State<MessageTemplatesWidget> {
  void _showAddTemplateDialog() {
    final nameController = TextEditingController();
    final messageController = TextEditingController();
    String selectedAlertType = 'fraud';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Message Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Template Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 2.h),
                DropdownButtonFormField<String>(
                  initialValue: selectedAlertType,
                  decoration: const InputDecoration(
                    labelText: 'Alert Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'fraud', child: Text('Fraud')),
                    DropdownMenuItem(
                      value: 'compliance',
                      child: Text('Compliance'),
                    ),
                    DropdownMenuItem(
                      value: 'security',
                      child: Text('Security'),
                    ),
                    DropdownMenuItem(value: 'system', child: Text('System')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedAlertType = value);
                    }
                  },
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Message Template',
                    border: OutlineInputBorder(),
                    hintText: 'Use {variable_name} for dynamic values',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                  return;
                }

                try {
                  await SmsAlertsService.instance.createMessageTemplate(
                    templateName: nameController.text.trim(),
                    alertType: selectedAlertType,
                    messageTemplate: messageController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Template created successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    widget.onTemplatesChanged();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Create Template'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Add template button
        Padding(
          padding: EdgeInsets.all(3.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddTemplateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Template'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
            ),
          ),
        ),

        // Templates list
        Expanded(
          child: widget.templates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 30.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No message templates yet',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Create templates for quick alert sending',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  itemCount: widget.templates.length,
                  itemBuilder: (context, index) {
                    final template = widget.templates[index];
                    final alertType = template['alert_type'] ?? 'fraud';
                    final usageCount = template['usage_count'] ?? 0;

                    Color alertColor;
                    switch (alertType) {
                      case 'fraud':
                        alertColor = Colors.red;
                        break;
                      case 'compliance':
                        alertColor = Colors.orange;
                        break;
                      case 'security':
                        alertColor = Colors.purple;
                        break;
                      case 'system':
                        alertColor = Colors.blue;
                        break;
                      default:
                        alertColor = Colors.grey;
                    }

                    return Card(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: alertColor.withAlpha(51),
                          child: Icon(Icons.description, color: alertColor),
                        ),
                        title: Text(
                          template['template_name'] ?? '',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.3.h,
                              ),
                              decoration: BoxDecoration(
                                color: alertColor.withAlpha(51),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                alertType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: alertColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Used $usageCount times',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(3.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Message:',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                Container(
                                  padding: EdgeInsets.all(2.w),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    template['message_template'] ?? '',
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
