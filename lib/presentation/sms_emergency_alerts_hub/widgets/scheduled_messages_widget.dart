import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/sms_alerts_service.dart';

class ScheduledMessagesWidget extends StatefulWidget {
  final VoidCallback onScheduleChanged;

  const ScheduledMessagesWidget({super.key, required this.onScheduleChanged});

  @override
  State<ScheduledMessagesWidget> createState() =>
      _ScheduledMessagesWidgetState();
}

class _ScheduledMessagesWidgetState extends State<ScheduledMessagesWidget> {
  List<Map<String, dynamic>> _scheduledMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledMessages();
  }

  Future<void> _loadScheduledMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await SmsAlertsService.instance.getScheduledMessages();

      if (mounted) {
        setState(() {
          _scheduledMessages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showScheduleDialog() async {
    final messageController = TextEditingController();
    String selectedAlertType = 'system';
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.now();

    // Get contacts for selection
    final contacts = await SmsAlertsService.instance.getEmergencyContacts();
    String? selectedContactId = contacts.isNotEmpty ? contacts[0]['id'] : null;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Message'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Contact selector
                DropdownButtonFormField<String>(
                  initialValue: selectedContactId,
                  decoration: const InputDecoration(
                    labelText: 'Recipient',
                    border: OutlineInputBorder(),
                  ),
                  items: contacts.map((contact) {
                    return DropdownMenuItem<String>(
                      value: contact['id'],
                      child: Text(
                        contact['contact_name'] ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedContactId = value);
                  },
                ),
                SizedBox(height: 2.h),

                // Alert type
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

                // Message
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 2.h),

                // Date picker
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    'Date: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),

                // Time picker
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    'Time: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
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
                if (messageController.text.trim().isEmpty ||
                    selectedContactId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                  return;
                }

                final scheduledDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                try {
                  await SmsAlertsService.instance.scheduleMessage(
                    contactId: selectedContactId!,
                    messageContent: messageController.text.trim(),
                    alertType: selectedAlertType,
                    scheduledFor: scheduledDateTime,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message scheduled successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    widget.onScheduleChanged();
                    _loadScheduledMessages();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Schedule'),
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
        // Schedule button
        Padding(
          padding: EdgeInsets.all(3.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showScheduleDialog,
              icon: const Icon(Icons.schedule_send),
              label: const Text('Schedule New Message'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
            ),
          ),
        ),

        // Scheduled messages list
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _scheduledMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule_send,
                        size: 30.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No scheduled messages',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Schedule messages for non-urgent alerts',
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
                  itemCount: _scheduledMessages.length,
                  itemBuilder: (context, index) {
                    final message = _scheduledMessages[index];
                    final alertType = message['alert_type'] ?? 'system';
                    final scheduledFor = message['scheduled_for'] != null
                        ? DateTime.parse(message['scheduled_for'])
                        : DateTime.now();
                    final isSent = message['is_sent'] ?? false;

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
                      default:
                        alertColor = Colors.blue;
                    }

                    return Card(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSent
                              ? Colors.grey.withAlpha(51)
                              : alertColor.withAlpha(51),
                          child: Icon(
                            isSent ? Icons.check : Icons.schedule,
                            color: isSent ? Colors.grey : alertColor,
                          ),
                        ),
                        title: Text(
                          message['message_content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            decoration: isSent
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 0.5.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12.sp,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  '${scheduledFor.year}-${scheduledFor.month.toString().padLeft(2, '0')}-${scheduledFor.day.toString().padLeft(2, '0')} ${scheduledFor.hour.toString().padLeft(2, '0')}:${scheduledFor.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 0.3.h),
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
                          ],
                        ),
                        trailing: isSent
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(51),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  'SENT',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
