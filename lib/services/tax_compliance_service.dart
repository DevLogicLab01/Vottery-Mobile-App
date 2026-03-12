import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// Service for tax compliance document management
class TaxComplianceService {
  static TaxComplianceService? _instance;
  static TaxComplianceService get instance =>
      _instance ??= TaxComplianceService._();

  TaxComplianceService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  static const String taxDocumentsBucket = 'tax-documents';

  /// Get all tax documents for current creator
  Future<List<Map<String, dynamic>>> getTaxDocuments({
    int? taxYear,
    String? documentType,
    String? status,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      var query = _client
          .from('tax_compliance_documents')
          .select()
          .eq('creator_id', _auth.currentUser!.id);

      if (taxYear != null) {
        query = query.eq('tax_year', taxYear);
      }

      if (documentType != null) {
        query = query.eq('document_type', documentType);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get tax documents error: $e');
      return [];
    }
  }

  /// Stream tax documents for real-time updates
  Stream<List<Map<String, dynamic>>> streamTaxDocuments() {
    if (!_auth.isAuthenticated) {
      return Stream.value([]);
    }

    return _client
        .from('tax_compliance_documents')
        .stream(primaryKey: ['id'])
        .eq('creator_id', _auth.currentUser!.id)
        .order('created_at', ascending: false);
  }

  /// Get expiring documents
  Future<List<Map<String, dynamic>>> getExpiringDocuments({
    int daysThreshold = 90,
  }) async {
    try {
      final response = await _client.rpc(
        'get_expiring_tax_documents',
        params: {'p_days_threshold': daysThreshold},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get expiring documents error: $e');
      return [];
    }
  }

  /// Generate tax document (1099-NEC, W-8BEN, etc.)
  Future<bool> generateTaxDocument({
    required String documentType,
    required int taxYear,
    required String jurisdictionCode,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('tax_compliance_documents').insert({
        'creator_id': _auth.currentUser!.id,
        'document_type': documentType,
        'tax_year': taxYear,
        'jurisdiction_code': jurisdictionCode,
        'status': 'pending',
      });

      return true;
    } catch (e) {
      debugPrint('Generate tax document error: $e');
      return false;
    }
  }

  /// Upload tax document file
  Future<String?> uploadTaxDocument({
    required String documentId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final filePath = '${_auth.currentUser!.id}/$documentId/$fileName';
      await _client.storage
          .from(taxDocumentsBucket)
          .uploadBinary(
            filePath,
            Uint8List.fromList(fileBytes),
            fileOptions: FileOptions(
              contentType: _getContentType(fileName),
              upsert: true,
            ),
          );

      final documentUrl = _client.storage
          .from(taxDocumentsBucket)
          .getPublicUrl(filePath);

      // Update document record with file URL
      await _client
          .from('tax_compliance_documents')
          .update({
            'file_url': documentUrl,
            'file_name': fileName,
            'file_size': fileBytes.length,
            'status': 'generated',
          })
          .eq('id', documentId);

      return documentUrl;
    } catch (e) {
      debugPrint('Upload tax document error: $e');
      return null;
    }
  }

  /// Get jurisdiction registrations
  Future<List<Map<String, dynamic>>> getJurisdictionRegistrations() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('tax_jurisdiction_registrations')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .order('jurisdiction_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get jurisdiction registrations error: $e');
      return [];
    }
  }

  /// Update jurisdiction registration
  Future<bool> updateJurisdictionRegistration({
    required String jurisdictionCode,
    required String jurisdictionName,
    String? registrationNumber,
    DateTime? registrationDate,
    bool? isActive,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('tax_jurisdiction_registrations').upsert({
        'creator_id': _auth.currentUser!.id,
        'jurisdiction_code': jurisdictionCode,
        'jurisdiction_name': jurisdictionName,
        'registration_number': registrationNumber,
        'registration_date': registrationDate?.toIso8601String().split('T')[0],
        'is_active': isActive ?? true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Update jurisdiction registration error: $e');
      return false;
    }
  }

  /// Get compliance status summary
  Future<Map<String, dynamic>> getComplianceStatus() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultComplianceStatus();

      final documents = await getTaxDocuments();
      final expiringDocs = await getExpiringDocuments(daysThreshold: 90);
      final jurisdictions = await getJurisdictionRegistrations();

      final validDocs = documents
          .where((d) => d['status'] == 'generated')
          .length;
      final expiredDocs = documents
          .where((d) => d['status'] == 'expired')
          .length;

      final complianceScore = jurisdictions.isEmpty
          ? 0
          : ((validDocs / documents.length) * 100).round();

      return {
        'total_documents': documents.length,
        'valid_documents': validDocs,
        'expired_documents': expiredDocs,
        'expiring_soon': expiringDocs.length,
        'jurisdictions_registered': jurisdictions.length,
        'compliance_score': complianceScore,
      };
    } catch (e) {
      debugPrint('Get compliance status error: $e');
      return _getDefaultComplianceStatus();
    }
  }

  /// Get tax notification preferences
  Future<List<Map<String, dynamic>>> getTaxNotificationPreferences() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('tax_notification_preferences')
          .select()
          .eq('creator_id', _auth.currentUser!.id);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get tax notification preferences error: $e');
      return [];
    }
  }

  /// Update tax notification preference
  Future<bool> updateTaxNotificationPreference({
    required String notificationType,
    bool? emailEnabled,
    bool? pushEnabled,
    bool? smsEnabled,
    String? preferredTime,
    String? timezone,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (emailEnabled != null) updates['email_enabled'] = emailEnabled;
      if (pushEnabled != null) updates['push_enabled'] = pushEnabled;
      if (smsEnabled != null) updates['sms_enabled'] = smsEnabled;
      if (preferredTime != null) updates['preferred_time'] = preferredTime;
      if (timezone != null) updates['timezone'] = timezone;

      await _client.from('tax_notification_preferences').upsert({
        'creator_id': _auth.currentUser!.id,
        'notification_type': notificationType,
        ...updates,
      });

      return true;
    } catch (e) {
      debugPrint('Update tax notification preference error: $e');
      return false;
    }
  }

  /// Get tax notification history
  Future<List<Map<String, dynamic>>> getTaxNotificationHistory({
    int limit = 50,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('tax_notification_history')
          .select(
            '*, tax_compliance_documents!document_id(document_type, tax_year)',
          )
          .eq('creator_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get tax notification history error: $e');
      return [];
    }
  }

  /// Schedule tax expiration notifications (called by cron job)
  Future<int> scheduleTaxExpirationNotifications() async {
    try {
      final response = await _client.rpc(
        'schedule_tax_expiration_notifications',
      );
      return response as int? ?? 0;
    } catch (e) {
      debugPrint('Schedule tax expiration notifications error: $e');
      return 0;
    }
  }

  /// Send tax compliance report via email
  Future<bool> sendTaxComplianceReport({
    required String reportId,
    required String recipientEmail,
    required String jurisdiction,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-compliance-report',
        body: {
          'report_id': reportId,
          'recipient_email': recipientEmail,
          'jurisdiction': jurisdiction,
        },
      );

      return response.data?['success'] == true;
    } catch (e) {
      debugPrint('Send tax compliance report error: $e');
      return false;
    }
  }

  /// Get notification delivery statistics
  Future<Map<String, dynamic>> getNotificationDeliveryStats() async {
    try {
      if (!_auth.isAuthenticated) return {};

      final response = await _client
          .from('tax_notification_history')
          .select('status, channel')
          .eq('creator_id', _auth.currentUser!.id);

      final stats = <String, dynamic>{
        'total_sent': 0,
        'total_delivered': 0,
        'total_opened': 0,
        'total_clicked': 0,
        'total_failed': 0,
        'by_channel': <String, int>{},
      };

      for (final notification in response) {
        final status = notification['status'] as String?;
        final channel = notification['channel'] as String?;

        if (status == 'sent' || status == 'delivered') {
          stats['total_sent'] = (stats['total_sent'] as int) + 1;
        }
        if (status == 'delivered') {
          stats['total_delivered'] = (stats['total_delivered'] as int) + 1;
        }
        if (status == 'opened') {
          stats['total_opened'] = (stats['total_opened'] as int) + 1;
        }
        if (status == 'clicked') {
          stats['total_clicked'] = (stats['total_clicked'] as int) + 1;
        }
        if (status == 'failed') {
          stats['total_failed'] = (stats['total_failed'] as int) + 1;
        }

        if (channel != null) {
          final byChannel = stats['by_channel'] as Map<String, int>;
          byChannel[channel] = (byChannel[channel] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('Get notification delivery stats error: $e');
      return {};
    }
  }

  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Map<String, dynamic> _getDefaultComplianceStatus() {
    return {
      'total_documents': 0,
      'valid_documents': 0,
      'expired_documents': 0,
      'expiring_soon': 0,
      'jurisdictions_registered': 0,
      'compliance_score': 0,
    };
  }
}
