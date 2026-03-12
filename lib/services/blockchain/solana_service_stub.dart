import 'package:flutter/foundation.dart';

/// Mint NFT on Solana blockchain (stub)
Future<Map<String, dynamic>?> mintNFTImpl({
  required Map<String, dynamic> metadata,
  required String metadataUri,
}) async {
  debugPrint('Solana service stub - not implemented');
  return null;
}

/// Get Solana wallet balance (stub)
Future<double> getWalletBalanceImpl(String walletAddress) async {
  debugPrint('Solana service stub - not implemented');
  return 0.0;
}
