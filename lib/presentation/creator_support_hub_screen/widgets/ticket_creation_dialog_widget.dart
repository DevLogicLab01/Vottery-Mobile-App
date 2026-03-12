import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../services/support_ticket_service.dart';
import '../../../services/auth_service.dart';

class TicketCreationDialogWidget extends StatefulWidget {
  final VoidCallback onSubmit;

  const TicketCreationDialogWidget({super.key, required this.onSubmit});

  @override
  State<TicketCreationDialogWidget> createState() =>
      _TicketCreationDialogWidgetState();
}

class _TicketCreationDialogWidgetState
    extends State<TicketCreationDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final SupportTicketService _service = SupportTicketService.instance;
  final _auth = AuthService.instance;

  String _selectedCategory = 'technical';
  String _selectedPriority = 'medium';
  final List<XFile> _attachments = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.length + _attachments.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 5 attachments allowed'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _attachments.addAll(images);
      });
    } catch (e) {
      debugPrint('Pick images error: $e');
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<Map<String, dynamic>> _collectMetadata() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceModel = 'Unknown';
      String osVersion = 'Unknown';
      String platform = 'Unknown';

      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = androidInfo.model;
        osVersion = androidInfo.version.release;
        platform = 'Android';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.model;
        osVersion = iosInfo.systemVersion;
        platform = 'iOS';
      }

      return {
        'app_version': packageInfo.version,
        'device_model': deviceModel,
        'os_version': osVersion,
        'platform': platform,
        'user_id': _auth.currentUser?.id,
      };
    } catch (e) {
      debugPrint('Collect metadata error: $e');
      return {};
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Collect metadata
      final metadata = await _collectMetadata();

      // Create ticket
      final ticket = await _service.createTicket(
        category: _selectedCategory,
        priority: _selectedPriority,
        subject: _subjectController.text,
        description:
            '${_descriptionController.text}\n\nMetadata: ${metadata.toString()}',
      );

      if (ticket != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ticket #${ticket['ticket_number'] ?? 'created'} created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSubmit();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create ticket'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Submit ticket error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(4.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),

                // Title
                Text(
                  'Create Support Ticket',
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3.h),

                // Subject
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Subject is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 2.h),

                // Category
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'technical',
                      child: Text('Technical'),
                    ),
                    DropdownMenuItem(value: 'payment', child: Text('Payment')),
                    DropdownMenuItem(value: 'content', child: Text('Content')),
                    DropdownMenuItem(value: 'account', child: Text('Account')),
                    DropdownMenuItem(
                      value: 'feature_request',
                      child: Text('Feature Request'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                  },
                ),
                SizedBox(height: 2.h),

                // Priority
                Text(
                  'Priority *',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  children: [
                    ChoiceChip(
                      label: const Text('Low'),
                      selected: _selectedPriority == 'low',
                      onSelected: (selected) {
                        setState(() => _selectedPriority = 'low');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Medium'),
                      selected: _selectedPriority == 'medium',
                      onSelected: (selected) {
                        setState(() => _selectedPriority = 'medium');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('High'),
                      selected: _selectedPriority == 'high',
                      onSelected: (selected) {
                        setState(() => _selectedPriority = 'high');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Urgent'),
                      selected: _selectedPriority == 'urgent',
                      onSelected: (selected) {
                        setState(() => _selectedPriority = 'urgent');
                      },
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  maxLines: 5,
                  minLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 2.h),

                // Attachments
                Row(
                  children: [
                    Text(
                      'Attachments (${_attachments.length}/5)',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate),
                    ),
                  ],
                ),
                if (_attachments.isNotEmpty)
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: _attachments.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(Icons.image),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              onPressed: () => _removeAttachment(entry.key),
                              icon: const Icon(Icons.close),
                              iconSize: 16.sp,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                SizedBox(height: 3.h),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitTicket,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : Text(
                            'Submit Ticket',
                            style: GoogleFonts.inter(
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
      ),
    );
  }
}
