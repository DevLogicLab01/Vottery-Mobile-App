import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/unified_sms_service.dart';

class TemplateTestingDialogWidget extends StatefulWidget {
  final Map<String, dynamic> template;

  const TemplateTestingDialogWidget({super.key, required this.template});

  @override
  State<TemplateTestingDialogWidget> createState() =>
      _TemplateTestingDialogWidgetState();
}

class _TemplateTestingDialogWidgetState
    extends State<TemplateTestingDialogWidget> {
  late TextEditingController _phoneController;
  final Map<String, TextEditingController> _variableControllers = {};
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _extractVariables();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final controller in _variableControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _extractVariables() {
    final messageBody = widget.template['message_body'] as String? ?? '';
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(messageBody);

    for (final match in matches) {
      final variable = match.group(1)!;
      _variableControllers[variable] = TextEditingController();
    }
  }

  String _renderMessage() {
    var message = widget.template['message_body'] as String? ?? '';

    for (final entry in _variableControllers.entries) {
      final value = entry.value.text.isEmpty ? '{${entry.key}}' : entry.value.text;
      message = message.replaceAll('{${entry.key}}', value);
    }

    return message;
  }

  Future<void> _sendTestSMS() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final renderedMessage = _renderMessage();
      final result = await UnifiedSMSService.instance.sendSMS(
        toPhone: _phoneController.text,
        messageBody: renderedMessage,
        messageType: 'operational',
      );

      if (mounted) {
        setState(() => _isSending = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test SMS sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send SMS: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  'Test Template',
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
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Test Phone Number',
                        hintText: '+1234567890',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 2.h),
                    if (_variableControllers.isNotEmpty) ...[
                      Text(
                        'Variable Values',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      ..._variableControllers.entries.map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(bottom: 1.h),
                          child: TextField(
                            controller: entry.value,
                            decoration: InputDecoration(
                              labelText: entry.key,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],
                    Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withAlpha(51)),
                      ),
                      child: Text(
                        _renderMessage(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.blue[900],
                        ),
                      ),
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
                ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendTestSMS,
                  icon: _isSending
                      ? SizedBox(
                          width: 16.sp,
                          height: 16.sp,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSending ? 'Sending...' : 'Send Test SMS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}