import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './unified_sms_service.dart';

/// SMS Alert Template Service
/// Manages alert templates with variable insertion and rendering
class SMSAlertTemplateService {
  static SMSAlertTemplateService? _instance;
  static SMSAlertTemplateService get instance =>
      _instance ??= SMSAlertTemplateService._();

  SMSAlertTemplateService._();

  final _supabase = SupabaseService.instance.client;
  final _auth = AuthService.instance;
  final _smsService = UnifiedSMSService.instance;

  /// Get all alert templates
  Future<List<Map<String, dynamic>>> getTemplates({
    String? category,
    String? priority,
    bool? isActive,
  }) async {
    try {
      var query = _supabase.from('sms_alert_templates').select();

      if (category != null) {
        query = query.eq('category', category);
      }
      if (priority != null) {
        query = query.eq('priority', priority);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get templates error: $e');
      return [];
    }
  }

  /// Get template by ID
  Future<Map<String, dynamic>?> getTemplateById(String templateId) async {
    try {
      final response = await _supabase
          .from('sms_alert_templates')
          .select()
          .eq('template_id', templateId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get template by ID error: $e');
      return null;
    }
  }

  /// Create new template
  Future<Map<String, dynamic>?> createTemplate({
    required String templateName,
    required String category,
    required String messageBody,
    required List<Map<String, dynamic>> variables,
    required String priority,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final response = await _supabase
          .from('sms_alert_templates')
          .insert({
            'template_name': templateName,
            'category': category,
            'message_body': messageBody,
            'variables': variables,
            'priority': priority,
            'created_by': _auth.currentUser!.id,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Create template error: $e');
      rethrow;
    }
  }

  /// Update template
  Future<bool> updateTemplate({
    required String templateId,
    String? templateName,
    String? category,
    String? messageBody,
    List<Map<String, dynamic>>? variables,
    String? priority,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (templateName != null) updates['template_name'] = templateName;
      if (category != null) updates['category'] = category;
      if (messageBody != null) updates['message_body'] = messageBody;
      if (variables != null) updates['variables'] = variables;
      if (priority != null) updates['priority'] = priority;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isEmpty) return false;

      updates['updated_at'] = DateTime.now().toIso8601String();

      // Create version history
      if (messageBody != null || variables != null) {
        await _createTemplateVersion(
          templateId: templateId,
          messageBody: messageBody ?? '',
          variables: variables ?? [],
        );
      }

      await _supabase
          .from('sms_alert_templates')
          .update(updates)
          .eq('template_id', templateId);

      return true;
    } catch (e) {
      debugPrint('Update template error: $e');
      return false;
    }
  }

  /// Delete template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      await _supabase
          .from('sms_alert_templates')
          .delete()
          .eq('template_id', templateId);

      return true;
    } catch (e) {
      debugPrint('Delete template error: $e');
      return false;
    }
  }

  /// Create template version
  Future<void> _createTemplateVersion({
    required String templateId,
    required String messageBody,
    required List<Map<String, dynamic>> variables,
  }) async {
    try {
      // Get current version number
      final versions = await _supabase
          .from('sms_template_versions')
          .select('version_number')
          .eq('template_id', templateId)
          .order('version_number', ascending: false)
          .limit(1);

      final nextVersion = versions.isEmpty
          ? 1
          : (versions[0]['version_number'] as int) + 1;

      await _supabase.from('sms_template_versions').insert({
        'template_id': templateId,
        'version_number': nextVersion,
        'message_body': messageBody,
        'variables': variables,
        'changed_by': _auth.currentUser?.id,
      });
    } catch (e) {
      debugPrint('Create template version error: $e');
    }
  }

  /// Get template versions
  Future<List<Map<String, dynamic>>> getTemplateVersions(
    String templateId,
  ) async {
    try {
      final response = await _supabase
          .from('sms_template_versions')
          .select()
          .eq('template_id', templateId)
          .order('version_number', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get template versions error: $e');
      return [];
    }
  }

  /// Insert variables into template
  String insertVariables(String templateBody, Map<String, dynamic> variables) {
    String result = templateBody;

    variables.forEach((key, value) {
      final placeholder = '{$key}';
      if (result.contains(placeholder)) {
        final formattedValue = _formatVariableValue(key, value);
        result = result.replaceAll(placeholder, formattedValue);
      }
    });

    // Check for missing variables
    final missingPattern = RegExp(r'\{([^}]+)\}');
    result = result.replaceAllMapped(missingPattern, (match) {
      return '{MISSING: ${match.group(1)}}';
    });

    return result;
  }

  /// Format variable value based on type
  String _formatVariableValue(String key, dynamic value) {
    if (value == null) return '';

    // Currency formatting
    if (key.contains('amount') ||
        key.contains('cost') ||
        key.contains('price')) {
      if (value is num) {
        return '\$${value.toStringAsFixed(2)}';
      }
    }

    // Percentage formatting
    if (key.contains('percentage') ||
        key.contains('rate') ||
        key.contains('confidence')) {
      if (value is num) {
        return '${value.toStringAsFixed(1)}%';
      }
    }

    // DateTime formatting
    if (value is DateTime) {
      return '${value.month}/${value.day}/${value.year} ${value.hour}:${value.minute.toString().padLeft(2, '0')}';
    }

    return value.toString();
  }

  /// Send alert using template
  Future<bool> sendAlertFromTemplate({
    required String templateId,
    required String recipientPhone,
    required Map<String, dynamic> variables,
  }) async {
    try {
      // Get template
      final template = await getTemplateById(templateId);
      if (template == null) {
        throw Exception('Template not found');
      }

      // Render message
      final messageBody = insertVariables(
        template['message_body'] as String,
        variables,
      );

      // Send SMS
      final result = await _smsService.sendSMS(
        toPhone: recipientPhone,
        messageBody: messageBody,
        messageType: template['category'] as String,
      );

      // Log alert sent
      await _supabase.from('sms_alerts_sent').insert({
        'template_id': templateId,
        'recipient_phone': recipientPhone,
        'message_body': messageBody,
        'variables_used': variables,
        'provider': result.provider,
        'delivery_status': result.success ? 'sent' : 'failed',
        'provider_message_id': result.messageId,
        'error_message': result.error,
      });

      return result.success;
    } catch (e) {
      debugPrint('Send alert from template error: $e');
      return false;
    }
  }

  /// Test template with sample data
  Future<String> testTemplate({
    required String templateId,
    required Map<String, dynamic> sampleVariables,
  }) async {
    try {
      final template = await getTemplateById(templateId);
      if (template == null) {
        return 'Template not found';
      }

      return insertVariables(
        template['message_body'] as String,
        sampleVariables,
      );
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Get alert sending history
  Future<List<Map<String, dynamic>>> getAlertHistory({
    String? templateId,
    String? deliveryStatus,
    int limit = 50,
  }) async {
    try {
      var query = _supabase.from('sms_alerts_sent').select();

      if (templateId != null) {
        query = query.eq('template_id', templateId);
      }
      if (deliveryStatus != null) {
        query = query.eq('delivery_status', deliveryStatus);
      }

      final response = await query
          .order('sent_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get alert history error: $e');
      return [];
    }
  }
}
