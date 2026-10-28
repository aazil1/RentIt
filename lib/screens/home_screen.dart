import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/item_model.dart';
import '../services/marketplace_scope.dart';
import 'item_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _showFavoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = MarketplaceScope.of(context);
    final categories = ['All', ...store.listings.map((item) => item.category).toSet()];
    final query = _searchController.text.trim().toLowerCase();
    final items = store.listings.where((item) {
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      final matchesFavorites =
          !_showFavoritesOnly || store.favoriteIds.contains(item.id);
      return item.isAvailable &&
          matchesCategory &&
          matchesSearch &&
          matchesFavorites;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.shopping_bag_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RentIt',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text('Borrow more. Buy less.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.black54)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: _showFavoritesOnly
                          ? 'Show all items'
                          : 'Show saved items',
                      onPressed: () => setState(
                          () => _showFavoritesOnly = !_showFavoritesOnly),
                      icon: Icon(_showFavoritesOnly
                          ? Icons.favorite
                          : Icons.favorite_border),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF176B53), Color(0xFF2F9274)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('THE SMARTER WAY TO RENT',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.7)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Find your next\nfavorite thing.',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1),
                            ),
                            const SizedBox(height: 8),
                            const Text('Great finds, right around the corner.',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.local_mall_rounded,
                          size: 68, color: Color(0xBFFFFFFF)),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search cameras, tools, games...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                      showCheckmark: false,
                      selectedColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      side: BorderSide.none,
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _showFavoritesOnly
                            ? 'Your saved items'
                            : 'Popular near you',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text('${items.length} items',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54)),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyResults(
                  favoritesOnly: _showFavoritesOnly,
                  onClear: () => setState(() {
                    _showFavoritesOnly = false;
                    _selectedCategory = 'All';
                    _searchController.clear();
                  }),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                sliver: SliverGrid.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.66,
                  ),
                  itemBuilder: (context, index) => _ListingCard(
                    item: items[index],
                    isFavorite: store.favoriteIds.contains(items[index].id),
                    onFavorite: () => store.toggleFavorite(items[index].id),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ItemDetailsScreen(item: items[index])),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final RentalItem item;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  const _ListingCard({
    required this.item,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  static final _currency = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ListingArt(category: item.category, imageUrl: item.imageUrl),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.93),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(item.category,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: IconButton.filledTonal(
                      tooltip:
                          isFavorite ? 'Remove from saved items' : 'Save item',
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.93),
                          minimumSize: const Size(34, 34)),
                      onPressed: onFavorite,
                      icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color:
                              isFavorite ? Colors.redAccent : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700, height: 1.2)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: _currency.format(item.dailyRate),
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16),
                            children: const [
                              TextSpan(
                                  text: ' /day',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 11,
                                      color: Colors.black54))
                            ],
                          ),
                        ),
                      ),
                      const Icon(Icons.star_rounded,
                          size: 15, color: Color(0xFFF5AD34)),
                      const SizedBox(width: 2),
                      Text(item.owner.renterRating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text('by ${item.owner.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.black54, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingArt extends StatelessWidget {
  final String category;
  final String imageUrl;

  const _ListingArt({required this.category, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final (icon, color) = switch (category) {
      'Tech' => (Icons.camera_alt_rounded, const Color(0xFFDCECE5)),
      'Gaming' || 'Games' => (
          Icons.sports_esports_rounded,
          const Color(0xFFE8E1F5)
        ),
      'Tools' => (Icons.handyman_rounded, const Color(0xFFF4E8D4)),
      'Home' || 'Appliances' => (Icons.chair_rounded, const Color(0xFFE8EAF2)),
      'Books' => (Icons.auto_stories_rounded, const Color(0xFFF5E6E1)),
      _ => (Icons.inventory_2_rounded, const Color(0xFFE5ECE7)),
    };
    return Container(
      color: color,
      child: Center(
          child: Icon(icon,
              size: 56,
              color: const Color(0xFF176B53).withValues(alpha: 0.75))),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final bool favoritesOnly;
  final VoidCallback onClear;

  const _EmptyResults({required this.favoritesOnly, required this.onClear});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  favoritesOnly
                      ? Icons.favorite_border
                      : Icons.search_off_rounded,
                  size: 48,
                  color: Colors.black38),
              const SizedBox(height: 12),
              Text(favoritesOnly ? 'No saved items yet' : 'No items found',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                  favoritesOnly
                      ? 'Tap the heart on anything you like.'
                      : 'Try a different search or category.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 14),
              TextButton(
                  onPressed: onClear, child: const Text('Show all items')),
            ],
          ),
        ),
      );
}
