import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/fraud_engine_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class FraudAppealScreen extends StatefulWidget {
  const FraudAppealScreen({super.key});

  @override
  State<FraudAppealScreen> createState() => _FraudAppealScreenState();
}

class _FraudAppealScreenState extends State<FraudAppealScreen> {
  final FraudEngineService _fraudService = FraudEngineService.instance;
  final TextEditingController _appealReasonController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _suspension;
  final List<String> _evidenceUrls = [];

  @override
  void initState() {
    super.initState();
    _loadSuspension();
  }

  @override
  void dispose() {
    _appealReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadSuspension() async {
    setState(() => _isLoading = true);

    try {
      final suspensions = await _fraudService.getActiveSuspensions();

      setState(() {
        _suspension = suspensions.isNotEmpty ? suspensions.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAppeal() async {
    if (_appealReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a reason for your appeal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await _fraudService.submitFraudAppeal(
        suspensionId: _suspension!['suspension_id'],
        appealReason: _appealReasonController.text.trim(),
        evidenceUrls: _evidenceUrls,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appeal submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit appeal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Submit Appeal',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _suspension == null
          ? _buildNoSuspensionState()
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suspension Details
                  _buildSuspensionDetailsCard(),
                  SizedBox(height: 3.h),

                  // Appeal Form
                  _buildAppealForm(),
                  SizedBox(height: 3.h),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAppeal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Submit Appeal',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNoSuspensionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 20.w, color: Colors.green),
          SizedBox(height: 2.h),
          Text(
            'No Active Suspension',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Your account is in good standing',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspensionDetailsCard() {
    final reason = _suspension!['suspension_reason'] as String? ?? 'N/A';
    final suspendedAt = _suspension!['suspended_at'] as String?;
    final expiresAt = _suspension!['expires_at'] as String?;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'Suspension Details',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildDetailRow('Reason', reason),
          _buildDetailRow('Suspended On', suspendedAt?.split('T')[0] ?? 'N/A'),
          if (expiresAt != null)
            _buildDetailRow('Expires On', expiresAt.split('T')[0]),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppealForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appeal Reason',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: _appealReasonController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Explain why you believe this suspension is unfair...',
            hintStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Supporting Evidence (Optional)',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        OutlinedButton.icon(
          onPressed: _pickAndUploadEvidence,
          icon: Icon(Icons.upload_file),
          label: Text('Upload Evidence'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        if (_evidenceUrls.isNotEmpty) ...[
          SizedBox(height: 1.h),
          Text(
            '${_evidenceUrls.length} file(s) uploaded',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.green),
          ),
        ],
      ],
    );
  }

  Future<void> _pickAndUploadEvidence() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'txt', 'doc', 'docx'],
      );
      if (picked == null || picked.files.isEmpty) return;

      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to upload evidence')),
        );
        return;
      }

      final client = SupabaseService.instance.client;
      int uploaded = 0;
      for (final file in picked.files) {
        final bytes = file.bytes;
        if (bytes == null) continue;
        final safeName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
        final path = 'fraud_appeals/$userId/$safeName';
        await client.storage.from('support-files').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: file.extension == 'pdf'
                    ? 'application/pdf'
                    : 'application/octet-stream',
                upsert: false,
              ),
            );
        final url = client.storage.from('support-files').getPublicUrl(path);
        _evidenceUrls.add(url);
        uploaded += 1;
      }

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded $uploaded file(s)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }
}
