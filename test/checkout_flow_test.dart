import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screens/checkout_screen.dart';
import 'package:myapp/services/marketplace_scope.dart';
import 'package:myapp/services/marketplace_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('selected demo payment creates a rental order', (tester) async {
    final store = MarketplaceStore();
    await store.load();
    final item = store.listings.first;

    await tester.pumpWidget(
      MarketplaceScope(
        store: store,
        child: MaterialApp(
          home: CheckoutScreen(
            item: item,
            calculatedTotal: 1800,
            units: 1,
            bookingPeriod: 'Oct 20, 2026',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Maya'));
    await tester.pumpAndSettle();
    final checkoutButton = find.textContaining('Complete demo checkout');
    await tester.scrollUntilVisible(checkoutButton, 200);
    await tester.ensureVisible(checkoutButton);
    await tester.pumpAndSettle();
    await tester.tap(checkoutButton);
    await tester.pumpAndSettle();

    expect(find.text('You’re all set!'), findsOneWidget);
    expect(store.bookings, hasLength(1));
    expect(store.bookings.single.paymentMethod, 'Maya');
    expect(store.bookings.single.itemId, item.id);
  });
}
