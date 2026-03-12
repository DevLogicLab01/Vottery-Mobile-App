import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CompanyInfoStepWidget extends StatefulWidget {
  final Map<String, dynamic>? registration;
  final Function(Map<String, dynamic>) onNext;

  const CompanyInfoStepWidget({
    super.key,
    this.registration,
    required this.onNext,
  });

  @override
  State<CompanyInfoStepWidget> createState() => _CompanyInfoStepWidgetState();
}

class _CompanyInfoStepWidgetState extends State<CompanyInfoStepWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  late TextEditingController _companyEmailController;
  late TextEditingController _companyWebsiteController;
  late TextEditingController _companyPhoneController;
  String _industryClassification = 'Digital Marketing';

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(
      text: widget.registration?['company_name'] ?? '',
    );
    _companyEmailController = TextEditingController(
      text: widget.registration?['company_email'] ?? '',
    );
    _companyWebsiteController = TextEditingController(
      text: widget.registration?['company_website'] ?? '',
    );
    _companyPhoneController = TextEditingController(
      text: widget.registration?['company_phone'] ?? '',
    );
    _industryClassification =
        widget.registration?['industry_classification'] ?? 'Digital Marketing';
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyWebsiteController.dispose();
    _companyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us about your company',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 3.h),
            TextFormField(
              controller: _companyNameController,
              decoration: InputDecoration(
                labelText: 'Company Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Company name is required';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _companyEmailController,
              decoration: InputDecoration(
                labelText: 'Company Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Company email is required';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              initialValue: _industryClassification,
              decoration: InputDecoration(
                labelText: 'Industry Classification *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Digital Marketing',
                  child: Text('Digital Marketing'),
                ),
                DropdownMenuItem(
                  value: 'Brand Management',
                  child: Text('Brand Management'),
                ),
                DropdownMenuItem(
                  value: 'Advertising Agency',
                  child: Text('Advertising Agency'),
                ),
                DropdownMenuItem(
                  value: 'E-commerce',
                  child: Text('E-commerce'),
                ),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() => _industryClassification = value!);
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _companyWebsiteController,
              decoration: InputDecoration(
                labelText: 'Company Website',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _companyPhoneController,
              decoration: InputDecoration(
                labelText: 'Company Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onNext({
                      'company_name': _companyNameController.text,
                      'company_email': _companyEmailController.text,
                      'industry_classification': _industryClassification,
                      'company_website': _companyWebsiteController.text,
                      'company_phone': _companyPhoneController.text,
                    });
                  }
                },
                child: Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
