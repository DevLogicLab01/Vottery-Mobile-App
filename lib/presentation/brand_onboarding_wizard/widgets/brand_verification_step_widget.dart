import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/brand_onboarding_service.dart';

class BrandVerificationStepWidget extends StatefulWidget {
  final Map<String, dynamic>? onboardingData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const BrandVerificationStepWidget({
    super.key,
    this.onboardingData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<BrandVerificationStepWidget> createState() =>
      _BrandVerificationStepWidgetState();
}

class _BrandVerificationStepWidgetState
    extends State<BrandVerificationStepWidget> {
  final BrandOnboardingService _service = BrandOnboardingService.instance;

  bool _isSaving = false;
  final List<String> _uploadedDocuments = [];

  Future<void> _handleNext() async {
    if (_uploadedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload at least one document')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await _service.completeBrandVerification(
        documentUrls: _uploadedDocuments,
        businessLicense: {
          'verified': true,
          'uploaded_at': DateTime.now().toIso8601String(),
        },
        ownershipDisclosure: {
          'verified': true,
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );

      if (success && mounted) {
        widget.onNext();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save verification documents')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _simulateDocumentUpload() {
    setState(() {
      _uploadedDocuments.add(
        'https://example.com/documents/business_license_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Document uploaded successfully')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Brand Verification',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Upload documents to verify your business identity',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          _buildUploadSection(
            theme,
            'Business License',
            'Upload your business registration or license',
            Icons.business,
          ),
          SizedBox(height: 2.h),
          _buildUploadSection(
            theme,
            'Ownership Disclosure',
            'Beneficial ownership information',
            Icons.people,
          ),
          SizedBox(height: 3.h),
          if (_uploadedDocuments.isNotEmpty) ...[
            Text(
              'Uploaded Documents',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            ..._uploadedDocuments.map((doc) => _buildDocumentCard(theme, doc)),
          ],
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 2.h,
                          width: 2.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Continue to Payment',
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
        ],
      ),
    );
  }

  Widget _buildUploadSection(
    ThemeData theme,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _simulateDocumentUpload,
              icon: Icon(Icons.upload_file, size: 5.w),
              label: Text('Upload Document'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(ThemeData theme, String documentUrl) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 5.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              documentUrl.split('/').last,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
