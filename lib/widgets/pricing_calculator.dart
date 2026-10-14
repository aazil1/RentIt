import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item_model.dart';

class PricingCalculator extends StatelessWidget {
  final RentalItem item;
  final PricingMode mode;
  final int units;

  const PricingCalculator({
    super.key,
    required this.item,
    required this.mode,
    required this.units,
  });

  double get subtotal => mode == PricingMode.daily ? item.dailyRate * units : item.hourlyRate * units;
  double get total => subtotal + item.securityDeposit;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mode == PricingMode.daily
                    ? '${currency.format(item.dailyRate)} × $units day(s)'
                    : '${currency.format(item.hourlyRate)} × $units hr(s)',
                style: TextStyle(color: Colors.grey.shade800),
              ),
              Text(currency.format(subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Refundable Deposit', style: TextStyle(color: Colors.grey.shade800)),
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                ],
              ),
              Text(currency.format(item.securityDeposit), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                currency.format(total),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }
}