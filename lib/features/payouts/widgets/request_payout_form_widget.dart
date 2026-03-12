import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// YouTube-style: Request payout when above threshold. Same validation/errors as API.
class RequestPayoutFormWidget extends StatefulWidget {
  const RequestPayoutFormWidget({
    super.key,
    required this.availableBalance,
    required this.meetsThreshold,
    required this.threshold,
    required this.formatCurrency,
    required this.onRequest,
    required this.requesting,
    this.error,
    this.successMessage,
  });

  final double availableBalance;
  final bool meetsThreshold;
  final double threshold;
  final String Function(double, [String]) formatCurrency;
  final Future<bool> Function(double, {String method}) onRequest;
  final bool requesting;
  final String? error;
  final String? successMessage;

  @override
  State<RequestPayoutFormWidget> createState() => _RequestPayoutFormWidgetState();
}

class _RequestPayoutFormWidgetState extends State<RequestPayoutFormWidget> {
  final _amountController = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _amountController.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (!widget.meetsThreshold || amount < widget.threshold) return;
    final success = await widget.onRequest(amount, method: 'bank_transfer');
    if (success && mounted) _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final canSubmit = widget.meetsThreshold &&
        amount >= widget.threshold &&
        amount <= widget.availableBalance &&
        !widget.requesting;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request payout',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              focusNode: _focus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                border: const OutlineInputBorder(),
                suffixText: 'USD',
              ),
              onChanged: (_) => setState(() {}),
              enabled: widget.meetsThreshold,
            ),
            const SizedBox(height: 8),
            Text(
              'Available: ${widget.formatCurrency(widget.availableBalance)} • Minimum: ${widget.formatCurrency(widget.threshold)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (widget.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  widget.error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                ),
              ),
            ],
            if (widget.successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  widget.successMessage!,
                  style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canSubmit ? _submit : null,
                child: widget.requesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Request payout'),
              ),
            ),
            if (!widget.meetsThreshold) ...[
              const SizedBox(height: 12),
              Text(
                'Reach ${widget.formatCurrency(widget.threshold)} available balance to request a payout.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
