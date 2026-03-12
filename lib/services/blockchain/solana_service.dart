import 'solana_service_stub.dart'
    if (dart.library.io) 'solana_service_io.dart'
    if (dart.library.html) 'solana_service_web.dart';

/// Solana Service with conditional imports for web compatibility
class SolanaService {
  static SolanaService? _instance;
  static SolanaService get instance => _instance ??= SolanaService._();

  SolanaService._();

  /// Mint NFT on Solana blockchain
  Future<Map<String, dynamic>?> mintNFT({
    required Map<String, dynamic> metadata,
    required String metadataUri,
  }) async {
    return await mintNFTImpl(metadata: metadata, metadataUri: metadataUri);
  }

  /// Get Solana wallet balance
  Future<double> getWalletBalance(String walletAddress) async {
    return await getWalletBalanceImpl(walletAddress);
  }
}
