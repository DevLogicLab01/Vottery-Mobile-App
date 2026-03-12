import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// Service for carousel template marketplace operations including creation, listing, purchase, and revenue tracking
class CarouselTemplateMarketplaceService {
  static CarouselTemplateMarketplaceService? _instance;
  static CarouselTemplateMarketplaceService get instance =>
      _instance ??= CarouselTemplateMarketplaceService._();

  CarouselTemplateMarketplaceService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get all approved templates
  Future<List<Map<String, dynamic>>> getMarketplaceTemplates({
    String? category,
    String? searchQuery,
    String? sortBy,
  }) async {
    try {
      var query = _client
          .from('carousel_templates')
          .select('*, user_profiles!creator_user_id(full_name, avatar_url)')
          .eq('status', 'approved');

      if (category != null) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'template_name.ilike.%$searchQuery%,template_description.ilike.%$searchQuery%',
        );
      }

      // Sort options
      final dynamic sortedQuery;
      switch (sortBy) {
        case 'popular':
          sortedQuery = query.order('sales_count', ascending: false);
          break;
        case 'rating':
          sortedQuery = query.order('average_rating', ascending: false);
          break;
        case 'price_low':
          sortedQuery = query.order('price', ascending: true);
          break;
        case 'price_high':
          sortedQuery = query.order('price', ascending: false);
          break;
        default:
          sortedQuery = query.order('created_at', ascending: false);
      }

      final response = await sortedQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get marketplace templates error: $e');
      return [];
    }
  }

  /// Get creator's own templates
  Future<List<Map<String, dynamic>>> getMyTemplates() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('carousel_templates')
          .select()
          .eq('creator_user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get my templates error: $e');
      return [];
    }
  }

  /// Create template
  Future<String?> createTemplate({
    required String templateName,
    required String templateDescription,
    required String category,
    required double price,
    required Map<String, dynamic> templateData,
    List<String>? previewImages,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('carousel_templates')
          .insert({
            'creator_user_id': _auth.currentUser!.id,
            'template_name': templateName,
            'template_description': templateDescription,
            'category': category,
            'price': price,
            'template_data': templateData,
            'preview_images': previewImages ?? [],
            'status': 'pending',
          })
          .select('template_id')
          .single();

      return response['template_id'] as String?;
    } catch (e) {
      debugPrint('Create template error: $e');
      return null;
    }
  }

  /// Update template
  Future<bool> updateTemplate({
    required String templateId,
    String? templateName,
    String? templateDescription,
    double? price,
    Map<String, dynamic>? templateData,
    List<String>? previewImages,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (templateName != null) updates['template_name'] = templateName;
      if (templateDescription != null) {
        updates['template_description'] = templateDescription;
      }
      if (price != null) updates['price'] = price;
      if (templateData != null) updates['template_data'] = templateData;
      if (previewImages != null) updates['preview_images'] = previewImages;

      await _client
          .from('carousel_templates')
          .update(updates)
          .eq('template_id', templateId)
          .eq('creator_user_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Update template error: $e');
      return false;
    }
  }

  /// Purchase template
  Future<String?> purchaseTemplate({
    required String templateId,
    required double amount,
    required String stripePaymentIntentId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('template_purchases')
          .insert({
            'template_id': templateId,
            'buyer_user_id': _auth.currentUser!.id,
            'purchase_amount': amount,
            'stripe_payment_intent_id': stripePaymentIntentId,
            'purchase_status': 'completed',
          })
          .select('purchase_id')
          .single();

      // Update template sales count
      await _client.rpc(
        'increment',
        params: {
          'table_name': 'carousel_templates',
          'row_id': templateId,
          'column_name': 'sales_count',
        },
      );

      return response['purchase_id'] as String?;
    } catch (e) {
      debugPrint('Purchase template error: $e');
      return null;
    }
  }

  /// Get user's purchased templates
  Future<List<Map<String, dynamic>>> getPurchasedTemplates() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('template_purchases')
          .select('*, carousel_templates(*)')
          .eq('buyer_user_id', _auth.currentUser!.id)
          .eq('purchase_status', 'completed')
          .order('purchased_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get purchased templates error: $e');
      return [];
    }
  }

  /// Get template reviews
  Future<List<Map<String, dynamic>>> getTemplateReviews(
    String templateId,
  ) async {
    try {
      final response = await _client
          .from('template_reviews')
          .select('*, user_profiles!buyer_user_id(full_name, avatar_url)')
          .eq('template_id', templateId)
          .order('reviewed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get template reviews error: $e');
      return [];
    }
  }

  /// Submit template review
  Future<bool> submitReview({
    required String templateId,
    required int rating,
    String? reviewText,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('template_reviews').insert({
        'template_id': templateId,
        'buyer_user_id': _auth.currentUser!.id,
        'rating': rating,
        'review_text': reviewText,
      });

      // Update template average rating
      await _updateTemplateRating(templateId);

      return true;
    } catch (e) {
      debugPrint('Submit review error: $e');
      return false;
    }
  }

  /// Update template average rating
  Future<void> _updateTemplateRating(String templateId) async {
    try {
      final reviews = await _client
          .from('template_reviews')
          .select('rating')
          .eq('template_id', templateId);

      if (reviews.isEmpty) return;

      final totalRating = reviews.fold<int>(
        0,
        (sum, review) => sum + (review['rating'] as int),
      );
      final avgRating = totalRating / reviews.length;

      await _client
          .from('carousel_templates')
          .update({'average_rating': avgRating, 'review_count': reviews.length})
          .eq('template_id', templateId);
    } catch (e) {
      debugPrint('Update template rating error: $e');
    }
  }

  /// Get creator revenue from templates
  Future<Map<String, dynamic>> getCreatorRevenue() async {
    try {
      if (!_auth.isAuthenticated) return {};

      final splits = await _client
          .from('template_revenue_splits')
          .select()
          .eq('creator_user_id', _auth.currentUser!.id);

      double totalGross = 0;
      double totalCreatorAmount = 0;
      double totalPlatformFee = 0;
      int pendingPayouts = 0;

      for (final split in splits) {
        totalGross += (split['gross_amount'] as num).toDouble();
        totalCreatorAmount += (split['creator_amount'] as num).toDouble();
        totalPlatformFee += (split['platform_fee'] as num).toDouble();
        if (split['payout_status'] == 'pending') pendingPayouts++;
      }

      return {
        'total_gross': totalGross,
        'total_creator_amount': totalCreatorAmount,
        'total_platform_fee': totalPlatformFee,
        'pending_payouts': pendingPayouts,
        'total_sales': splits.length,
      };
    } catch (e) {
      debugPrint('Get creator revenue error: $e');
      return {};
    }
  }

  /// Get template analytics
  Future<Map<String, dynamic>> getTemplateAnalytics(String templateId) async {
    try {
      final template = await _client
          .from('carousel_templates')
          .select()
          .eq('template_id', templateId)
          .single();

      final purchases = await _client
          .from('template_purchases')
          .select()
          .eq('template_id', templateId)
          .eq('purchase_status', 'completed');

      final reviews = await _client
          .from('template_reviews')
          .select()
          .eq('template_id', templateId);

      return {
        'template': template,
        'total_sales': purchases.length,
        'total_revenue': purchases.fold<double>(
          0,
          (sum, p) => sum + (p['purchase_amount'] as num).toDouble(),
        ),
        'average_rating': template['average_rating'],
        'review_count': reviews.length,
      };
    } catch (e) {
      debugPrint('Get template analytics error: $e');
      return {};
    }
  }

  /// Admin: Approve/reject template
  Future<bool> moderateTemplate({
    required String templateId,
    required String status,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('carousel_templates')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('template_id', templateId);

      return true;
    } catch (e) {
      debugPrint('Moderate template error: $e');
      return false;
    }
  }
}
