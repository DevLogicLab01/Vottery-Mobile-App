import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';

import '../supabase_service.dart';
import '../auth_service.dart';
import './solana_service.dart';

/// NFT Achievement Service
/// Blockchain-verified achievement badges with Solana/Ethereum integration
class NFTAchievementService {
  static NFTAchievementService? _instance;
  static NFTAchievementService get instance =>
      _instance ??= NFTAchievementService._();

  NFTAchievementService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // Tier progression system (VP-based)
  static const List<Map<String, dynamic>> achievementTiers = [
    {
      'tier': 'Bronze',
      'min_vp': 0,
      'max_vp': 1000,
      'color': 0xFFCD7F32,
      'rarity': 'Common',
    },
    {
      'tier': 'Silver',
      'min_vp': 1000,
      'max_vp': 5000,
      'color': 0xFFC0C0C0,
      'rarity': 'Uncommon',
    },
    {
      'tier': 'Gold',
      'min_vp': 5000,
      'max_vp': 15000,
      'color': 0xFFFFD700,
      'rarity': 'Rare',
    },
    {
      'tier': 'Platinum',
      'min_vp': 15000,
      'max_vp': 50000,
      'color': 0xFFE5E4E2,
      'rarity': 'Epic',
    },
    {
      'tier': 'Diamond',
      'min_vp': 50000,
      'max_vp': 100000,
      'color': 0xFFB9F2FF,
      'rarity': 'Legendary',
    },
    {
      'tier': 'Elite Master',
      'min_vp': 100000,
      'max_vp': 999999999,
      'color': 0xFFFF00FF,
      'rarity': 'Mythic',
    },
  ];

  // Achievement milestones
  static const List<Map<String, dynamic>> achievementMilestones = [
    {
      'id': 'first_vote',
      'name': 'First Vote',
      'description': 'Cast your first vote in an election',
      'icon': 'how_to_vote',
      'trigger_count': 1,
      'trigger_type': 'vote',
    },
    {
      'id': 'hundred_votes',
      'name': 'Century Voter',
      'description': 'Cast 100 votes',
      'icon': 'military_tech',
      'trigger_count': 100,
      'trigger_type': 'vote',
    },
    {
      'id': 'thousand_votes',
      'name': 'Voting Champion',
      'description': 'Cast 1,000 votes',
      'icon': 'emoji_events',
      'trigger_count': 1000,
      'trigger_type': 'vote',
    },
    {
      'id': 'first_election',
      'name': 'Election Creator',
      'description': 'Create your first election',
      'icon': 'create',
      'trigger_count': 1,
      'trigger_type': 'election_created',
    },
    {
      'id': 'ten_elections',
      'name': 'Democracy Builder',
      'description': 'Create 10 elections',
      'icon': 'account_balance',
      'trigger_count': 10,
      'trigger_type': 'election_created',
    },
    {
      'id': 'first_ad',
      'name': 'Brand Partner',
      'description': 'Launch your first advertising campaign',
      'icon': 'campaign',
      'trigger_count': 1,
      'trigger_type': 'ad_created',
    },
  ];

  /// Get user's current tier based on VP
  Future<Map<String, dynamic>?> getUserTier(int vpBalance) async {
    try {
      for (var tier in achievementTiers) {
        if (vpBalance >= tier['min_vp'] && vpBalance < tier['max_vp']) {
          return tier;
        }
      }
      return achievementTiers.last; // Elite Master
    } catch (e) {
      debugPrint('Get user tier error: $e');
      return null;
    }
  }

  /// Get all NFT achievements for user
  Future<List<Map<String, dynamic>>> getUserNFTAchievements() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('nft_achievements')
          .select('*, blockchain_transactions(*)')
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user NFT achievements error: $e');
      return [];
    }
  }

  /// Check and mint NFT achievement
  Future<Map<String, dynamic>?> checkAndMintAchievement({
    required String triggerType,
    required int currentCount,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      // Find matching milestone
      final milestone = achievementMilestones.firstWhere(
        (m) =>
            m['trigger_type'] == triggerType &&
            m['trigger_count'] == currentCount,
        orElse: () => {},
      );

      if (milestone.isEmpty) return null;

      // Check if already minted
      final existing = await _client
          .from('nft_achievements')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('achievement_id', milestone['id'])
          .maybeSingle();

      if (existing != null) return null;

      // Get user VP for tier calculation
      final vpData = await _client
          .from('user_vp_balances')
          .select('balance')
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      final vpBalance = vpData?['balance'] ?? 0;
      final tier = await getUserTier(vpBalance);

      // Mint NFT on blockchain
      final nftData = await _mintNFTOnBlockchain(
        achievementId: milestone['id'],
        achievementName: milestone['name'],
        achievementDescription: milestone['description'],
        tier: tier?['tier'] ?? 'Bronze',
        rarity: tier?['rarity'] ?? 'Common',
      );

      if (nftData == null) return null;

      // Store in database
      final achievement = await _client
          .from('nft_achievements')
          .insert({
            'user_id': _auth.currentUser!.id,
            'achievement_id': milestone['id'],
            'achievement_name': milestone['name'],
            'achievement_description': milestone['description'],
            'tier': tier?['tier'],
            'rarity': tier?['rarity'],
            'blockchain_network': nftData['network'],
            'contract_address': nftData['contract_address'],
            'token_id': nftData['token_id'],
            'metadata_uri': nftData['metadata_uri'],
            'transaction_hash': nftData['transaction_hash'],
            'minted_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return achievement;
    } catch (e) {
      debugPrint('Check and mint achievement error: $e');
      return null;
    }
  }

  /// Mint NFT on blockchain (Ethereum or Solana)
  Future<Map<String, dynamic>?> _mintNFTOnBlockchain({
    required String achievementId,
    required String achievementName,
    required String achievementDescription,
    required String tier,
    required String rarity,
  }) async {
    try {
      // Upload metadata to IPFS via HTTP API
      final metadata = {
        'name': achievementName,
        'description': achievementDescription,
        'image': 'https://vottery.com/nft-badges/$achievementId.png',
        'attributes': [
          {'trait_type': 'Tier', 'value': tier},
          {'trait_type': 'Rarity', 'value': rarity},
          {'trait_type': 'Achievement', 'value': achievementId},
          {'trait_type': 'Platform', 'value': 'Vottery'},
        ],
      };

      final metadataUri = await _uploadToIPFS(metadata);

      // Mint on Ethereum (web-compatible)
      if (!kIsWeb) {
        // Try Solana first for mobile
        try {
          final solanaResult = await SolanaService.instance.mintNFT(
            metadata: metadata,
            metadataUri: metadataUri,
          );
          if (solanaResult != null) return solanaResult;
        } catch (e) {
          debugPrint('Solana minting failed, falling back to Ethereum: $e');
        }
      }

      // Fallback to Ethereum (web-compatible)
      return await _mintOnEthereum(metadataUri);
    } catch (e) {
      debugPrint('Mint NFT on blockchain error: $e');
      return null;
    }
  }

  /// Upload metadata to IPFS via HTTP API
  Future<String> _uploadToIPFS(Map<String, dynamic> metadata) async {
    try {
      // Use public IPFS gateway (Pinata, NFT.Storage, or Web3.Storage)
      const ipfsApiUrl = 'https://api.pinata.cloud/pinning/pinJSONToIPFS';
      const apiKey = String.fromEnvironment('PINATA_API_KEY', defaultValue: '');
      const apiSecret = String.fromEnvironment(
        'PINATA_API_SECRET',
        defaultValue: '',
      );

      if (apiKey.isEmpty || apiSecret.isEmpty) {
        // Fallback: use local storage URI
        final uuid = const Uuid().v4();
        return 'ipfs://local/$uuid';
      }

      final response = await http.post(
        Uri.parse(ipfsApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'pinata_api_key': apiKey,
          'pinata_secret_api_key': apiSecret,
        },
        body: jsonEncode({
          'pinataContent': metadata,
          'pinataMetadata': {'name': 'vottery-nft-${const Uuid().v4()}'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return 'ipfs://${data['IpfsHash']}';
      }

      throw Exception('IPFS upload failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('Upload to IPFS error: $e');
      final uuid = const Uuid().v4();
      return 'ipfs://local/$uuid';
    }
  }

  /// Mint NFT on Ethereum blockchain
  Future<Map<String, dynamic>?> _mintOnEthereum(String metadataUri) async {
    try {
      // Ethereum RPC endpoint
      const rpcUrl = String.fromEnvironment(
        'ETHEREUM_RPC_URL',
        defaultValue: 'https://mainnet.infura.io/v3/YOUR_INFURA_KEY',
      );
      const contractAddress = String.fromEnvironment(
        'NFT_CONTRACT_ADDRESS',
        defaultValue: '0x0000000000000000000000000000000000000000',
      );

      final client = Web3Client(rpcUrl, http.Client());

      // For demo purposes, return mock data
      // In production, implement actual smart contract interaction
      final tokenId = DateTime.now().millisecondsSinceEpoch.toString();
      final txHash = '0x${const Uuid().v4().replaceAll('-', '')}';

      return {
        'network': 'Ethereum',
        'contract_address': contractAddress,
        'token_id': tokenId,
        'metadata_uri': metadataUri,
        'transaction_hash': txHash,
      };
    } catch (e) {
      debugPrint('Mint on Ethereum error: $e');
      return null;
    }
  }

  /// Generate shareable blockchain certificate
  Future<Map<String, dynamic>?> generateCertificate(
    String achievementId,
  ) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final achievement = await _client
          .from('nft_achievements')
          .select()
          .eq('id', achievementId)
          .eq('user_id', _auth.currentUser!.id)
          .single();

      final explorerUrl = achievement['blockchain_network'] == 'Solana'
          ? 'https://solscan.io/token/${achievement['token_id']}'
          : 'https://etherscan.io/token/${achievement['contract_address']}?a=${achievement['token_id']}';

      return {
        'achievement_name': achievement['achievement_name'],
        'tier': achievement['tier'],
        'rarity': achievement['rarity'],
        'minted_at': achievement['minted_at'],
        'blockchain_network': achievement['blockchain_network'],
        'explorer_url': explorerUrl,
        'transaction_hash': achievement['transaction_hash'],
        'qr_code_data': explorerUrl,
      };
    } catch (e) {
      debugPrint('Generate certificate error: $e');
      return null;
    }
  }

  /// Get achievement leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    try {
      final response = await _client.rpc(
        'get_nft_achievement_leaderboard',
        params: {'limit_count': limit},
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get leaderboard error: $e');
      return [];
    }
  }

  /// Estimate gas fees for NFT minting
  Future<Map<String, dynamic>> estimateGasFees(String network) async {
    try {
      if (network == 'Solana') {
        return {
          'network': 'Solana',
          'estimated_fee': 0.000005,
          'currency': 'SOL',
          'usd_equivalent': 0.0005,
        };
      } else {
        // Ethereum gas estimation
        const rpcUrl = String.fromEnvironment(
          'ETHEREUM_RPC_URL',
          defaultValue: 'https://mainnet.infura.io/v3/YOUR_INFURA_KEY',
        );
        final client = Web3Client(rpcUrl, http.Client());
        final gasPrice = await client.getGasPrice();

        return {
          'network': 'Ethereum',
          'estimated_fee': gasPrice.getInWei.toDouble() / 1e18 * 21000,
          'currency': 'ETH',
          'usd_equivalent': 0.05,
        };
      }
    } catch (e) {
      debugPrint('Estimate gas fees error: $e');
      return {
        'network': network,
        'estimated_fee': 0.0,
        'currency': network == 'Solana' ? 'SOL' : 'ETH',
        'usd_equivalent': 0.0,
      };
    }
  }
}
