import 'package:flutter/foundation.dart';

import '../../../../services/auth_service.dart';
import '../api/payout_api.dart';
import '../constants/payout_constants.dart';

/// Holds payout state for YouTube-style screen. Mirrors Web usePayout hook.
class PayoutController extends ChangeNotifier {
  PayoutController() {
    _api = PayoutApi.instance;
    load();
  }

  late final PayoutApi _api;

  Map<String, dynamic>? _wallet;
  Map<String, dynamic>? _settings;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String? _error;
  bool _requesting = false;
  String? _successMessage;

  Map<String, dynamic>? get wallet => _wallet;
  Map<String, dynamic>? get settings => _settings;
  List<Map<String, dynamic>> get history => _history;
  bool get loading => _loading;
  String? get error => _error;
  bool get requesting => _requesting;
  String? get successMessage => _successMessage;

  double get availableBalance =>
      (_wallet != null ? (_wallet!['available_balance'] as num?)?.toDouble() : null) ?? 0.0;

  bool get meetsThreshold => availableBalance >= PayoutConstants.payoutThreshold;

  double get amountToThreshold =>
      (PayoutConstants.payoutThreshold - availableBalance).clamp(0.0, double.infinity);

  String get nextPaymentDate => _api.getNextPaymentDate();

  String formatCurrency(double amount, [String currency = 'USD']) =>
      _api.formatCurrency(amount, currency);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      _wallet = null;
      _settings = null;
      _history = [];
      _loading = false;
      notifyListeners();
      return;
    }

    _wallet = await _api.getWallet();
    _settings = await _api.getPayoutSettings();
    _history = await _api.getPayoutHistory();
    _loading = false;
    notifyListeners();
  }

  Future<bool> requestPayout(double amount, {String method = 'bank_transfer'}) async {
    _error = null;
    _successMessage = null;
    _requesting = true;
    notifyListeners();

    final result = await _api.requestPayout(
      amount: amount,
      method: method,
    );

    _requesting = false;
    if (result.success) {
      _successMessage = PayoutSuccess.requestSubmitted;
      await load();
    } else {
      _error = result.error;
    }
    notifyListeners();
    return result.success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }
}
