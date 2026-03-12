import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signature/signature.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/tax_compliance_service.dart';
import '../../../theme/app_theme.dart';

class TaxComplianceTrackingWidget extends StatefulWidget {
  final Map<String, dynamic> complianceStatus;
  final VoidCallback onRefresh;

  const TaxComplianceTrackingWidget({
    super.key,
    required this.complianceStatus,
    required this.onRefresh,
  });

  @override
  State<TaxComplianceTrackingWidget> createState() =>
      _TaxComplianceTrackingWidgetState();
}

class _TaxComplianceTrackingWidgetState
    extends State<TaxComplianceTrackingWidget> {
  final TaxComplianceService _taxService = TaxComplianceService.instance;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );

  String _selectedFormType = 'W-9';
  bool _isUploading = false;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    final docs = await _taxService.getTaxDocuments();
    setState(() => _documents = docs);
  }

  Future<void> _uploadTaxForm() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isUploading = true);

        final file = result.files.first;
        final bytes = file.bytes ?? await file.xFile.readAsBytes();

        // Generate document ID
        final docId = DateTime.now().millisecondsSinceEpoch.toString();

        // Upload document
        final documentUrl = await _taxService.uploadTaxDocument(
          documentId: docId,
          fileBytes: bytes,
          fileName: file.name,
        );

        if (documentUrl != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tax document uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadDocuments();
          widget.onRefresh();
        }
      }
    } catch (e) {
      debugPrint('Upload tax form error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSignatureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign $_selectedFormType Form',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 80.w,
          height: 30.h,
          child: Column(
            children: [
              Container(
                height: 20.h,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.textSecondaryLight),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => _signatureController.clear(),
                    child: Text('Clear'),
                  ),
                  Text(
                    'Sign above',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_signatureController.isNotEmpty) {
                final signature = await _signatureController.toPngBytes();
                if (signature != null && mounted) {
                  Navigator.pop(context);
                  _saveSignedForm(signature);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
            ),
            child: Text('Save Signature'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSignedForm(Uint8List signatureBytes) async {
    setState(() => _isUploading = true);

    try {
      final docId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = '${_selectedFormType}_signed_$docId.png';

      final documentUrl = await _taxService.uploadTaxDocument(
        documentId: docId,
        fileBytes: signatureBytes,
        fileName: fileName,
      );

      if (documentUrl != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_selectedFormType form signed and saved'),
            backgroundColor: Colors.green,
          ),
        );
        _signatureController.clear();
        await _loadDocuments();
        widget.onRefresh();
      }
    } catch (e) {
      debugPrint('Save signed form error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save signature'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final validDocs = widget.complianceStatus['valid_documents'] ?? 0;
    final totalDocs = widget.complianceStatus['total_documents'] ?? 0;
    final complianceScore = widget.complianceStatus['compliance_score'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComplianceHeader(validDocs, totalDocs, complianceScore),
          SizedBox(height: 3.h),
          _buildFormTypeSelector(),
          SizedBox(height: 2.h),
          _buildUploadButtons(),
          SizedBox(height: 3.h),
          _buildDocumentsList(),
        ],
      ),
    );
  }

  Widget _buildComplianceHeader(int validDocs, int totalDocs, int score) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            score >= 80 ? Colors.green : Colors.orange,
            (score >= 80 ? Colors.green : Colors.orange).withAlpha(204),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            '$score%',
            style: GoogleFonts.inter(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Compliance Score',
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Valid', validDocs.toString()),
              _buildStatItem('Total', totalDocs.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.white.withAlpha(230),
          ),
        ),
      ],
    );
  }

  Widget _buildFormTypeSelector() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Tax Form Type',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(child: _buildFormTypeOption('W-9', 'US Creators')),
              SizedBox(width: 2.w),
              Expanded(child: _buildFormTypeOption('W-8BEN', 'International')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormTypeOption(String type, String description) {
    final isSelected = _selectedFormType == type;

    return InkWell(
      onTap: () => setState(() => _selectedFormType = type),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight.withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryLight
                : AppTheme.textSecondaryLight,
          ),
        ),
        child: Column(
          children: [
            Text(
              type,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppTheme.primaryLight
                    : AppTheme.textPrimaryLight,
              ),
            ),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadTaxForm,
            icon: Icon(Icons.upload_file, size: 5.w),
            label: Text('Upload $_selectedFormType Form'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _showSignatureDialog,
            icon: Icon(Icons.draw, size: 5.w),
            label: Text('Sign $_selectedFormType Digitally'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryLight,
              side: BorderSide(color: AppTheme.primaryLight),
              padding: EdgeInsets.symmetric(vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsList() {
    if (_documents.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 15.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 1.h),
            Text(
              'No tax documents uploaded',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uploaded Documents',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        ..._documents.map((doc) => _buildDocumentCard(doc)),
      ],
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final docType = doc['document_type'] ?? 'Unknown';
    final status = doc['status'] ?? 'pending';
    final createdAt = doc['created_at'] != null
        ? DateTime.parse(doc['created_at'] as String)
        : DateTime.now();

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.primaryLight.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: AppTheme.primaryLight, size: 8.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docType,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Uploaded: ${createdAt.month}/${createdAt.day}/${createdAt.year}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'generated':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'expired':
        color = Colors.red;
        label = 'Expired';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
