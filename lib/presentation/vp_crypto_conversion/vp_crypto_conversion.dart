import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/vp_service.dart';

class VPCryptoConversion extends StatefulWidget {
  const VPCryptoConversion({super.key});

  @override
  State<VPCryptoConversion> createState() => _VPCryptoConversionState();
}

class _VPCryptoConversionState extends State<VPCryptoConversion> {
  final VPService _vpService = VPService.instance;
  final TextEditingController _amountController = TextEditingController();
  String _token = 'USDC';
  bool _isConverting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    setState(() => _isConverting = true);
    final ok = await _vpService.convertVPToCrypto(
      token: _token,
      vpAmount: amount,
      exchangeRate: 1000.0,
    );
    if (!mounted) return;

    setState(() => _isConverting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Conversion request submitted' : 'Conversion failed'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VP Crypto Conversion')),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convert VP to supported crypto at current exchange rates.',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              value: _token,
              decoration: const InputDecoration(
                labelText: 'Token',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'USDC', child: Text('USDC')),
                DropdownMenuItem(value: 'USDT', child: Text('USDT')),
                DropdownMenuItem(value: 'BTC', child: Text('BTC')),
              ],
              onChanged: (v) => setState(() => _token = v ?? _token),
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
                onPressed: _isConverting ? null : _convert,
                child: Text(_isConverting ? 'Processing...' : 'Convert VP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
