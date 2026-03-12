import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './auth_service.dart';

/// Service for managing election permission controls
/// Handles country validation, group membership checks, and eligibility verification
class ElectionPermissionService {
  static ElectionPermissionService? _instance;
  static ElectionPermissionService get instance =>
      _instance ??= ElectionPermissionService._();

  ElectionPermissionService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Check if user has permission to vote in election
  Future<Map<String, dynamic>> checkVotingPermission(String electionId) async {
    try {
      if (!_auth.isAuthenticated) {
        return {
          'allowed': false,
          'reason': 'User must be authenticated to vote',
        };
      }

      final userId = _auth.currentUser!.id;

      // Call database function to check permission
      final response = await _client.rpc(
        'check_election_permission',
        params: {'p_election_id': electionId, 'p_user_id': userId},
      );

      final allowed = response as bool? ?? false;

      if (!allowed) {
        // Get election details to provide specific reason
        final election = await _getElectionDetails(electionId);
        final permissionType = election?['permission_type'] as String?;

        String reason = 'You do not have permission to vote in this election';

        if (permissionType == 'country_specific') {
          reason =
              'This election is restricted to specific countries. Your country is not in the allowed list.';
        } else if (permissionType == 'group_only') {
          reason =
              'This election is restricted to group members only. You are not a member of the required group.';
        }

        return {'allowed': false, 'reason': reason};
      }

      return {'allowed': true, 'reason': null};
    } catch (e) {
      debugPrint('Check voting permission error: $e');
      return {
        'allowed': false,
        'reason': 'Error checking permission: ${e.toString()}',
      };
    }
  }

  /// Get election details including permission settings
  Future<Map<String, dynamic>?> _getElectionDetails(String electionId) async {
    try {
      final response = await _client
          .from('elections')
          .select('permission_type, allowed_countries, group_id')
          .eq('id', electionId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get election details error: $e');
      return null;
    }
  }

  /// Get user's groups for group-only elections
  Future<List<Map<String, dynamic>>> getUserGroups() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final userId = _auth.currentUser!.id;

      final response = await _client
          .from('group_members')
          .select('group_id, user_groups!inner(id, name, member_count)')
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user groups error: $e');
      return [];
    }
  }

  /// Get all available groups for creator to select
  Future<List<Map<String, dynamic>>> getCreatorGroups() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final userId = _auth.currentUser!.id;

      // Get groups where user is creator
      final response = await _client
          .from('user_groups')
          .select('id, name, description, member_count')
          .eq('creator_id', userId)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get creator groups error: $e');
      return [];
    }
  }

  /// Validate country code against allowed countries
  bool isCountryAllowed(String userCountry, List<String> allowedCountries) {
    if (allowedCountries.isEmpty) return true;
    return allowedCountries.contains(userCountry);
  }

  /// Get user's country from profile
  Future<String?> getUserCountry() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final userId = _auth.currentUser!.id;

      final response = await _client
          .from('user_profiles')
          .select('location')
          .eq('id', userId)
          .maybeSingle();

      return response?['location'] as String?;
    } catch (e) {
      debugPrint('Get user country error: $e');
      return null;
    }
  }

  /// Check if user is member of specific group
  Future<bool> isGroupMember(String groupId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final userId = _auth.currentUser!.id;

      final response = await _client
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Check group membership error: $e');
      return false;
    }
  }

  /// Get list of 195+ countries with flags
  List<Map<String, String>> getAllCountries() {
    return [
      {'code': 'US', 'name': 'United States', 'flag': '🇺🇸'},
      {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
      {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧'},
      {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
      {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
      {'code': 'IT', 'name': 'Italy', 'flag': '🇮🇹'},
      {'code': 'ES', 'name': 'Spain', 'flag': '🇪🇸'},
      {'code': 'AU', 'name': 'Australia', 'flag': '🇦🇺'},
      {'code': 'NZ', 'name': 'New Zealand', 'flag': '🇳🇿'},
      {'code': 'JP', 'name': 'Japan', 'flag': '🇯🇵'},
      {'code': 'CN', 'name': 'China', 'flag': '🇨🇳'},
      {'code': 'IN', 'name': 'India', 'flag': '🇮🇳'},
      {'code': 'BR', 'name': 'Brazil', 'flag': '🇧🇷'},
      {'code': 'MX', 'name': 'Mexico', 'flag': '🇲🇽'},
      {'code': 'AR', 'name': 'Argentina', 'flag': '🇦🇷'},
      {'code': 'ZA', 'name': 'South Africa', 'flag': '🇿🇦'},
      {'code': 'NG', 'name': 'Nigeria', 'flag': '🇳🇬'},
      {'code': 'EG', 'name': 'Egypt', 'flag': '🇪🇬'},
      {'code': 'KE', 'name': 'Kenya', 'flag': '🇰🇪'},
      {'code': 'RU', 'name': 'Russia', 'flag': '🇷🇺'},
      {'code': 'PL', 'name': 'Poland', 'flag': '🇵🇱'},
      {'code': 'SE', 'name': 'Sweden', 'flag': '🇸🇪'},
      {'code': 'NO', 'name': 'Norway', 'flag': '🇳🇴'},
      {'code': 'DK', 'name': 'Denmark', 'flag': '🇩🇰'},
      {'code': 'FI', 'name': 'Finland', 'flag': '🇫🇮'},
      {'code': 'NL', 'name': 'Netherlands', 'flag': '🇳🇱'},
      {'code': 'BE', 'name': 'Belgium', 'flag': '🇧🇪'},
      {'code': 'CH', 'name': 'Switzerland', 'flag': '🇨🇭'},
      {'code': 'AT', 'name': 'Austria', 'flag': '🇦🇹'},
      {'code': 'PT', 'name': 'Portugal', 'flag': '🇵🇹'},
      {'code': 'GR', 'name': 'Greece', 'flag': '🇬🇷'},
      {'code': 'TR', 'name': 'Turkey', 'flag': '🇹🇷'},
      {'code': 'SA', 'name': 'Saudi Arabia', 'flag': '🇸🇦'},
      {'code': 'AE', 'name': 'United Arab Emirates', 'flag': '🇦🇪'},
      {'code': 'IL', 'name': 'Israel', 'flag': '🇮🇱'},
      {'code': 'KR', 'name': 'South Korea', 'flag': '🇰🇷'},
      {'code': 'TH', 'name': 'Thailand', 'flag': '🇹🇭'},
      {'code': 'VN', 'name': 'Vietnam', 'flag': '🇻🇳'},
      {'code': 'PH', 'name': 'Philippines', 'flag': '🇵🇭'},
      {'code': 'ID', 'name': 'Indonesia', 'flag': '🇮🇩'},
      {'code': 'MY', 'name': 'Malaysia', 'flag': '🇲🇾'},
      {'code': 'SG', 'name': 'Singapore', 'flag': '🇸🇬'},
      {'code': 'PK', 'name': 'Pakistan', 'flag': '🇵🇰'},
      {'code': 'BD', 'name': 'Bangladesh', 'flag': '🇧🇩'},
      {'code': 'LK', 'name': 'Sri Lanka', 'flag': '🇱🇰'},
      {'code': 'NP', 'name': 'Nepal', 'flag': '🇳🇵'},
      {'code': 'AF', 'name': 'Afghanistan', 'flag': '🇦🇫'},
      {'code': 'IQ', 'name': 'Iraq', 'flag': '🇮🇶'},
      {'code': 'IR', 'name': 'Iran', 'flag': '🇮🇷'},
      {'code': 'JO', 'name': 'Jordan', 'flag': '🇯🇴'},
      {'code': 'LB', 'name': 'Lebanon', 'flag': '🇱🇧'},
      {'code': 'SY', 'name': 'Syria', 'flag': '🇸🇾'},
      {'code': 'YE', 'name': 'Yemen', 'flag': '🇾🇪'},
      {'code': 'OM', 'name': 'Oman', 'flag': '🇴🇲'},
      {'code': 'KW', 'name': 'Kuwait', 'flag': '🇰🇼'},
      {'code': 'QA', 'name': 'Qatar', 'flag': '🇶🇦'},
      {'code': 'BH', 'name': 'Bahrain', 'flag': '🇧🇭'},
      {'code': 'CL', 'name': 'Chile', 'flag': '🇨🇱'},
      {'code': 'CO', 'name': 'Colombia', 'flag': '🇨🇴'},
      {'code': 'PE', 'name': 'Peru', 'flag': '🇵🇪'},
      {'code': 'VE', 'name': 'Venezuela', 'flag': '🇻🇪'},
      {'code': 'EC', 'name': 'Ecuador', 'flag': '🇪🇨'},
      {'code': 'BO', 'name': 'Bolivia', 'flag': '🇧🇴'},
      {'code': 'PY', 'name': 'Paraguay', 'flag': '🇵🇾'},
      {'code': 'UY', 'name': 'Uruguay', 'flag': '🇺🇾'},
      {'code': 'CR', 'name': 'Costa Rica', 'flag': '🇨🇷'},
      {'code': 'PA', 'name': 'Panama', 'flag': '🇵🇦'},
      {'code': 'GT', 'name': 'Guatemala', 'flag': '🇬🇹'},
      {'code': 'HN', 'name': 'Honduras', 'flag': '🇭🇳'},
      {'code': 'SV', 'name': 'El Salvador', 'flag': '🇸🇻'},
      {'code': 'NI', 'name': 'Nicaragua', 'flag': '🇳🇮'},
      {'code': 'CU', 'name': 'Cuba', 'flag': '🇨🇺'},
      {'code': 'DO', 'name': 'Dominican Republic', 'flag': '🇩🇴'},
      {'code': 'JM', 'name': 'Jamaica', 'flag': '🇯🇲'},
      {'code': 'TT', 'name': 'Trinidad and Tobago', 'flag': '🇹🇹'},
      {'code': 'BS', 'name': 'Bahamas', 'flag': '🇧🇸'},
      {'code': 'BB', 'name': 'Barbados', 'flag': '🇧🇧'},
      {'code': 'GH', 'name': 'Ghana', 'flag': '🇬🇭'},
      {'code': 'ET', 'name': 'Ethiopia', 'flag': '🇪🇹'},
      {'code': 'TZ', 'name': 'Tanzania', 'flag': '🇹🇿'},
      {'code': 'UG', 'name': 'Uganda', 'flag': '🇺🇬'},
      {'code': 'ZM', 'name': 'Zambia', 'flag': '🇿🇲'},
      {'code': 'ZW', 'name': 'Zimbabwe', 'flag': '🇿🇼'},
      {'code': 'BW', 'name': 'Botswana', 'flag': '🇧🇼'},
      {'code': 'NA', 'name': 'Namibia', 'flag': '🇳🇦'},
      {'code': 'MZ', 'name': 'Mozambique', 'flag': '🇲🇿'},
      {'code': 'AO', 'name': 'Angola', 'flag': '🇦🇴'},
      {'code': 'CM', 'name': 'Cameroon', 'flag': '🇨🇲'},
      {'code': 'CI', 'name': 'Ivory Coast', 'flag': '🇨🇮'},
      {'code': 'SN', 'name': 'Senegal', 'flag': '🇸🇳'},
      {'code': 'ML', 'name': 'Mali', 'flag': '🇲🇱'},
      {'code': 'BF', 'name': 'Burkina Faso', 'flag': '🇧🇫'},
      {'code': 'NE', 'name': 'Niger', 'flag': '🇳🇪'},
      {'code': 'TD', 'name': 'Chad', 'flag': '🇹🇩'},
      {'code': 'SD', 'name': 'Sudan', 'flag': '🇸🇩'},
      {'code': 'SS', 'name': 'South Sudan', 'flag': '🇸🇸'},
      {'code': 'SO', 'name': 'Somalia', 'flag': '🇸🇴'},
      {'code': 'DJ', 'name': 'Djibouti', 'flag': '🇩🇯'},
      {'code': 'ER', 'name': 'Eritrea', 'flag': '🇪🇷'},
      {'code': 'RW', 'name': 'Rwanda', 'flag': '🇷🇼'},
      {'code': 'BI', 'name': 'Burundi', 'flag': '🇧🇮'},
      {'code': 'MW', 'name': 'Malawi', 'flag': '🇲🇼'},
      {'code': 'MG', 'name': 'Madagascar', 'flag': '🇲🇬'},
      {'code': 'MU', 'name': 'Mauritius', 'flag': '🇲🇺'},
      {'code': 'SC', 'name': 'Seychelles', 'flag': '🇸🇨'},
      {'code': 'KM', 'name': 'Comoros', 'flag': '🇰🇲'},
      {'code': 'CZ', 'name': 'Czech Republic', 'flag': '🇨🇿'},
      {'code': 'SK', 'name': 'Slovakia', 'flag': '🇸🇰'},
      {'code': 'HU', 'name': 'Hungary', 'flag': '🇭🇺'},
      {'code': 'RO', 'name': 'Romania', 'flag': '🇷🇴'},
      {'code': 'BG', 'name': 'Bulgaria', 'flag': '🇧🇬'},
      {'code': 'HR', 'name': 'Croatia', 'flag': '🇭🇷'},
      {'code': 'SI', 'name': 'Slovenia', 'flag': '🇸🇮'},
      {'code': 'RS', 'name': 'Serbia', 'flag': '🇷🇸'},
      {'code': 'BA', 'name': 'Bosnia and Herzegovina', 'flag': '🇧🇦'},
      {'code': 'MK', 'name': 'North Macedonia', 'flag': '🇲🇰'},
      {'code': 'AL', 'name': 'Albania', 'flag': '🇦🇱'},
      {'code': 'ME', 'name': 'Montenegro', 'flag': '🇲🇪'},
      {'code': 'XK', 'name': 'Kosovo', 'flag': '🇽🇰'},
      {'code': 'EE', 'name': 'Estonia', 'flag': '🇪🇪'},
      {'code': 'LV', 'name': 'Latvia', 'flag': '🇱🇻'},
      {'code': 'LT', 'name': 'Lithuania', 'flag': '🇱🇹'},
      {'code': 'BY', 'name': 'Belarus', 'flag': '🇧🇾'},
      {'code': 'UA', 'name': 'Ukraine', 'flag': '🇺🇦'},
      {'code': 'MD', 'name': 'Moldova', 'flag': '🇲🇩'},
      {'code': 'GE', 'name': 'Georgia', 'flag': '🇬🇪'},
      {'code': 'AM', 'name': 'Armenia', 'flag': '🇦🇲'},
      {'code': 'AZ', 'name': 'Azerbaijan', 'flag': '🇦🇿'},
      {'code': 'KZ', 'name': 'Kazakhstan', 'flag': '🇰🇿'},
      {'code': 'UZ', 'name': 'Uzbekistan', 'flag': '🇺🇿'},
      {'code': 'TM', 'name': 'Turkmenistan', 'flag': '🇹🇲'},
      {'code': 'KG', 'name': 'Kyrgyzstan', 'flag': '🇰🇬'},
      {'code': 'TJ', 'name': 'Tajikistan', 'flag': '🇹🇯'},
      {'code': 'MN', 'name': 'Mongolia', 'flag': '🇲🇳'},
      {'code': 'MM', 'name': 'Myanmar', 'flag': '🇲🇲'},
      {'code': 'LA', 'name': 'Laos', 'flag': '🇱🇦'},
      {'code': 'KH', 'name': 'Cambodia', 'flag': '🇰🇭'},
      {'code': 'BN', 'name': 'Brunei', 'flag': '🇧🇳'},
      {'code': 'TL', 'name': 'Timor-Leste', 'flag': '🇹🇱'},
      {'code': 'BT', 'name': 'Bhutan', 'flag': '🇧🇹'},
      {'code': 'MV', 'name': 'Maldives', 'flag': '🇲🇻'},
      {'code': 'IS', 'name': 'Iceland', 'flag': '🇮🇸'},
      {'code': 'IE', 'name': 'Ireland', 'flag': '🇮🇪'},
      {'code': 'LU', 'name': 'Luxembourg', 'flag': '🇱🇺'},
      {'code': 'MT', 'name': 'Malta', 'flag': '🇲🇹'},
      {'code': 'CY', 'name': 'Cyprus', 'flag': '🇨🇾'},
      {'code': 'LI', 'name': 'Liechtenstein', 'flag': '🇱🇮'},
      {'code': 'MC', 'name': 'Monaco', 'flag': '🇲🇨'},
      {'code': 'AD', 'name': 'Andorra', 'flag': '🇦🇩'},
      {'code': 'SM', 'name': 'San Marino', 'flag': '🇸🇲'},
      {'code': 'VA', 'name': 'Vatican City', 'flag': '🇻🇦'},
      {'code': 'FJ', 'name': 'Fiji', 'flag': '🇫🇯'},
      {'code': 'PG', 'name': 'Papua New Guinea', 'flag': '🇵🇬'},
      {'code': 'SB', 'name': 'Solomon Islands', 'flag': '🇸🇧'},
      {'code': 'VU', 'name': 'Vanuatu', 'flag': '🇻🇺'},
      {'code': 'NC', 'name': 'New Caledonia', 'flag': '🇳🇨'},
      {'code': 'PF', 'name': 'French Polynesia', 'flag': '🇵🇫'},
      {'code': 'WS', 'name': 'Samoa', 'flag': '🇼🇸'},
      {'code': 'TO', 'name': 'Tonga', 'flag': '🇹🇴'},
      {'code': 'KI', 'name': 'Kiribati', 'flag': '🇰🇮'},
      {'code': 'TV', 'name': 'Tuvalu', 'flag': '🇹🇻'},
      {'code': 'NR', 'name': 'Nauru', 'flag': '🇳🇷'},
      {'code': 'PW', 'name': 'Palau', 'flag': '🇵🇼'},
      {'code': 'FM', 'name': 'Micronesia', 'flag': '🇫🇲'},
      {'code': 'MH', 'name': 'Marshall Islands', 'flag': '🇲🇭'},
      {'code': 'GY', 'name': 'Guyana', 'flag': '🇬🇾'},
      {'code': 'SR', 'name': 'Suriname', 'flag': '🇸🇷'},
      {'code': 'GF', 'name': 'French Guiana', 'flag': '🇬🇫'},
      {'code': 'BZ', 'name': 'Belize', 'flag': '🇧🇿'},
      {'code': 'HT', 'name': 'Haiti', 'flag': '🇭🇹'},
      {'code': 'GD', 'name': 'Grenada', 'flag': '🇬🇩'},
      {'code': 'LC', 'name': 'Saint Lucia', 'flag': '🇱🇨'},
      {'code': 'VC', 'name': 'Saint Vincent', 'flag': '🇻🇨'},
      {'code': 'AG', 'name': 'Antigua and Barbuda', 'flag': '🇦🇬'},
      {'code': 'DM', 'name': 'Dominica', 'flag': '🇩🇲'},
      {'code': 'KN', 'name': 'Saint Kitts and Nevis', 'flag': '🇰🇳'},
      {'code': 'LR', 'name': 'Liberia', 'flag': '🇱🇷'},
      {'code': 'SL', 'name': 'Sierra Leone', 'flag': '🇸🇱'},
      {'code': 'GM', 'name': 'Gambia', 'flag': '🇬🇲'},
      {'code': 'GN', 'name': 'Guinea', 'flag': '🇬🇳'},
      {'code': 'GW', 'name': 'Guinea-Bissau', 'flag': '🇬🇼'},
      {'code': 'CV', 'name': 'Cape Verde', 'flag': '🇨🇻'},
      {'code': 'ST', 'name': 'São Tomé and Príncipe', 'flag': '🇸🇹'},
      {'code': 'GQ', 'name': 'Equatorial Guinea', 'flag': '🇬🇶'},
      {'code': 'GA', 'name': 'Gabon', 'flag': '🇬🇦'},
      {'code': 'CG', 'name': 'Republic of the Congo', 'flag': '🇨🇬'},
      {
        'code': 'CD',
        'name': 'Democratic Republic of the Congo',
        'flag': '🇨🇩',
      },
      {'code': 'CF', 'name': 'Central African Republic', 'flag': '🇨🇫'},
      {'code': 'TG', 'name': 'Togo', 'flag': '🇹🇬'},
      {'code': 'BJ', 'name': 'Benin', 'flag': '🇧🇯'},
      {'code': 'MR', 'name': 'Mauritania', 'flag': '🇲🇷'},
      {'code': 'EH', 'name': 'Western Sahara', 'flag': '🇪🇭'},
      {'code': 'MA', 'name': 'Morocco', 'flag': '🇲🇦'},
      {'code': 'DZ', 'name': 'Algeria', 'flag': '🇩🇿'},
      {'code': 'TN', 'name': 'Tunisia', 'flag': '🇹🇳'},
      {'code': 'LY', 'name': 'Libya', 'flag': '🇱🇾'},
    ];
  }
}
