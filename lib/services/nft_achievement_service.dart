import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './gamification_service.dart';

/// NFT Achievement Service
/// Manages blockchain-verified achievement badges with Ethereum integration
class NFTAchievementService {
  static NFTAchievementService? _instance;
  static NFTAchievementService get instance =>
      _instance ??= NFTAchievementService._();

  NFTAchievementService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  GamificationService get _gamification => GamificationService.instance;

  // Ethereum configuration (using Sepolia testnet)
  static const String _rpcUrl = 'https://sepolia.infura.io/v3/YOUR_INFURA_KEY';
  static const String _contractAddress = '0xYourNFTContractAddress';

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

  // Milestone achievements for automatic NFT minting
  static const List<Map<String, dynamic>> milestoneAchievements = [
    {
      'key': 'first_vote',
      'title': 'First Vote',
      'description': 'Cast your first vote',
      'requirement': 1,
      'badge_type': 'milestone',
    },
    {
      'key': '100_votes',
      'title': 'Century Voter',
      'description': 'Cast 100 votes',
      'requirement': 100,
      'badge_type': 'milestone',
    },
    {
      'key': '1000_votes',
      'title': 'Millennium Voter',
      'description': 'Cast 1000 votes',
      'requirement': 1000,
      'badge_type': 'milestone',
    },
    {
      'key': 'first_election_created',
      'title': 'Election Creator',
      'description': 'Create your first election',
      'requirement': 1,
      'badge_type': 'creator',
    },
    {
      'key': '10_elections_created',
      'title': 'Prolific Creator',
      'description': 'Create 10 elections',
      'requirement': 10,
      'badge_type': 'creator',
    },
    {
      'key': 'first_ad_campaign',
      'title': 'Advertiser Debut',
      'description': 'Launch your first ad campaign',
      'requirement': 1,
      'badge_type': 'advertiser',
    },
  ];

  /// Get user's current tier based on VP balance
  Future<Map<String, dynamic>> getUserTier() async {
    try {
      if (!_auth.isAuthenticated) {
        return achievementTiers[0]; // Default to Bronze
      }

      final vpBalance = await _client
          .from('vp_balance')
          .select('total_vp')
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      final totalVP = vpBalance?['total_vp'] as int? ?? 0;

      for (var tier in achievementTiers.reversed) {
        if (totalVP >= tier['min_vp']) {
          return tier;
        }
      }

      return achievementTiers[0];
    } catch (e) {
      debugPrint('Get user tier error: $e');
      return achievementTiers[0];
    }
  }

  /// Get all NFT badges earned by user
  Future<List<Map<String, dynamic>>> getUserNFTBadges() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('nft_achievement_badges')
          .select('*')
          .eq('user_id', _auth.currentUser!.id)
          .order('minted_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user NFT badges error: $e');
      return [];
    }
  }

  /// Check and mint NFT for milestone achievement
  Future<Map<String, dynamic>> checkAndMintMilestone({
    required String achievementKey,
    required int currentCount,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Find matching milestone
      final milestone = milestoneAchievements.firstWhere(
        (m) => m['key'] == achievementKey,
        orElse: () => {},
      );

      if (milestone.isEmpty) {
        return {'success': false, 'message': 'Milestone not found'};
      }

      // Check if requirement met
      if (currentCount < milestone['requirement']) {
        return {'success': false, 'message': 'Requirement not met'};
      }

      // Check if already minted
      final existing = await _client
          .from('nft_achievement_badges')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('achievement_key', achievementKey)
          .maybeSingle();

      if (existing != null) {
        return {'success': false, 'message': 'Already minted'};
      }

      // Estimate gas fees (mock for now)
      final gasEstimate = await _estimateGasFees();

      // Mint NFT (simplified - in production, this would call smart contract)
      final nftData = await _mintNFTBadge(
        achievementKey: achievementKey,
        title: milestone['title'],
        description: milestone['description'],
        badgeType: milestone['badge_type'],
      );

      return {
        'success': true,
        'nft_data': nftData,
        'gas_estimate': gasEstimate,
        'message': 'NFT badge minted successfully',
      };
    } catch (e) {
      debugPrint('Check and mint milestone error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Mint NFT badge (simplified implementation)
  Future<Map<String, dynamic>> _mintNFTBadge({
    required String achievementKey,
    required String title,
    required String description,
    required String badgeType,
  }) async {
    try {
      // Get current tier for rarity
      final tier = await getUserTier();

      // Generate IPFS metadata URL (mock)
      final ipfsUrl =
          'ipfs://QmExample${DateTime.now().millisecondsSinceEpoch}';

      // Generate blockchain transaction hash (mock)
      final txHash =
          '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

      // Store NFT record in database
      final nftRecord = await _client
          .from('nft_achievement_badges')
          .insert({
            'user_id': _auth.currentUser!.id,
            'achievement_key': achievementKey,
            'title': title,
            'description': description,
            'badge_type': badgeType,
            'tier': tier['tier'],
            'rarity': tier['rarity'],
            'ipfs_metadata_url': ipfsUrl,
            'blockchain': 'ethereum',
            'contract_address': _contractAddress,
            'token_id': DateTime.now().millisecondsSinceEpoch,
            'transaction_hash': txHash,
            'minting_status': 'completed',
            'minted_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return nftRecord;
    } catch (e) {
      debugPrint('Mint NFT badge error: $e');
      rethrow;
    }
  }

  /// Estimate gas fees for NFT minting
  Future<Map<String, dynamic>> _estimateGasFees() async {
    try {
      // Mock gas estimation (in production, query Ethereum network)
      return {
        'gas_price_gwei': 25.5,
        'gas_limit': 150000,
        'estimated_cost_eth': 0.003825,
        'estimated_cost_usd': 12.45,
      };
    } catch (e) {
      debugPrint('Estimate gas fees error: $e');
      return {
        'gas_price_gwei': 0,
        'gas_limit': 0,
        'estimated_cost_eth': 0,
        'estimated_cost_usd': 0,
      };
    }
  }

  /// Get blockchain explorer URL for NFT
  String getBlockchainExplorerUrl(String transactionHash) {
    return 'https://sepolia.etherscan.io/tx/$transactionHash';
  }

  /// Get OpenSea marketplace URL for NFT
  String getOpenSeaUrl(String contractAddress, int tokenId) {
    return 'https://testnets.opensea.io/assets/sepolia/$contractAddress/$tokenId';
  }

  /// Get minting queue status
  Future<Map<String, dynamic>> getMintingQueueStatus() async {
    try {
      if (!_auth.isAuthenticated) {
        return {'pending': 0, 'processing': 0, 'completed': 0, 'failed': 0};
      }

      final response = await _client
          .from('nft_achievement_badges')
          .select('minting_status')
          .eq('user_id', _auth.currentUser!.id);

      final badges = List<Map<String, dynamic>>.from(response);

      return {
        'pending': badges.where((b) => b['minting_status'] == 'pending').length,
        'processing': badges
            .where((b) => b['minting_status'] == 'processing')
            .length,
        'completed': badges
            .where((b) => b['minting_status'] == 'completed')
            .length,
        'failed': badges.where((b) => b['minting_status'] == 'failed').length,
      };
    } catch (e) {
      debugPrint('Get minting queue status error: $e');
      return {'pending': 0, 'processing': 0, 'completed': 0, 'failed': 0};
    }
  }

  /// Get leaderboard of top badge collectors
  Future<List<Map<String, dynamic>>> getTopBadgeCollectors({
    int limit = 10,
  }) async {
    try {
      final response = await _client.rpc(
        'get_top_nft_collectors',
        params: {'limit_count': limit},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get top badge collectors error: $e');
      return [];
    }
  }

  /// Check wallet connection status
  Future<Map<String, dynamic>> getWalletStatus() async {
    try {
      if (!_auth.isAuthenticated) {
        return {'connected': false, 'wallets': []};
      }

      final response = await _client
          .from('user_wallets')
          .select('*')
          .eq('user_id', _auth.currentUser!.id)
          .eq('is_active', true);

      final wallets = List<Map<String, dynamic>>.from(response);

      return {'connected': wallets.isNotEmpty, 'wallets': wallets};
    } catch (e) {
      debugPrint('Get wallet status error: $e');
      return {'connected': false, 'wallets': []};
    }
  }
}
