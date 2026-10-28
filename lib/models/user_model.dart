class UserModel {
  final String id;
  final String name;
  final String avatarUrl;
  final double renterRating; // Rating as someone renting out items (Host)
  final double borrowerRating; // Rating as someone borrowing items
  final int totalRentalsOut;
  final int totalBorrowed;

  UserModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.renterRating,
    required this.borrowerRating,
    required this.totalRentalsOut,
    required this.totalBorrowed,
  });
}