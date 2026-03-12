import 'package:flutter/foundation.dart';

import './supabase_service.dart';

/// Admin participation fee controls – Web parity: admin_participation_controls
/// feature_name 'participation_fees', globally_enabled, disabled_countries.
class ParticipationFeeControlsService {
  static ParticipationFeeControlsService? _instance;
  static ParticipationFeeControlsService get instance =>
      _instance ??= ParticipationFeeControlsService._();

  ParticipationFeeControlsService._();

  static const String _featureName = 'participation_fees';

  /// Fetch current controls (global + disabled countries).
  Future<ParticipationFeeControlsState> getControls() async {
    try {
      final res = await SupabaseService.instance.client
          .from('admin_participation_controls')
          .select('globally_enabled, disabled_countries')
          .eq('feature_name', _featureName)
          .maybeSingle();

      if (res == null) {
        return ParticipationFeeControlsState(
          globallyEnabled: false,
          disabledCountries: [],
        );
      }

      final disabled = res['disabled_countries'];
      return ParticipationFeeControlsState(
        globallyEnabled: res['globally_enabled'] == true,
        disabledCountries: disabled is List
            ? List<String>.from(disabled.map((e) => e.toString()))
            : [],
      );
    } catch (e) {
      debugPrint('ParticipationFeeControlsService getControls: $e');
      return ParticipationFeeControlsState(
        globallyEnabled: false,
        disabledCountries: [],
      );
    }
  }

  /// Toggle global participation fee on/off.
  Future<String?> setGlobalEnabled(bool enabled) async {
    try {
      await SupabaseService.instance.client
          .from('admin_participation_controls')
          .update({
        'globally_enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('feature_name', _featureName);
      return null;
    } catch (e) {
      debugPrint('ParticipationFeeControlsService setGlobalEnabled: $e');
      return e.toString();
    }
  }

  /// Toggle a country: add to or remove from disabled list.
  Future<String?> toggleCountry(String countryCode) async {
    try {
      final state = await getControls();
      final disabled = List<String>.from(state.disabledCountries);
      if (disabled.contains(countryCode)) {
        disabled.remove(countryCode);
      } else {
        disabled.add(countryCode);
      }
      await SupabaseService.instance.client
          .from('admin_participation_controls')
          .update({
        'disabled_countries': disabled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('feature_name', _featureName);
      return null;
    } catch (e) {
      debugPrint('ParticipationFeeControlsService toggleCountry: $e');
      return e.toString();
    }
  }
}

class ParticipationFeeControlsState {
  final bool globallyEnabled;
  final List<String> disabledCountries;

  ParticipationFeeControlsState({
    required this.globallyEnabled,
    required this.disabledCountries,
  });
}
