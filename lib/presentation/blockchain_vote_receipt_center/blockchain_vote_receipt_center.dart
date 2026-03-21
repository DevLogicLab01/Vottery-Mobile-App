import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/blockchain_receipt_service.dart';

class BlockchainVoteReceiptCenter extends StatefulWidget {
  const BlockchainVoteReceiptCenter({super.key});

  @override
  State<BlockchainVoteReceiptCenter> createState() =>
      _BlockchainVoteReceiptCenterState();
}

class _BlockchainVoteReceiptCenterState
    extends State<BlockchainVoteReceiptCenter> {
  final BlockchainReceiptService _receiptService = BlockchainReceiptService();
  final TextEditingController _verifyController = TextEditingController();

  List<Map<String, dynamic>> _receipts = [];
  Map<String, dynamic>? _verificationResult;
  bool _isLoading = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _receipts = [];
        _isLoading = false;
      });
      return;
    }

    final receipts = await _receiptService.getUserReceipts(userId);
    setState(() {
      _receipts = receipts;
      _isLoading = false;
    });
  }

  Future<void> _verifyReceipt() async {
    final receiptPayload = _verifyController.text.trim();
    if (receiptPayload.isEmpty) return;

    setState(() => _isVerifying = true);
    final result = await _receiptService.verifyReceipt(receiptPayload);
    setState(() {
      _verificationResult = result;
      _isVerifying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blockchain Vote Receipts'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReceipts),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'My Receipts', icon: Icon(Icons.receipt_long)),
                      Tab(text: 'Verify Receipt', icon: Icon(Icons.verified)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [_buildReceiptsTab(), _buildVerifyTab()],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReceiptsTab() {
    if (_receipts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'No vote receipts yet',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _receipts.length,
      itemBuilder: (context, index) {
        final receipt = _receipts[index];
        return _buildReceiptCard(receipt);
      },
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> receipt) {
    final receiptData = _receiptService.generateReceiptData(receipt);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_vote, color: Theme.of(context).primaryColor),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    receiptData['election_title'],
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildReceiptRow('Vote ID', receiptData['vote_id']),
            _buildReceiptRow('Vote Option', receiptData['vote_option']),
            _buildReceiptRow(
              'Vote Hash',
              receiptData['vote_hash'],
              copyable: true,
            ),
            _buildReceiptRow(
              'Block Number',
              receiptData['block_number'].toString(),
            ),
            _buildReceiptRow(
              'Timestamp',
              _formatTimestamp(receiptData['timestamp']),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _viewOnBlockchain(receiptData['polygonscan_url']),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View on Polygonscan'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                IconButton(
                  onPressed: () => _shareReceipt(receipt),
                  icon: const Icon(Icons.share),
                  tooltip: 'Share Receipt',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 13.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (copyable)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verify Vote Receipt',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  TextField(
                    controller: _verifyController,
                    decoration: const InputDecoration(
                      labelText: 'Paste Receipt JSON',
                      hintText: '{"vote_hash": "...", ...}',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  SizedBox(height: 2.h),
                  ElevatedButton.icon(
                    onPressed: _isVerifying ? null : _verifyReceipt,
                    icon: _isVerifying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_user),
                    label: Text(
                      _isVerifying ? 'Verifying...' : 'Verify Receipt',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_verificationResult != null) ...[
            SizedBox(height: 2.h),
            _buildVerificationResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationResult() {
    final verificationState =
        (_verificationResult!['state'] ?? BlockchainReceiptService.stateFailed)
            .toString();
    final isValid = _verificationResult!['valid'] == true;
    final stateText = {
      BlockchainReceiptService.stateVerified: 'Verified',
      BlockchainReceiptService.statePendingBackend: 'Pending Backend',
      BlockchainReceiptService.stateUnavailable: 'Unavailable',
      BlockchainReceiptService.stateUnsupported: 'Unsupported',
      BlockchainReceiptService.stateFailed: 'Failed',
    }[verificationState]!;

    return Card(
      color: isValid ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? Colors.green : Colors.red,
                  size: 32,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    isValid ? 'Receipt Verified' : 'Verification ${stateText}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isValid ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (!isValid)
              Text(
                'Reason: ${_verificationResult!['reason']}',
                style: TextStyle(fontSize: 14.sp, color: Colors.red[700]),
              )
            else ...[
              Text(
                'This receipt is authentic and recorded on the blockchain.',
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 1.h),
              Text(
                'Verified at: ${_formatTimestamp(_verificationResult!['verified_at'])}',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _viewOnBlockchain(String url) {
    // In production, would open URL in browser
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening: $url')));
  }

  void _shareReceipt(Map<String, dynamic> receipt) {
    final receiptJson = jsonEncode(receipt);
    Clipboard.setData(ClipboardData(text: receiptJson));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt copied to clipboard')),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = DateTime.parse(timestamp.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  void dispose() {
    _verifyController.dispose();
    super.dispose();
  }
}
