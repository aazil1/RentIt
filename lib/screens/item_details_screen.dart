import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../models/item_model.dart';
import '../services/marketplace_scope.dart';
import '../widgets/host_card.dart';
import '../widgets/pricing_calculator.dart';
import 'chat_screen.dart';
import 'checkout_screen.dart';

class ItemDetailsScreen extends StatefulWidget {
  final RentalItem item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  PricingMode selectedMode = PricingMode.daily;
  DateTimeRange? selectedDateRange;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  DateTime? singleDayDate;

  int get calculatedUnits {
    if (selectedMode == PricingMode.daily) {
      if (selectedDateRange == null) return 0;
      return selectedDateRange!.duration.inDays + 1;
    } else {
      if (singleDayDate == null || startTime == null || endTime == null) return 0;
      final startMins = startTime!.hour * 60 + startTime!.minute;
      final endMins = endTime!.hour * 60 + endTime!.minute;
      final diff = endMins - startMins;
      if (diff <= 0) return 0;
      return (diff / 60).ceil();
    }
  }

  double get rentalSubtotal {
    final rate = selectedMode == PricingMode.daily ? widget.item.dailyRate : widget.item.hourlyRate;
    return calculatedUnits * rate;
  }

  double get grandTotal {
    if (calculatedUnits == 0) return 0;
    return rentalSubtotal + widget.item.securityDeposit;
  }

  String get bookingPeriod {
    if (selectedMode == PricingMode.daily && selectedDateRange != null) {
      return '${DateFormat('MMM d').format(selectedDateRange!.start)} – ${DateFormat('MMM d, yyyy').format(selectedDateRange!.end)}';
    }
    if (selectedMode == PricingMode.hourly && singleDayDate != null && startTime != null && endTime != null) {
      return '${DateFormat('MMM d, yyyy').format(singleDayDate!)} · ${startTime!.format(context)}–${endTime!.format(context)}';
    }
    return 'Dates not selected';
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    final store = MarketplaceScope.of(context);
    final isFavorite = store.favoriteIds.contains(widget.item.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Remove from saved items' : 'Save item',
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => store.toggleFavorite(widget.item.id),
          ),
          IconButton(
            tooltip: 'Copy listing details',
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text:
                      '${widget.item.title} · ${currency.format(widget.item.dailyRate)}/day on RentIt',
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listing details copied to clipboard.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Visual
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.item.imageUrl.isEmpty
                  ? const Icon(Icons.devices, size: 80, color: Colors.deepPurple)
                  : Image.network(
                      widget.item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.devices, size: 80, color: Colors.deepPurple),
                    ),
            ),
            const SizedBox(height: 16),

            // Item Title & Rate Overview
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(widget.item.category),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${currency.format(widget.item.dailyRate)}/day',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    Text(
                      '${currency.format(widget.item.hourlyRate)}/hr',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Owner Card
            HostCard(
              owner: widget.item.owner,
              onChatPressed: widget.item.owner.id == 'local-user'
                  ? null
                  : () async {
                      try {
                        final conversation = await store.startConversation(
                          item: widget.item,
                          myRole: MarketplaceRole.borrower,
                        );
                        if (!context.mounted) return;
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(conversationId: conversation.id),
                          ),
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not open conversation: $error')),
                        );
                      }
                    },
            ),
            const SizedBox(height: 16),

            // Description
            Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.item.description, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
            const Divider(height: 32),

            // Booking Options
            Text('Select Duration', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            SegmentedButton<PricingMode>(
              segments: const [
                ButtonSegment(value: PricingMode.daily, label: Text('Daily Rental'), icon: Icon(Icons.calendar_month)),
                ButtonSegment(value: PricingMode.hourly, label: Text('Hourly Rental'), icon: Icon(Icons.access_time)),
              ],
              selected: {selectedMode},
              onSelectionChanged: (selection) {
                setState(() {
                  selectedMode = selection.first;
                  selectedDateRange = null;
                  singleDayDate = null;
                  startTime = null;
                  endTime = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Pickers
            if (selectedMode == PricingMode.daily) ...[
              ListTile(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(Icons.date_range, color: Colors.deepPurple),
                title: Text(
                  selectedDateRange == null
                      ? 'Select Start and End Dates'
                      : '${DateFormat('MMM dd').format(selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(selectedDateRange!.end)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(selectedDateRange == null ? 'Tap to open calendar' : '$calculatedUnits day(s) selected'),
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => selectedDateRange = picked);
                },
              ),
            ] else ...[
              ListTile(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(Icons.today, color: Color(0xFF176B53)),
                title: Text(
                  singleDayDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(singleDayDate!),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => singleDayDate = picked);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      child: Text(startTime == null ? 'Start Time' : startTime!.format(context)),
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: startTime ?? TimeOfDay.now());
                        if (t != null) setState(() => startTime = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      child: Text(endTime == null ? 'End Time' : endTime!.format(context)),
                      onPressed: () async {
                        final t = await showTimePicker(context: context, initialTime: endTime ?? TimeOfDay.now());
                        if (t != null) setState(() => endTime = t);
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Calculator Card Widget
            if (calculatedUnits > 0)
              PricingCalculator(
                item: widget.item,
                mode: selectedMode,
                units: calculatedUnits,
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Grand Total', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  currency.format(grandTotal),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: calculatedUnits > 0
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                              item: widget.item,
                              calculatedTotal: grandTotal,
                              units: calculatedUnits,
                              bookingPeriod: bookingPeriod,
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}