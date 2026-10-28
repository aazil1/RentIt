import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/chat_model.dart';
import 'package:myapp/services/marketplace_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('profile, favorites, listings, and bookings persist between store loads',
      () async {
    final firstStore = MarketplaceStore();
    await firstStore.load();
    expect(firstStore.listings.length, greaterThanOrEqualTo(15));
    await firstStore.toggleFavorite('sample-camera');
    await firstStore.saveProfile(
      name: 'Taylor Example',
      email: 'taylor@example.com',
      phone: '09123456789',
      address: 'Cebu City',
    );
    await firstStore.addBooking(
      RentalBooking(
        id: 'RNT-test',
        itemId: 'sample-camera',
        itemTitle: 'Sony Alpha a7 III Camera Kit',
        category: 'Tech',
        total: 1800,
        units: 1,
        bookingPeriod: 'Oct 20, 2026',
        paymentMethod: 'GCash',
        bookedAt: DateTime(2026, 10, 14),
      ),
    );
    final conversation = await firstStore.startConversation(
      item: firstStore.listings.first,
      myRole: MarketplaceRole.borrower,
    );
    await firstStore.sendMessage(conversation.id, 'Is this available this weekend?');

    final secondStore = MarketplaceStore();
    await secondStore.load();

    expect(secondStore.name, 'Taylor Example');
    expect(secondStore.phone, '09123456789');
    expect(secondStore.favoriteIds, contains('sample-camera'));
    expect(secondStore.bookings.single.paymentMethod, 'GCash');
    expect(secondStore.bookings.single.bookingPeriod, 'Oct 20, 2026');
    expect(secondStore.conversations.single.myRole, MarketplaceRole.borrower);
    expect(secondStore.conversations.single.messages.single.text, 'Is this available this weekend?');
  });
}
