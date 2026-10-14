import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/item_model.dart';
import '../services/marketplace_scope.dart';
import '../services/marketplace_store.dart';

class CheckoutScreen extends StatefulWidget {
  final RentalItem item;
  final double calculatedTotal;
  final int units;
  final String bookingPeriod;

  const CheckoutScreen({
    super.key,
    required this.item,
    required this.calculatedTotal,
    required this.units,
    required this.bookingPeriod,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedMethod = 'GCash';
  bool _isProcessing = false;

  static const _methods = [
    ('GCash', 'E-wallet', Icons.account_balance_wallet_rounded),
    ('Maya', 'E-wallet', Icons.wallet_rounded),
    ('Credit / Debit Card', 'Visa · Mastercard', Icons.credit_card_rounded),
    ('Cash on pickup', 'Pay when you collect', Icons.payments_outlined),
  ];
  static final _currency = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

  Future<void> _pay() async {
    if (widget.calculatedTotal <= 0 || widget.units <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a valid rental period before checkout.')));
      return;
    }
    setState(() => _isProcessing = true);
    final store = MarketplaceScope.of(context);
    final reference = 'RNT-${DateTime.now().millisecondsSinceEpoch}';
    try {
      await store.addBooking(
        RentalBooking(
          id: reference,
          itemId: widget.item.id,
          itemTitle: widget.item.title,
          category: widget.item.category,
          total: widget.calculatedTotal,
          units: widget.units,
          bookingPeriod: widget.bookingPeriod,
          paymentMethod: _selectedMethod,
          bookedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _PaymentSuccessScreen(
            reference: reference,
            itemTitle: widget.item.title,
            total: widget.calculatedTotal,
            paymentMethod: _selectedMethod,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not complete demo checkout: $error')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF176B53)),
              const SizedBox(width: 8),
              Text('Secure checkout', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RENTAL SUMMARY', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800, color: Colors.black54)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(widget.bookingPeriod, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _SummaryLine(label: 'Rental duration', value: '${widget.units} unit${widget.units == 1 ? '' : 's'}'),
                  const SizedBox(height: 8),
                  _SummaryLine(label: 'Refundable deposit included', value: _currency.format(widget.item.securityDeposit)),
                  const SizedBox(height: 12),
                  _SummaryLine(
                    label: 'Total due',
                    value: _currency.format(widget.calculatedTotal),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text('Choose how to pay', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ..._methods.map((method) {
            final selected = _selectedMethod == method.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isProcessing ? null : () => setState(() => _selectedMethod = method.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? theme.colorScheme.primary : const Color(0xFFE5E9E6)),
                    ),
                    child: Row(
                      children: [
                        Icon(method.$3, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(method.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(method.$2, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                            ],
                          ),
                        ),
                        Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: selected ? theme.colorScheme.primary : Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: const Color(0xFFFFF4DC), borderRadius: BorderRadius.circular(14)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF8B6419)),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Demo checkout only. No real payment is processed and no card or wallet credentials are collected.',
                    style: TextStyle(color: Color(0xFF75591E), fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isProcessing ? null : _pay,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            child: _isProcessing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Complete demo checkout · ${_currency.format(widget.calculatedTotal)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          const Text('Your order will appear in Activity after checkout.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryLine({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: bold ? Colors.black87 : Colors.black54, fontWeight: bold ? FontWeight.w700 : FontWeight.normal))),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 17 : 14),
            ),
          ),
        ],
      );
}

class _PaymentSuccessScreen extends StatelessWidget {
  final String reference;
  final String itemTitle;
  final double total;
  final String paymentMethod;

  const _PaymentSuccessScreen({
    required this.reference,
    required this.itemTitle,
    required this.total,
    required this.paymentMethod,
  });

  static final _currency = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(color: Color(0xFFDDF2E7), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 54, color: Color(0xFF176B53)),
                ),
                const SizedBox(height: 22),
                Text('You’re all set!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Your demo rental order has been saved.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _SummaryLine(label: 'Item', value: itemTitle),
                        const SizedBox(height: 12),
                        _SummaryLine(label: 'Demo payment method', value: paymentMethod),
                        const SizedBox(height: 12),
                        _SummaryLine(label: 'Demo order total', value: _currency.format(total), bold: true),
                        const SizedBox(height: 12),
                        _SummaryLine(label: 'Reference', value: reference),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('No real money was charged.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text('Back to exploring'),
                ),
              ],
            ),
          ),
        ),
      );
}
