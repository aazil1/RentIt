import 'package:flutter/widgets.dart';

import 'marketplace_store.dart';

class MarketplaceScope extends InheritedNotifier<MarketplaceStore> {
  const MarketplaceScope({
    super.key,
    required MarketplaceStore store,
    required super.child,
  }) : super(notifier: store);

  static MarketplaceStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MarketplaceScope>();
    assert(scope != null, 'MarketplaceScope is missing above this context.');
    return scope!.notifier!;
  }
}
