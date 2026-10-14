import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/services/marketplace_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('RentApp smoke test', (WidgetTester tester) async {
    final store = MarketplaceStore();
    await store.load();
    await tester.pumpWidget(RentApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Popular near you'), findsOneWidget);
    expect(find.text('Sony Alpha a7 III Camera Kit'), findsOneWidget);
  });

  testWidgets('navigation destinations open their matching pages',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = MarketplaceStore();
    await store.load();
    await tester.pumpWidget(RentApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Messages'), findsOneWidget);

    await tester.tap(find.text('List item'));
    await tester.pumpAndSettle();
    expect(find.text('List an item'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Your activity'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
