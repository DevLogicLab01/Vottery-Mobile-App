import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_service.dart';
import 'supabase_service.dart';

class EnterpriseOperationsService {
  static EnterpriseOperationsService? _instance;
  static EnterpriseOperationsService get instance =>
      _instance ??= EnterpriseOperationsService._();

  EnterpriseOperationsService._();

  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  Future<Map<String, dynamic>?> saveWhiteLabelConfig({
    required String tenantId,
    required String customDomain,
    required String brandName,
    required String primaryColor,
    required bool hideVotteryBranding,
  }) async {
    try {
      final res = await _client.from('enterprise_branding_configs').upsert({
        'tenant_id': tenantId,
        'custom_domain': customDomain,
        'brand_name': brandName,
        'primary_color': primaryColor,
        'hide_vottery_branding': hideVotteryBranding,
      }, onConflict: 'tenant_id').select().single();
      return res;
    } catch (e) {
      debugPrint('saveWhiteLabelConfig error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveSsoConfig({
    required String tenantId,
    required String provider,
    required String clientId,
    required String issuer,
    required String samlEntryPoint,
    required bool enabled,
  }) async {
    try {
      final res = await _client.from('enterprise_sso_configs').upsert({
        'tenant_id': tenantId,
        'provider': provider,
        'client_id': clientId,
        'issuer': issuer,
        'saml_entry_point': samlEntryPoint,
        'enabled': enabled,
      }, onConflict: 'tenant_id').select().single();
      return res;
    } catch (e) {
      debugPrint('saveSsoConfig error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> createBulkElectionsFromCsv({
    required String csvText,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];
      final userId = _auth.currentUser!.id;
      final rows = _parseCsvRows(csvText);
      if (rows.isEmpty) return [];
      final payload = rows
          .map((row) => {
                'title': row['title'] ?? row['name'] ?? 'Untitled Election',
                'description': row['description'] ?? '',
                'status': 'draft',
                'category': row['category'] ?? 'general',
                'created_by': userId,
                'starts_at': row['starts_at'],
                'ends_at': row['ends_at'],
              })
          .toList();
      final response = await _client
          .from('elections')
          .insert(payload)
          .select('id,title,status');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('createBulkElectionsFromCsv error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> saveVolumePricing({
    required String tenantId,
    required num participationDiscountPercent,
    required num bulkVpDiscountPercent,
    required num flatFeeUnlimitedElections,
    required String licenseTerms,
  }) async {
    try {
      final res = await _client.from('enterprise_pricing_models').upsert({
        'tenant_id': tenantId,
        'participation_discount_percent': participationDiscountPercent,
        'bulk_vp_discount_percent': bulkVpDiscountPercent,
        'flat_fee_unlimited_elections': flatFeeUnlimitedElections,
        'license_terms': licenseTerms,
      }, onConflict: 'tenant_id').select().single();
      return res;
    } catch (e) {
      debugPrint('saveVolumePricing error: $e');
      return null;
    }
  }

  Future<bool> sendWhatsAppNotification({
    required String to,
    required String message,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'send-whatsapp-notification',
        body: {
          'to': to,
          'message': message,
          'channel': 'whatsapp',
          // Keep global comms strategy explicit: SMS = Telnyx primary, Twilio fallback.
          'smsProviderStrategy': 'telnyx_primary_twilio_fallback',
        },
      );
      return res.data != null;
    } catch (e) {
      debugPrint('sendWhatsAppNotification error: $e');
      return false;
    }
  }

  Future<bool> initiateEnterpriseSso({
    required String provider,
    required String issuerOrDomain,
  }) async {
    try {
      final normalized = provider.trim().toLowerCase();
      if (kIsWeb &&
          (normalized == 'google' ||
              normalized == 'facebook' ||
              normalized == 'apple')) {
        // Web-native OAuth fallback for providers supported directly in client SDK.
        final oauthProvider = switch (normalized) {
          'google' => OAuthProvider.google,
          'facebook' => OAuthProvider.facebook,
          _ => OAuthProvider.apple,
        };
        return await _client.auth.signInWithOAuth(
          oauthProvider,
          redirectTo: '${Uri.base.origin}/auth/callback',
        );
      }

      // Enterprise SSO for mobile routes through web callback flow.
      final url = Uri.parse(
        'https://vottery.com/enterprise-sso-integration'
        '?provider=${Uri.encodeComponent(provider)}'
        '&issuer=${Uri.encodeComponent(issuerOrDomain)}',
      );
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('initiateEnterpriseSso error: $e');
      return false;
    }
  }

  List<Map<String, String>> _parseCsvRows(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length < 2) return [];
    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    return lines.skip(1).map((line) {
      final cols = line.split(',').map((c) => c.trim()).toList();
      final row = <String, String>{};
      for (var i = 0; i < headers.length; i++) {
        row[headers[i]] = i < cols.length ? cols[i] : '';
      }
      return row;
    }).toList();
  }
}

