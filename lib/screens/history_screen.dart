import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_model.dart';
import '../services/marketplace_scope.dart';
import 'chat_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _showBookings = true;
  static final _currency = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final store = MarketplaceScope.of(context);
    final myListings =
        store.listings.where((item) => item.owner.id == 'local-user').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Your activity')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: true,
                    label: Text('Rentals'),
                    icon: Icon(Icons.shopping_bag_outlined)),
                ButtonSegment(
                    value: false,
                    label: Text('My listings'),
                    icon: Icon(Icons.storefront_outlined)),
              ],
              selected: {_showBookings},
              onSelectionChanged: (selection) =>
                  setState(() => _showBookings = selection.first),
            ),
          ),
          Expanded(
            child: _showBookings
                ? store.bookings.isEmpty
                    ? const _ActivityEmpty(
                        icon: Icons.receipt_long_outlined,
                        title: 'No rentals yet',
                        message:
                            'Your completed demo checkouts will show up here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: store.bookings.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final booking = store.bookings[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    child: Icon(Icons.inventory_2_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(booking.itemTitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Text(booking.bookingPeriod,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54)),
                                        const SizedBox(height: 5),
                                        Text('${booking.paymentMethod} · DEMO',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_currency.format(booking.total),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                : myListings.isEmpty
                    ? const _ActivityEmpty(
                        icon: Icons.add_business_outlined,
                        title: 'No items listed',
                        message: 'Share something you own with your community.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: myListings.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = myListings[index];
                          Future<void> openBorrowerChat() async {
                            try {
                              final conversation =
                                  await store.startConversation(
                                item: item,
                                myRole: MarketplaceRole.renter,
                                participantId: '${item.id}-demo-borrower',
                                participantName: 'Interested borrower',
                              );
                              if (!context.mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                      conversationId: conversation.id),
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Could not open conversation: $error')),
                              );
                            }
                          }

                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Icon(Icons.inventory_2_outlined,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              title: Text(item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                  '${item.category} · ${_currency.format(item.dailyRate)}/day · Active'),
                              trailing: IconButton(
                                tooltip: 'Message borrower',
                                onPressed: openBorrowerChat,
                                icon: const Icon(Icons.chat_outlined),
                              ),
                              onTap: openBorrowerChat,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ActivityEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ActivityEmpty(
      {required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: Colors.black38),
              const SizedBox(height: 14),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
}
