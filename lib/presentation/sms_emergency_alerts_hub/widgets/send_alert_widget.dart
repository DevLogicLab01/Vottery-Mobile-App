import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/sms_alerts_service.dart';

class SendAlertWidget extends StatefulWidget {
  final List<Map<String, dynamic>> contacts;
  final List<Map<String, dynamic>> templates;
  final VoidCallback onAlertSent;

  const SendAlertWidget({
    super.key,
    required this.contacts,
    required this.templates,
    required this.onAlertSent,
  });

  @override
  State<SendAlertWidget> createState() => _SendAlertWidgetState();
}

class _SendAlertWidgetState extends State<SendAlertWidget> {
  final _messageController = TextEditingController();
  String _selectedAlertType = 'fraud';
  String? _selectedTemplateId;
  final List<String> _selectedContactIds = [];
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendAlert() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }

    if (_selectedContactIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final success = await SmsAlertsService.instance.sendEmergencySms(
        alertType: _selectedAlertType,
        message: _messageController.text.trim(),
        templateId: _selectedTemplateId,
        contactIds: _selectedContactIds,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency alert sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _messageController.clear();
          _selectedContactIds.clear();
          widget.onAlertSent();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send alert'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _applyTemplate(String templateId) {
    final template = widget.templates.firstWhere(
      (t) => t['id'] == templateId,
      orElse: () => {},
    );

    if (template.isNotEmpty) {
      setState(() {
        _selectedTemplateId = templateId;
        _messageController.text = template['message_template'] ?? '';
        _selectedAlertType = template['alert_type'] ?? 'fraud';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert type selector
          Text(
            'Alert Type',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: [
              _buildAlertTypeChip('fraud', 'Fraud', Colors.red),
              _buildAlertTypeChip('compliance', 'Compliance', Colors.orange),
              _buildAlertTypeChip('security', 'Security', Colors.purple),
              _buildAlertTypeChip('system', 'System', Colors.blue),
            ],
          ),
          SizedBox(height: 2.h),

          // Template selector
          Text(
            'Use Template (Optional)',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedTemplateId,
                hint: Text('Select a template'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No template'),
                  ),
                  ...widget.templates.map((template) {
                    return DropdownMenuItem<String>(
                      value: template['id'],
                      child: Text(
                        template['template_name'] ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _applyTemplate(value);
                  } else {
                    setState(() {
                      _selectedTemplateId = null;
                      _messageController.clear();
                    });
                  }
                },
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Message input
          Text(
            'Message',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _messageController,
            maxLines: 5,
            maxLength: 160,
            decoration: InputDecoration(
              hintText: 'Enter emergency alert message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
          SizedBox(height: 2.h),

          // Contact selector
          Text(
            'Select Recipients',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          widget.contacts.isEmpty
              ? Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'No emergency contacts configured. Add contacts first.',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: widget.contacts.map((contact) {
                    final isSelected = _selectedContactIds.contains(
                      contact['id'],
                    );
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedContactIds.add(contact['id']);
                          } else {
                            _selectedContactIds.remove(contact['id']);
                          }
                        });
                      },
                      title: Text(
                        contact['contact_name'] ?? '',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                      subtitle: Text(
                        '${contact['phone_number']} (${contact['priority']})',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      secondary: Icon(
                        Icons.phone,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  }).toList(),
                ),
          SizedBox(height: 3.h),

          // Send button
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _isSending
                  ? SizedBox(
                      height: 2.h,
                      width: 2.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, size: 16.sp),
                        SizedBox(width: 2.w),
                        Text(
                          'Send Emergency Alert',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTypeChip(String value, String label, Color color) {
    final isSelected = _selectedAlertType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedAlertType = value);
        }
      },
      selectedColor: color.withAlpha(51),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12.sp,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey[300]!,
        width: isSelected ? 2.0 : 1.0,
      ),
    );
  }
}
