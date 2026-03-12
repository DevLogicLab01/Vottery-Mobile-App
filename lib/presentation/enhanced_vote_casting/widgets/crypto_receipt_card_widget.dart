import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

/// Cryptographic receipt card shown after vote submission
class CryptoReceiptCardWidget extends StatelessWidget {
  final String receiptId;
  final String voteHash;
  final String signature;
  final String timestamp;
  final String electionId;
  final VoidCallback? onDownloadPdf;

  const CryptoReceiptCardWidget({
    super.key,
    required this.receiptId,
    required this.voteHash,
    required this.signature,
    required this.timestamp,
    required this.electionId,
    this.onDownloadPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.green.withAlpha(100), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user,
                  color: Colors.green,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cryptographic Vote Receipt',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Your vote is secured on the blockchain',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDownloadPdf != null)
                IconButton(
                  icon: Icon(
                    Icons.download,
                    color: AppTheme.primaryLight,
                    size: 6.w,
                  ),
                  onPressed: onDownloadPdf,
                  tooltip: 'Export as PDF',
                ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildReceiptField('Receipt ID', receiptId),
          _buildReceiptField(
            'Vote Hash (keccak256)',
            voteHash.length > 20 ? '${voteHash.substring(0, 20)}...' : voteHash,
          ),
          _buildReceiptField(
            'ECDSA Signature',
            signature.length > 20
                ? '${signature.substring(0, 20)}...'
                : signature,
          ),
          _buildReceiptField('Timestamp', timestamp),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(15),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.green, size: 4.w),
                SizedBox(width: 1.5.w),
                Expanded(
                  child: Text(
                    'Stored in blockchain_vote_receipts table. Verifiable on-chain.',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptField(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: AppTheme.textPrimaryLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}