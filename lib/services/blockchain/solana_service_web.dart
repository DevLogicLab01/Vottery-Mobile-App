import 'package:flutter/foundation.dart';

/// Mint NFT on Solana blockchain (web stub - not supported)
Future<Map<String, dynamic>?> mintNFTImpl({
  required Map<String, dynamic> metadata,
  required String metadataUri,
}) async {
  debugPrint('Solana minting not supported on web platform');
  return null;
}

/// Get Solana wallet balance (web stub - not supported)
Future<double> getWalletBalanceImpl(String walletAddress) async {
  debugPrint('Solana wallet balance not supported on web platform');
  return 0.0;
}
