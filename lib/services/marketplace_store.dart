import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/item_model.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class RentalBooking {
  final String id;
  final String itemId;
  final String itemTitle;
  final String category;
  final double total;
  final int units;
  final String bookingPeriod;
  final String paymentMethod;
  final DateTime bookedAt;

  const RentalBooking({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.category,
    required this.total,
    required this.units,
    required this.bookingPeriod,
    required this.paymentMethod,
    required this.bookedAt,
  });

  Map<String, Object> toMap() => {
        'id': id,
        'itemId': itemId,
        'itemTitle': itemTitle,
        'category': category,
        'total': total,
        'units': units,
        'bookingPeriod': bookingPeriod,
        'paymentMethod': paymentMethod,
        'bookedAt': bookedAt.toIso8601String(),
      };

  factory RentalBooking.fromMap(Map<String, dynamic> map) => RentalBooking(
        id: map['id'] as String,
        itemId: map['itemId'] as String,
        itemTitle: map['itemTitle'] as String,
        category: map['category'] as String,
        total: (map['total'] as num).toDouble(),
        units: map['units'] as int,
        bookingPeriod: map['bookingPeriod'] as String,
        paymentMethod: map['paymentMethod'] as String,
        bookedAt: DateTime.parse(map['bookedAt'] as String),
      );
}

class MarketplaceStore extends ChangeNotifier {
  static const _storageKey = 'rentit_marketplace_v1';

  List<RentalItem> _listings = _sampleListings;
  List<RentalBooking> _bookings = [];
  List<ChatConversation> _conversations = [];
  Set<String> _favoriteIds = {};
  String name = 'Alex Morgan';
  String email = 'alex@example.com';
  String phone = '';
  String address = '';

  List<RentalItem> get listings => List.unmodifiable(_listings);
  List<RentalBooking> get bookings => List.unmodifiable(_bookings);
  List<ChatConversation> get conversations => List.unmodifiable(_conversations);
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  UserModel get currentUser => UserModel(
        id: 'local-user',
        name: name,
        avatarUrl: '',
        renterRating: 5,
        borrowerRating: 5,
        totalRentalsOut: _listings.where((item) => item.owner.id == 'local-user').length,
        totalBorrowed: _bookings.length,
      );

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null) return;

    final data = jsonDecode(raw) as Map<String, dynamic>;
    _listings = (data['listings'] as List<dynamic>)
        .map((item) => _itemFromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
    var addedNewSamples = false;
    for (final sample in _sampleListings) {
      if (!_listings.any((item) => item.id == sample.id)) {
        _listings.add(sample);
        addedNewSamples = true;
      }
    }
    _bookings = (data['bookings'] as List<dynamic>)
        .map((booking) => RentalBooking.fromMap(Map<String, dynamic>.from(booking as Map)))
        .toList();
    _conversations = ((data['conversations'] as List<dynamic>?) ?? [])
        .map((conversation) => ChatConversation.fromMap(Map<String, dynamic>.from(conversation as Map)))
        .toList();
    _favoriteIds = Set<String>.from(data['favoriteIds'] as List<dynamic>);
    final profile = Map<String, dynamic>.from(data['profile'] as Map);
    name = profile['name'] as String;
    email = profile['email'] as String;
    phone = profile['phone'] as String;
    address = profile['address'] as String;
    if (addedNewSamples) await _save();
    notifyListeners();
  }

  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    final profile = {'name': name, 'email': email, 'phone': phone, 'address': address};
    final profileOwner = UserModel(
      id: 'local-user',
      name: name,
      avatarUrl: '',
      renterRating: 5,
      borrowerRating: 5,
      totalRentalsOut: _listings.where((item) => item.owner.id == 'local-user').length,
      totalBorrowed: _bookings.length,
    );
    final listings = _listings
        .map(
          (item) => item.owner.id == 'local-user'
              ? RentalItem(
                  id: item.id,
                  title: item.title,
                  category: item.category,
                  description: item.description,
                  hourlyRate: item.hourlyRate,
                  dailyRate: item.dailyRate,
                  securityDeposit: item.securityDeposit,
                  imageUrl: item.imageUrl,
                  owner: profileOwner,
                  isAvailable: item.isAvailable,
                )
              : item,
        )
        .toList();
    await _save(profile: profile, listings: listings);
    _listings = listings;
    this.name = name;
    this.email = email;
    this.phone = phone;
    this.address = address;
    notifyListeners();
  }

  Future<void> addListing(RentalItem item) async {
    final listings = [..._listings, item];
    await _save(listings: listings);
    _listings = listings;
    notifyListeners();
  }

  Future<void> toggleFavorite(String itemId) async {
    final favorites = Set<String>.from(_favoriteIds);
    if (!favorites.add(itemId)) favorites.remove(itemId);
    await _save(favoriteIds: favorites);
    _favoriteIds = favorites;
    notifyListeners();
  }

  Future<void> addBooking(RentalBooking booking) async {
    final bookings = [booking, ..._bookings];
    await _save(bookings: bookings);
    _bookings = bookings;
    notifyListeners();
  }

  Future<ChatConversation> startConversation({
    required RentalItem item,
    required MarketplaceRole myRole,
    String? participantName,
    String? participantId,
  }) async {
    final otherUserId = participantId ?? item.owner.id;
    final existing = _conversations.where(
      (conversation) =>
          conversation.listingId == item.id &&
          conversation.participantId == otherUserId &&
          conversation.myRole == myRole,
    );
    if (existing.isNotEmpty) return existing.first;

    final now = DateTime.now();
    final conversation = ChatConversation(
      id: '${item.id}-${myRole.name}-${now.microsecondsSinceEpoch}',
      listingId: item.id,
      listingTitle: item.title,
      participantId: otherUserId,
      participantName: participantName ?? item.owner.name,
      myRole: myRole,
      updatedAt: now,
      messages: const [],
    );
    final conversations = [conversation, ..._conversations];
    await _save(conversations: conversations);
    _conversations = conversations;
    notifyListeners();
    return conversation;
  }

  Future<void> sendMessage(String conversationId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final index = _conversations.indexWhere((conversation) => conversation.id == conversationId);
    if (index < 0) throw StateError('The conversation is no longer available.');
    final updatedConversation = _conversations[index].withMessage(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        senderId: 'local-user',
        text: trimmed,
        sentAt: DateTime.now(),
      ),
    );
    final conversations = [..._conversations];
    conversations[index] = updatedConversation;
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _save(conversations: conversations);
    _conversations = conversations;
    notifyListeners();
  }

  Future<void> _save({
    List<RentalItem>? listings,
    List<RentalBooking>? bookings,
    Set<String>? favoriteIds,
    Map<String, String>? profile,
    List<ChatConversation>? conversations,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode({
        'listings': (listings ?? _listings).map(_itemToMap).toList(),
        'bookings': (bookings ?? _bookings).map((booking) => booking.toMap()).toList(),
        'conversations': (conversations ?? _conversations).map((conversation) => conversation.toMap()).toList(),
        'favoriteIds': (favoriteIds ?? _favoriteIds).toList(),
        'profile': profile ?? {'name': name, 'email': email, 'phone': phone, 'address': address},
      }),
    );
    if (!saved) throw StateError('Could not save marketplace data on this device.');
  }

  static Map<String, Object> _itemToMap(RentalItem item) => {
        'id': item.id,
        'title': item.title,
        'category': item.category,
        'description': item.description,
        'hourlyRate': item.hourlyRate,
        'dailyRate': item.dailyRate,
        'securityDeposit': item.securityDeposit,
        'imageUrl': item.imageUrl,
        'isAvailable': item.isAvailable,
        'owner': {
          'id': item.owner.id,
          'name': item.owner.name,
          'avatarUrl': item.owner.avatarUrl,
          'renterRating': item.owner.renterRating,
          'borrowerRating': item.owner.borrowerRating,
          'totalRentalsOut': item.owner.totalRentalsOut,
          'totalBorrowed': item.owner.totalBorrowed,
        },
      };

  static RentalItem _itemFromMap(Map<String, dynamic> map) {
    final owner = Map<String, dynamic>.from(map['owner'] as Map);
    return RentalItem(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      hourlyRate: (map['hourlyRate'] as num).toDouble(),
      dailyRate: (map['dailyRate'] as num).toDouble(),
      securityDeposit: (map['securityDeposit'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      isAvailable: map['isAvailable'] as bool,
      owner: UserModel(
        id: owner['id'] as String,
        name: owner['name'] as String,
        avatarUrl: owner['avatarUrl'] as String,
        renterRating: (owner['renterRating'] as num).toDouble(),
        borrowerRating: (owner['borrowerRating'] as num).toDouble(),
        totalRentalsOut: owner['totalRentalsOut'] as int,
        totalBorrowed: owner['totalBorrowed'] as int,
      ),
    );
  }

  static final _sampleListings = <RentalItem>[
    RentalItem(
      id: 'sample-camera',
      title: 'Sony Alpha a7 III Camera Kit',
      category: 'Tech',
      description: 'Professional full-frame mirrorless camera with a 24–70mm lens and two extra batteries.',
      hourlyRate: 150,
      dailyRate: 800,
      securityDeposit: 1000,
      imageUrl: '',
      owner: _sampleOwner('owner-john', 'John Doe', 4.9),
    ),
    RentalItem(
      id: 'sample-console',
      title: 'PlayStation 5 + 2 Controllers',
      category: 'Gaming',
      description: 'PS5 console with an extra DualSense controller and a selection of popular games.',
      hourlyRate: 100,
      dailyRate: 600,
      securityDeposit: 800,
      imageUrl: '',
      owner: _sampleOwner('owner-maria', 'Maria Santos', 4.8),
    ),
    RentalItem(
      id: 'sample-drill',
      title: 'DeWalt Cordless Drill Kit',
      category: 'Tools',
      description: '20V brushless drill kit with two batteries, charger, and a sturdy carrying case.',
      hourlyRate: 50,
      dailyRate: 300,
      securityDeposit: 400,
      imageUrl: '',
      owner: _sampleOwner('owner-alex', 'Alex Reyes', 5),
    ),
    RentalItem(
      id: 'sample-speaker',
      title: 'JBL Portable Party Speaker',
      category: 'Tech',
      description: 'Powerful portable Bluetooth speaker with deep bass and a long-lasting battery.',
      hourlyRate: 80,
      dailyRate: 450,
      securityDeposit: 500,
      imageUrl: '',
      owner: _sampleOwner('owner-sam', 'Sam Rivera', 4.7),
    ),
    RentalItem(
      id: 'sample-bike',
      title: 'Giant Escape City Bike',
      category: 'Sports',
      description: 'Comfortable hybrid bike with a rear rack, helmet, lock, and front and rear lights.',
      hourlyRate: 70,
      dailyRate: 400,
      securityDeposit: 500,
      imageUrl: '',
      owner: _sampleOwner('owner-lena', 'Lena Cruz', 4.9),
    ),
    RentalItem(
      id: 'sample-projector',
      title: 'Epson Home Cinema Projector',
      category: 'Tech',
      description: 'Bright Full HD projector with HDMI cable, remote, and portable screen available.',
      hourlyRate: 120,
      dailyRate: 650,
      securityDeposit: 900,
      imageUrl: '',
      owner: _sampleOwner('owner-diego', 'Diego Flores', 4.8),
    ),
    RentalItem(
      id: 'sample-drone',
      title: 'DJI Mini 3 Drone',
      category: 'Tech',
      description: 'Lightweight camera drone with spare batteries, controller, and a carry case.',
      hourlyRate: 180,
      dailyRate: 950,
      securityDeposit: 1500,
      imageUrl: '',
      owner: _sampleOwner('owner-nina', 'Nina Reyes', 5),
    ),
    RentalItem(
      id: 'sample-tent',
      title: 'Coleman 4-Person Camping Tent',
      category: 'Sports',
      description: 'Weather-resistant family tent with rainfly, groundsheet, and storage bag.',
      hourlyRate: 60,
      dailyRate: 350,
      securityDeposit: 400,
      imageUrl: '',
      owner: _sampleOwner('owner-mark', 'Mark Villanueva', 4.6),
    ),
    RentalItem(
      id: 'sample-espresso',
      title: 'De’Longhi Espresso Machine',
      category: 'Home',
      description: 'Countertop espresso maker with milk frother, tamper, and starter coffee beans.',
      hourlyRate: 90,
      dailyRate: 500,
      securityDeposit: 700,
      imageUrl: '',
      owner: _sampleOwner('owner-claire', 'Claire Lim', 4.9),
    ),
    RentalItem(
      id: 'sample-guitar',
      title: 'Yamaha Acoustic Guitar',
      category: 'Music',
      description: 'Full-size acoustic guitar, gig bag, tuner, spare strings, and picks included.',
      hourlyRate: 50,
      dailyRate: 280,
      securityDeposit: 350,
      imageUrl: '',
      owner: _sampleOwner('owner-raf', 'Rafael Garcia', 4.7),
    ),
    RentalItem(
      id: 'sample-pressure-washer',
      title: 'Karcher Pressure Washer',
      category: 'Tools',
      description: 'Compact electric pressure washer with hose, spray lance, and patio attachment.',
      hourlyRate: 100,
      dailyRate: 550,
      securityDeposit: 800,
      imageUrl: '',
      owner: _sampleOwner('owner-joel', 'Joel Tan', 4.8),
    ),
    RentalItem(
      id: 'sample-chairs',
      title: 'Folding Event Table & Chairs',
      category: 'Home',
      description: 'One sturdy folding table and six clean folding chairs for events and gatherings.',
      hourlyRate: 80,
      dailyRate: 450,
      securityDeposit: 500,
      imageUrl: '',
      owner: _sampleOwner('owner-ana', 'Ana Bautista', 4.9),
    ),
    RentalItem(
      id: 'sample-baby-stroller',
      title: 'Compact Travel Stroller',
      category: 'Home',
      description: 'Lightweight foldable stroller with sun canopy, storage basket, and rain cover.',
      hourlyRate: 65,
      dailyRate: 380,
      securityDeposit: 600,
      imageUrl: '',
      owner: _sampleOwner('owner-ivy', 'Ivy Ramos', 5),
    ),
    RentalItem(
      id: 'sample-boardgames',
      title: 'Family Board Game Bundle',
      category: 'Games',
      description: 'A hand-picked bundle of five family board games for a fun night in.',
      hourlyRate: 30,
      dailyRate: 160,
      securityDeposit: 200,
      imageUrl: '',
      owner: _sampleOwner('owner-ben', 'Ben Santos', 4.7),
    ),
    RentalItem(
      id: 'sample-books',
      title: 'Popular Business Books Bundle',
      category: 'Books',
      description: 'A set of four well-kept business and personal-growth books for a weekend read.',
      hourlyRate: 20,
      dailyRate: 100,
      securityDeposit: 150,
      imageUrl: '',
      owner: _sampleOwner('owner-mia', 'Mia Dela Cruz', 4.8),
    ),
  ];

  static UserModel _sampleOwner(String id, String name, double rating) => UserModel(
        id: id,
        name: name,
        avatarUrl: '',
        renterRating: rating,
        borrowerRating: rating,
        totalRentalsOut: 12,
        totalBorrowed: 8,
      );
}
