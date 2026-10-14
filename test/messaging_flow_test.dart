import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/chat_model.dart';
import 'package:myapp/screens/inbox_screen.dart';
import 'package:myapp/services/marketplace_scope.dart';
import 'package:myapp/services/marketplace_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('borrower can message a renter from the inbox', (tester) async {
    final store = MarketplaceStore();
    await store.load();
    final item = store.listings.first;
    final conversation = await store.startConversation(
      item: item,
      myRole: MarketplaceRole.borrower,
    );

    await tester.pumpWidget(
      MarketplaceScope(
        store: store,
        child: const MaterialApp(home: InboxScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(item.owner.name));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField), 'Is it available this weekend?');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    expect(store.conversations.single.id, conversation.id);
    expect(store.conversations.single.messages.single.text,
        'Is it available this weekend?');
    expect(find.text('Is it available this weekend?'), findsOneWidget);
    expect(find.text('You · Borrower'), findsOneWidget);
  });
}
