import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/creator_verification_service.dart';
import '../../../theme/app_theme.dart';

class IdentityDocumentStepWidget extends StatefulWidget {
  final VoidCallback onNext;

  const IdentityDocumentStepWidget({super.key, required this.onNext});

  @override
  State<IdentityDocumentStepWidget> createState() =>
      _IdentityDocumentStepWidgetState();
}

class _IdentityDocumentStepWidgetState
    extends State<IdentityDocumentStepWidget> {
  final CreatorVerificationService _verificationService =
      CreatorVerificationService.instance;

  String _selectedDocumentType = 'passport';
  bool _isUploading = false;
  List<Map<String, dynamic>> _uploadedDocuments = [];

  @override
  void initState() {
    super.initState();
    _loadUploadedDocuments();
  }

  Future<void> _loadUploadedDocuments() async {
    final documents = await _verificationService.getUploadedDocuments();
    setState(() => _uploadedDocuments = documents);
  }

  @override
  Widget build(BuildContext context) {
    final hasIdentityDoc = _uploadedDocuments.any(
      (doc) =>
          doc['document_type'] == 'passport' ||
          doc['document_type'] == 'drivers_license' ||
          doc['document_type'] == 'national_id',
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Identity Document',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Upload a government-issued ID for verification',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedDocumentType,
            decoration: InputDecoration(
              labelText: 'Document Type',
              prefixIcon: Icon(Icons.badge),
            ),
            items: [
              DropdownMenuItem(value: 'passport', child: Text('Passport')),
              DropdownMenuItem(
                value: 'drivers_license',
                child: Text('Driver\'s License'),
              ),
              DropdownMenuItem(
                value: 'national_id',
                child: Text('National ID'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDocumentType = value);
              }
            },
          ),
          SizedBox(height: 3.h),
          if (_uploadedDocuments.isNotEmpty) ...[
            Text(
              'Uploaded Documents',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            ..._uploadedDocuments.map((doc) => _buildDocumentCard(doc)),
            SizedBox(height: 2.h),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : _uploadDocument,
              icon: Icon(Icons.upload_file),
              label: Text(_isUploading ? 'Uploading...' : 'Upload Document'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasIdentityDoc ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
              child: Text(
                'Continue',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: Icon(Icons.description, color: AppTheme.primaryLight),
        title: Text(
          doc['file_name'] ?? 'Document',
          style: TextStyle(fontSize: 14.sp),
        ),
        subtitle: Text(
          _formatDocumentType(doc['document_type']),
          style: TextStyle(fontSize: 12.sp),
        ),
        trailing: Icon(Icons.check_circle, color: AppTheme.accentLight),
      ),
    );
  }

  String _formatDocumentType(String type) {
    switch (type) {
      case 'passport':
        return 'Passport';
      case 'drivers_license':
        return 'Driver\'s License';
      case 'national_id':
        return 'National ID';
      default:
        return type;
    }
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to read file'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    final success = await _verificationService.uploadIdentityDocument(
      documentType: _selectedDocumentType,
      fileBytes: file.bytes!,
      fileName: file.name,
    );

    setState(() => _isUploading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document uploaded successfully'),
          backgroundColor: AppTheme.accentLight,
        ),
      );
      _loadUploadedDocuments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload document'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }
}
