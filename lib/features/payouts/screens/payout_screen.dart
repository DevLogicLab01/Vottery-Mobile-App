import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../controllers/payout_controller.dart';
import '../constants/payout_constants.dart';
import '../widgets/threshold_progress_widget.dart';
import '../widgets/balance_card_widget.dart';
import '../widgets/payment_method_card_widget.dart';
import '../widgets/payout_history_widget.dart';
import '../widgets/request_payout_form_widget.dart';

/// YouTube-style payout screen: threshold progress, next payment date,
/// payment method, request form, payment history.
class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  final PayoutController _controller = PayoutController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & payouts'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading earnings...'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _controller.load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BalanceCardWidget(
                    availableBalance: _controller.availableBalance,
                    nextPaymentDate: _controller.nextPaymentDate,
                    formatCurrency: _controller.formatCurrency,
                    currency: _controller.wallet?['currency'] ?? 'USD',
                  ),
                  SizedBox(height: 2.h),
                  ThresholdProgressWidget(
                    availableBalance: _controller.availableBalance,
                    threshold: PayoutConstants.payoutThreshold,
                    amountToThreshold: _controller.amountToThreshold,
                    formatCurrency: _controller.formatCurrency,
                  ),
                  SizedBox(height: 2.h),
                  PaymentMethodCardWidget(settings: _controller.settings),
                  SizedBox(height: 2.h),
                  RequestPayoutFormWidget(
                    availableBalance: _controller.availableBalance,
                    meetsThreshold: _controller.meetsThreshold,
                    threshold: PayoutConstants.payoutThreshold,
                    formatCurrency: _controller.formatCurrency,
                    onRequest: _controller.requestPayout,
                    requesting: _controller.requesting,
                    error: _controller.error,
                    successMessage: _controller.successMessage,
                  ),
                  SizedBox(height: 2.h),
                  PayoutHistoryWidget(
                    history: _controller.history,
                    formatCurrency: _controller.formatCurrency,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
