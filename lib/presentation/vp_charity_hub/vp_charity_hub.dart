import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/vp_service.dart';

class VPCharityHub extends StatefulWidget {
  const VPCharityHub({super.key});

  @override
  State<VPCharityHub> createState() => _VPCharityHubState();
}

class _VPCharityHubState extends State<VPCharityHub> {
  final VPService _vpService = VPService.instance;
  final TextEditingController _amountController = TextEditingController();
  String _selectedCharity = 'global_education_fund';
  bool _isSubmitting = false;

  final List<Map<String, String>> _charities = const [
    {'id': 'global_education_fund', 'name': 'Global Education Fund'},
    {'id': 'clean_water_initiative', 'name': 'Clean Water Initiative'},
    {'id': 'healthcare_access_foundation', 'name': 'Healthcare Access Foundation'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitDonation() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    setState(() => _isSubmitting = true);
    final ok = await _vpService.donateVPToCharity(
      charityId: _selectedCharity,
      vpAmount: amount,
    );
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Donation successful' : 'Donation failed'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VP Charity Hub')),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Donate VP to verified charity partners',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              value: _selectedCharity,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select charity',
              ),
              items: _charities
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text(c['name']!),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedCharity = v ?? _selectedCharity),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'VP Amount',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDonation,
                child: Text(_isSubmitting ? 'Submitting...' : 'Donate VP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
