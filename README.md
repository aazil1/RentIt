# RentIt

RentIt is a Flutter peer-to-peer rental marketplace demo. Browse and search listings, save favorites, list items, choose a rental period, and review rental activity.

## Run the app

1. Install Flutter and the platform-specific development tools.
2. Run `flutter pub get`.
3. Run `flutter run` on a supported device or simulator.

Firebase Core is initialized using `lib/firebase_options.dart`. Marketplace data currently uses local device storage through `shared_preferences`; listings and profile changes are not shared between devices.

## Current demo behavior

- Sample items are included the first time the app is opened.
- New listings, profile details, saved items, rental orders, and renter/borrower demo messages persist on the current device.
- Checkout lets you select GCash, Maya, card, or cash on pickup and creates a demo order. **No payment is actually processed and no payment credentials are collected.**

Messages are local demo conversations and are not delivered to other devices. Real marketplace accounts, live messaging, shared listings, image uploads, and payment processing require authentication, production Firestore rules/backend services, and a payment provider integration. Never put payment-provider secret keys in the mobile app.
