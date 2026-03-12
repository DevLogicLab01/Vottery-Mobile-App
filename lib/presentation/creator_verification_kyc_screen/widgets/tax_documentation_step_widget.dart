import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/creator_verification_service.dart';
import '../../../theme/app_theme.dart';

class TaxDocumentationStepWidget extends StatefulWidget {
  final VoidCallback onNext;
  final Map<String, dynamic>? initialData;

  const TaxDocumentationStepWidget({
    super.key,
    required this.onNext,
    this.initialData,
  });

  @override
  State<TaxDocumentationStepWidget> createState() =>
      _TaxDocumentationStepWidgetState();
}

class _TaxDocumentationStepWidgetState
    extends State<TaxDocumentationStepWidget> {
  final _formKey = GlobalKey<FormState>();
  final CreatorVerificationService _verificationService =
      CreatorVerificationService.instance;

  late TextEditingController _taxIdController;
  String _selectedTaxDocType = 'tax_document_w9';
  bool _isUploading = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _uploadedDocuments = [];

  @override
  void initState() {
    super.initState();
    _taxIdController = TextEditingController(
      text: widget.initialData?['tax_id'] ?? '',
    );
    _loadUploadedDocuments();
  }

  @override
  void dispose() {
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _loadUploadedDocuments() async {
    final documents = await _verificationService.getUploadedDocuments();
    setState(() => _uploadedDocuments = documents);
  }

  @override
  Widget build(BuildContext context) {
    final hasTaxDoc = _uploadedDocuments.any(
      (doc) =>
          doc['document_type'] == 'tax_document_w9' ||
          doc['document_type'] == 'tax_document_w8ben',
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 4: Tax Documentation',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Provide tax information for compliance',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 3.h),
            TextFormField(
              controller: _taxIdController,
              decoration: InputDecoration(
                labelText: 'Tax ID (SSN/EIN/Tax ID)',
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your tax ID';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              initialValue: _selectedTaxDocType,
              decoration: InputDecoration(
                labelText: 'Tax Document Type',
                prefixIcon: Icon(Icons.description),
              ),
              items: [
                DropdownMenuItem(
                  value: 'tax_document_w9',
                  child: Text('W-9 (US)'),
                ),
                DropdownMenuItem(
                  value: 'tax_document_w8ben',
                  child: Text('W-8BEN (International)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTaxDocType = value);
                }
              },
            ),
            SizedBox(height: 3.h),
            if (_uploadedDocuments.isNotEmpty) ...[
              Text(
                'Uploaded Tax Documents',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(height: 1.h),
              ..._uploadedDocuments
                  .where(
                    (doc) =>
                        doc['document_type'] == 'tax_document_w9' ||
                        doc['document_type'] == 'tax_document_w8ben',
                  )
                  .map((doc) => _buildDocumentCard(doc)),
              SizedBox(height: 2.h),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : _uploadTaxDocument,
                icon: Icon(Icons.upload_file),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Upload Tax Document',
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (hasTaxDoc && !_isSubmitting)
                    ? _submitTaxInfo
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Continue',
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
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: Icon(Icons.description, color: AppTheme.primaryLight),
        title: Text(
          doc['file_name'] ?? 'Tax Document',
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
      case 'tax_document_w9':
        return 'W-9 (US)';
      case 'tax_document_w8ben':
        return 'W-8BEN (International)';
      default:
        return type;
    }
  }

  Future<void> _uploadTaxDocument() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
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

    final success = await _verificationService.submitTaxDocumentation(
      taxId: _taxIdController.text,
      taxDocumentType: _selectedTaxDocType,
      fileBytes: file.bytes!,
      fileName: file.name,
    );

    setState(() => _isUploading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tax document uploaded successfully'),
          backgroundColor: AppTheme.accentLight,
        ),
      );
      _loadUploadedDocuments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload tax document'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }

  Future<void> _submitTaxInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(Duration(milliseconds: 500));
    setState(() => _isSubmitting = false);

    widget.onNext();
  }
}
