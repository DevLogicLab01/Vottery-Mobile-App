import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class CampaignTemplateService {
  static CampaignTemplateService? _instance;
  static CampaignTemplateService get instance =>
      _instance ??= CampaignTemplateService._();

  CampaignTemplateService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get all campaign templates
  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    try {
      final response = await _client
          .from('campaign_templates')
          .select()
          .eq('is_active', true)
          .order('usage_count', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all templates error: $e');
      return [];
    }
  }

  /// Get templates by category
  Future<List<Map<String, dynamic>>> getTemplatesByCategory({
    required String category,
  }) async {
    try {
      final response = await _client
          .from('campaign_templates')
          .select()
          .eq('category', category)
          .eq('is_active', true)
          .order('success_rate', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get templates by category error: $e');
      return [];
    }
  }

  /// Get templates by industry
  Future<List<Map<String, dynamic>>> getTemplatesByIndustry({
    required String industry,
  }) async {
    try {
      final response = await _client
          .from('campaign_templates')
          .select()
          .contains('industry_tags', [industry])
          .eq('is_active', true)
          .order('success_rate', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get templates by industry error: $e');
      return [];
    }
  }

  /// Search templates
  Future<List<Map<String, dynamic>>> searchTemplates({
    required String query,
  }) async {
    try {
      final response = await _client
          .from('campaign_templates')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .eq('is_active', true)
          .order('usage_count', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Search templates error: $e');
      return [];
    }
  }

  /// Get featured templates
  Future<List<Map<String, dynamic>>> getFeaturedTemplates() async {
    try {
      final response = await _client
          .from('campaign_templates')
          .select()
          .eq('is_featured', true)
          .eq('is_active', true)
          .order('success_rate', ascending: false)
          .limit(6);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get featured templates error: $e');
      return [];
    }
  }

  /// Get template by ID
  Future<Map<String, dynamic>?> getTemplateById({
    required String templateId,
  }) async {
    try {
      final response = await _client
          .from('campaign_templates')
          .select()
          .eq('id', templateId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get template by ID error: $e');
      return null;
    }
  }

  /// Apply template to create sponsored election
  Future<Map<String, dynamic>?> applyTemplate({
    required String templateId,
    required String electionId,
    Map<String, dynamic>? customizations,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final template = await getTemplateById(templateId: templateId);
      if (template == null) return null;

      // Merge template configuration with customizations
      final config = {
        ...template['default_configuration'] as Map<String, dynamic>,
        ...?customizations,
      };

      // Increment usage count
      await _client
          .from('campaign_templates')
          .update({'usage_count': (template['usage_count'] as int) + 1})
          .eq('id', templateId);

      return config;
    } catch (e) {
      debugPrint('Apply template error: $e');
      return null;
    }
  }

  /// Favorite template
  Future<bool> favoriteTemplate({required String templateId}) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('template_favorites').insert({
        'user_id': _auth.currentUser!.id,
        'template_id': templateId,
      });

      return true;
    } catch (e) {
      debugPrint('Favorite template error: $e');
      return false;
    }
  }

  /// Unfavorite template
  Future<bool> unfavoriteTemplate({required String templateId}) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('template_favorites')
          .delete()
          .eq('user_id', _auth.currentUser!.id)
          .eq('template_id', templateId);

      return true;
    } catch (e) {
      debugPrint('Unfavorite template error: $e');
      return false;
    }
  }

  /// Get user's favorite templates
  Future<List<Map<String, dynamic>>> getFavoriteTemplates() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('template_favorites')
          .select('template:campaign_templates(*)')
          .eq('user_id', _auth.currentUser!.id);

      return List<Map<String, dynamic>>.from(
        response.map((item) => item['template'] as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('Get favorite templates error: $e');
      return [];
    }
  }

  /// Get template statistics
  Future<Map<String, dynamic>> getTemplateStats({
    required String templateId,
  }) async {
    try {
      final template = await getTemplateById(templateId: templateId);
      if (template == null) return {};

      return {
        'usage_count': template['usage_count'] ?? 0,
        'success_rate': template['success_rate'] ?? 0.0,
        'avg_roi': template['avg_roi'] ?? 0.0,
        'avg_engagement': template['avg_engagement'] ?? 0.0,
        'community_rating': template['community_rating'] ?? 0.0,
      };
    } catch (e) {
      debugPrint('Get template stats error: $e');
      return {};
    }
  }
}
