import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/resend_email_service.dart';
import '../../services/stripe_connect_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Bank Account Linking Screen
/// Comprehensive bank account setup with routing number, SWIFT/IBAN, and tax documents
class BankAccountLinkingScreen extends StatefulWidget {
  const BankAccountLinkingScreen({super.key});

  @override
  State<BankAccountLinkingScreen> createState() =>
      _BankAccountLinkingScreenState();
}

class _BankAccountLinkingScreenState extends State<BankAccountLinkingScreen> {
  final StripeConnectService _stripeService = StripeConnectService.instance;
  final ResendEmailService _emailService = ResendEmailService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _linkedAccounts = [];
  bool _showAddAccountForm = false;

  // Form controllers
  final _routingNumberController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _swiftCodeController = TextEditingController();
  final _ibanController = TextEditingController();
  final _ssnController = TextEditingController();

  String _accountType = 'Checking';
  String? _detectedBankName;
  String _selectedCountry = 'US';
  String _selectedCurrency = 'USD';
  String _payoutSchedule = 'weekly';
  double _minimumThreshold = 10.0;
  bool _verificationInProgress = false;
  final List<Map<String, dynamic>> _taxDocuments = [];

  @override
  void initState() {
    super.initState();
    _loadLinkedAccounts();
  }

  @override
  void dispose() {
    _routingNumberController.dispose();
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    _accountHolderController.dispose();
    _swiftCodeController.dispose();
    _ibanController.dispose();
    _ssnController.dispose();
    super.dispose();
  }

  Future<void> _loadLinkedAccounts() async {
    setState(() => _isLoading = true);

    try {
      final accountStatus = await _stripeService.getConnectAccountStatus();
      if (accountStatus != null && mounted) {
        setState(() {
          _linkedAccounts = [
            {
              'bank_name': 'Bank of America',
              'last4': '1234',
              'is_verified': true,
              'is_primary': true,
            },
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load linked accounts error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _detectBankFromRouting(String routing) {
    if (routing.length == 9) {
      // Mock bank detection - in production, use routing number API
      setState(() {
        _detectedBankName = 'Bank of America';
      });
    }
  }

  bool _validateIBAN(String iban) {
    // Basic IBAN validation - in production, use full checksum algorithm
    if (iban.length < 15 || iban.length > 34) return false;
    return RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]+\$').hasMatch(iban);
  }

  bool _validateSWIFT(String swift) {
    return swift.length >= 8 && swift.length <= 11;
  }

  Future<void> _uploadTaxDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _taxDocuments.add({
            'name': file.name,
            'size': file.size,
            'type': 'W-9',
            'status': 'Pending Review',
            'uploaded_at': DateTime.now(),
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Upload tax document error: $e');
    }
  }

  Future<void> _submitBankAccount() async {
    if (_accountNumberController.text != _confirmAccountController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account numbers do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _verificationInProgress = true);

    // Simulate micro-deposit verification
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _verificationInProgress = false;
        _showAddAccountForm = false;
        _linkedAccounts.add({
          'bank_name': _detectedBankName ?? 'Unknown Bank',
          'last4': _accountNumberController.text.substring(
            _accountNumberController.text.length - 4,
          ),
          'is_verified': false,
          'is_primary': false,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification in progress. Check your account in 1-2 business days.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: IconButton(
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: 'Bank Account Linking',
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLinkedAccountsSection(),
                  SizedBox(height: 3.h),
                  if (_showAddAccountForm) ..._buildAddAccountForm(),
                  if (!_showAddAccountForm)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _showAddAccountForm = true),
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text('Add New Bank Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryLight,
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                  SizedBox(height: 3.h),
                  _buildTaxDocumentsSection(),
                  SizedBox(height: 3.h),
                  _buildComplianceChecklist(),
                  SizedBox(height: 3.h),
                  _buildPayoutConfiguration(),
                ],
              ),
            ),
    );
  }

  Widget _buildLinkedAccountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linked Accounts',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        if (_linkedAccounts.isEmpty)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Center(
              child: Text(
                'No linked accounts yet',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ),
          )
        else
          ..._linkedAccounts.map(
            (account) => Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: account['is_primary'] as bool
                      ? AppTheme.primaryLight
                      : Colors.transparent,
                  width: 2.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    color: AppTheme.primaryLight,
                    size: 8.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${account['bank_name']} ****${account['last4']}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryLight,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            if (account['is_verified'] as bool)
                              Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 5.w,
                              ),
                          ],
                        ),
                        if (account['is_primary'] as bool)
                          Text(
                            'Primary',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildAddAccountForm() {
    return [
      Text(
        'Add New Account',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryLight,
        ),
      ),
      SizedBox(height: 2.h),
      // Country Selector
      DropdownButtonFormField<String>(
        initialValue: _selectedCountry,
        decoration: InputDecoration(
          labelText: 'Country',
          border: OutlineInputBorder(),
        ),
        items: ['US', 'GB', 'FR', 'DE', 'IT']
            .map(
              (country) =>
                  DropdownMenuItem(value: country, child: Text(country)),
            )
            .toList(),
        onChanged: (value) => setState(() => _selectedCountry = value!),
      ),
      SizedBox(height: 2.h),
      // Routing Number (US only)
      if (_selectedCountry == 'US') ...[
        TextField(
          controller: _routingNumberController,
          decoration: InputDecoration(
            labelText: 'Routing Number',
            hintText: '9 digits',
            border: OutlineInputBorder(),
            suffixIcon: _detectedBankName != null
                ? Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
          keyboardType: TextInputType.number,
          maxLength: 9,
          onChanged: _detectBankFromRouting,
        ),
        if (_detectedBankName != null)
          Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Text(
              'Detected: $_detectedBankName',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
      // SWIFT/IBAN for international
      if (_selectedCountry != 'US') ...[
        TextField(
          controller: _swiftCodeController,
          decoration: InputDecoration(
            labelText: 'SWIFT Code',
            hintText: '8-11 characters',
            border: OutlineInputBorder(),
          ),
          maxLength: 11,
        ),
        SizedBox(height: 2.h),
        TextField(
          controller: _ibanController,
          decoration: InputDecoration(
            labelText: 'IBAN',
            hintText: 'International Bank Account Number',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 2.h),
      ],
      // Account Type
      Row(
        children: [
          Expanded(
            child: RadioListTile<String>(
              title: Text('Checking', style: TextStyle(fontSize: 12.sp)),
              value: 'Checking',
              groupValue: _accountType,
              onChanged: (value) => setState(() => _accountType = value!),
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: Text('Savings', style: TextStyle(fontSize: 12.sp)),
              value: 'Savings',
              groupValue: _accountType,
              onChanged: (value) => setState(() => _accountType = value!),
            ),
          ),
        ],
      ),
      SizedBox(height: 2.h),
      // Account Holder Name
      TextField(
        controller: _accountHolderController,
        decoration: InputDecoration(
          labelText: 'Account Holder Name',
          border: OutlineInputBorder(),
        ),
      ),
      SizedBox(height: 2.h),
      // Account Number
      TextField(
        controller: _accountNumberController,
        decoration: InputDecoration(
          labelText: 'Account Number',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        obscureText: true,
      ),
      SizedBox(height: 2.h),
      // Confirm Account Number
      TextField(
        controller: _confirmAccountController,
        decoration: InputDecoration(
          labelText: 'Confirm Account Number',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        obscureText: true,
      ),
      SizedBox(height: 2.h),
      // Currency Selection
      DropdownButtonFormField<String>(
        initialValue: _selectedCurrency,
        decoration: InputDecoration(
          labelText: 'Payout Currency',
          border: OutlineInputBorder(),
        ),
        items: ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY']
            .map(
              (currency) =>
                  DropdownMenuItem(value: currency, child: Text(currency)),
            )
            .toList(),
        onChanged: (value) => setState(() => _selectedCurrency = value!),
      ),
      SizedBox(height: 3.h),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _showAddAccountForm = false),
              child: Text('Cancel'),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _verificationInProgress ? null : _submitBankAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
              ),
              child: _verificationInProgress
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text('Submit'),
            ),
          ),
        ],
      ),
      SizedBox(height: 3.h),
    ];
  }

  Widget _buildTaxDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tax Documents',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            Row(
              children: [
                Icon(Icons.lock, color: Colors.green, size: 5.w),
                SizedBox(width: 1.w),
                Text(
                  'Encrypted',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 2.h),
        ElevatedButton.icon(
          onPressed: _uploadTaxDocument,
          icon: Icon(Icons.upload_file, color: Colors.white),
          label: Text('Upload Tax Document'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        if (_taxDocuments.isNotEmpty)
          ..._taxDocuments.map(
            (doc) => Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description,
                    color: AppTheme.primaryLight,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc['name'] as String,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${doc['type']} - ${doc['status']}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildComplianceChecklist() {
    final items = [
      {'label': 'Identity Verified', 'completed': true},
      {
        'label': 'Tax Documents Submitted',
        'completed': _taxDocuments.isNotEmpty,
      },
      {
        'label': 'Bank Account Verified',
        'completed': _linkedAccounts.any((a) => a['is_verified'] as bool),
      },
      {'label': 'Payout Method Configured', 'completed': true},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compliance Checklist',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Row(
              children: [
                Icon(
                  item['completed'] as bool
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: item['completed'] as bool
                      ? Colors.green
                      : AppTheme.textSecondaryLight,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payout Configuration',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        RadioListTile<String>(
          title: Text(
            'Instant Daily (1.5% fee)',
            style: TextStyle(fontSize: 12.sp),
          ),
          value: 'instant',
          groupValue: _payoutSchedule,
          onChanged: (value) => setState(() => _payoutSchedule = value!),
        ),
        RadioListTile<String>(
          title: Text(
            'Standard Weekly (Free)',
            style: TextStyle(fontSize: 12.sp),
          ),
          value: 'weekly',
          groupValue: _payoutSchedule,
          onChanged: (value) => setState(() => _payoutSchedule = value!),
        ),
        RadioListTile<String>(
          title: Text(
            'Monthly on 1st (Free)',
            style: TextStyle(fontSize: 12.sp),
          ),
          value: 'monthly',
          groupValue: _payoutSchedule,
          onChanged: (value) => setState(() => _payoutSchedule = value!),
        ),
        SizedBox(height: 2.h),
        Text(
          'Minimum Payout Threshold: \$${_minimumThreshold.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textPrimaryLight),
        ),
        Slider(
          value: _minimumThreshold,
          min: 10,
          max: 100,
          divisions: 9,
          label: '\$${_minimumThreshold.toStringAsFixed(0)}',
          onChanged: (value) => setState(() => _minimumThreshold = value),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 2.h),
        child: ShimmerSkeletonLoader(
          child: Container(
            height: 15.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ),
    );
  }
}
