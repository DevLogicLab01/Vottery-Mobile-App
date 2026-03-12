import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/advertiser_registration_service.dart';

class IdentityVerificationStepWidget extends StatefulWidget {
  final Map<String, dynamic>? registration;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const IdentityVerificationStepWidget({
    super.key,
    this.registration,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<IdentityVerificationStepWidget> createState() =>
      _IdentityVerificationStepWidgetState();
}

class _IdentityVerificationStepWidgetState
    extends State<IdentityVerificationStepWidget> {
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _beneficialOwners = [];
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.registration != null) {
      _loadDocuments();
      _loadBeneficialOwners();
    }
  }

  Future<void> _loadDocuments() async {
    final docs = await AdvertiserRegistrationService.instance.getDocuments(
      widget.registration!['id'],
    );
    if (mounted) {
      setState(() => _documents = docs);
    }
  }

  Future<void> _loadBeneficialOwners() async {
    final owners = await AdvertiserRegistrationService.instance
        .getBeneficialOwners(widget.registration!['id']);
    if (mounted) {
      setState(() => _beneficialOwners = owners);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Identity Verification', style: theme.textTheme.titleMedium),
          SizedBox(height: 2.h),
          Text(
            'Upload required documents for identity verification',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          _buildDocumentSection(theme),
          SizedBox(height: 3.h),
          _buildBeneficialOwnersSection(theme),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: Text('Back'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed:
                      _documents.isNotEmpty && _beneficialOwners.isNotEmpty
                      ? () => widget.onNext({})
                      : null,
                  child: Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Documents', style: theme.textTheme.titleSmall),
                TextButton.icon(
                  onPressed: _showUploadDialog,
                  icon: Icon(Icons.upload_file, size: 16.sp),
                  label: Text('Upload'),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (_documents.isEmpty)
              Center(
                child: Text(
                  'No documents uploaded yet',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              ..._documents.map(
                (doc) => ListTile(
                  leading: Icon(Icons.description),
                  title: Text(doc['document_name'] ?? 'Document'),
                  subtitle: Text(doc['document_type'] ?? 'Unknown'),
                  trailing: Chip(
                    label: Text(
                      doc['verification_status'] ?? 'pending',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                    backgroundColor: doc['verification_status'] == 'verified'
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficialOwnersSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Beneficial Owners', style: theme.textTheme.titleSmall),
                TextButton.icon(
                  onPressed: _showAddOwnerDialog,
                  icon: Icon(Icons.add, size: 16.sp),
                  label: Text('Add'),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (_beneficialOwners.isEmpty)
              Center(
                child: Text(
                  'No beneficial owners added yet',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              ..._beneficialOwners.map(
                (owner) => ListTile(
                  leading: Icon(Icons.person),
                  title: Text(owner['full_name'] ?? 'Owner'),
                  subtitle: Text(
                    '${owner['ownership_percentage'] ?? 0}% ownership',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload Document'),
        content: Text(
          'Document upload functionality would integrate with file picker and storage service.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddOwnerDialog() {
    final nameController = TextEditingController();
    final percentageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Beneficial Owner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: percentageController,
              decoration: InputDecoration(
                labelText: 'Ownership Percentage',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (widget.registration != null) {
                await AdvertiserRegistrationService.instance.addBeneficialOwner(
                  registrationId: widget.registration!['id'],
                  fullName: nameController.text,
                  ownershipPercentage:
                      double.tryParse(percentageController.text) ?? 0,
                );
                Navigator.pop(context);
                _loadBeneficialOwners();
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}
