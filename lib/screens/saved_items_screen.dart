import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/marketplace_scope.dart';
import 'item_details_screen.dart';

class SavedItemsScreen extends StatelessWidget {
  const SavedItemsScreen({super.key});

  static final _currency = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final store = MarketplaceScope.of(context);
    final items = store.listings
        .where((item) => store.favoriteIds.contains(item.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved items')),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 52, color: Colors.black38),
                    SizedBox(height: 12),
                    Text('Nothing saved yet',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 17)),
                    SizedBox(height: 5),
                    Text('Tap the heart on a listing to keep it here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(Icons.inventory_2_outlined,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${_currency.format(item.dailyRate)}/day · ${item.category}'),
                    trailing: IconButton(
                      tooltip: 'Remove from saved items',
                      onPressed: () => store.toggleFavorite(item.id),
                      icon: const Icon(Icons.favorite, color: Colors.redAccent),
                    ),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ItemDetailsScreen(item: item))),
                  ),
                );
              },
            ),
    );
  }
}
