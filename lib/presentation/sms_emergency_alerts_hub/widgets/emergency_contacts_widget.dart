import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/sms_alerts_service.dart';

class EmergencyContactsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> contacts;
  final VoidCallback onContactsChanged;

  const EmergencyContactsWidget({
    super.key,
    required this.contacts,
    required this.onContactsChanged,
  });

  @override
  State<EmergencyContactsWidget> createState() =>
      _EmergencyContactsWidgetState();
}

class _EmergencyContactsWidgetState extends State<EmergencyContactsWidget> {
  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final countryCodeController = TextEditingController(text: '+1');
    String selectedPriority = 'primary';
    final coverageController = TextEditingController(text: '24/7');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    SizedBox(
                      width: 20.w,
                      child: TextField(
                        controller: countryCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'primary', child: Text('Primary')),
                    DropdownMenuItem(value: 'backup', child: Text('Backup')),
                    DropdownMenuItem(
                      value: 'emergency',
                      child: Text('Emergency'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedPriority = value);
                    }
                  },
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: coverageController,
                  decoration: const InputDecoration(
                    labelText: 'Coverage Hours',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 24/7 or Business Hours',
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
                    phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                  return;
                }

                try {
                  await SmsAlertsService.instance.createEmergencyContact(
                    contactName: nameController.text.trim(),
                    phoneNumber: phoneController.text.trim(),
                    countryCode: countryCodeController.text.trim(),
                    priority: selectedPriority,
                    coverageHours: coverageController.text.trim(),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    widget.onContactsChanged();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteContact(String contactId, String contactName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete $contactName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SmsAlertsService.instance.deleteEmergencyContact(contactId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onContactsChanged();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Add contact button
        Padding(
          padding: EdgeInsets.all(3.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Emergency Contact'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
            ),
          ),
        ),

        // Contacts list
        Expanded(
          child: widget.contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.contacts_outlined,
                        size: 30.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No emergency contacts yet',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Add contacts to receive emergency alerts',
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
                  itemCount: widget.contacts.length,
                  itemBuilder: (context, index) {
                    final contact = widget.contacts[index];
                    final priority = contact['priority'] ?? 'primary';
                    final isActive = contact['is_active'] ?? true;

                    Color priorityColor;
                    switch (priority) {
                      case 'primary':
                        priorityColor = Colors.red;
                        break;
                      case 'backup':
                        priorityColor = Colors.orange;
                        break;
                      case 'emergency':
                        priorityColor = Colors.purple;
                        break;
                      default:
                        priorityColor = Colors.grey;
                    }

                    return Card(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: priorityColor.withAlpha(51),
                          child: Icon(Icons.phone, color: priorityColor),
                        ),
                        title: Text(
                          contact['contact_name'] ?? '',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 0.5.h),
                            Text(
                              contact['phone_number'] ?? '',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                            SizedBox(height: 0.3.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.w,
                                    vertical: 0.3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: priorityColor.withAlpha(51),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    priority.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: priorityColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  contact['coverage_hours'] ?? '24/7',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (value) async {
                                await SmsAlertsService.instance
                                    .updateEmergencyContact(
                                      contactId: contact['id'],
                                      isActive: value,
                                    );
                                widget.onContactsChanged();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteContact(
                                contact['id'],
                                contact['contact_name'] ?? '',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
