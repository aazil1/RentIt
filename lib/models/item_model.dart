import 'user_model.dart';

enum PricingMode { hourly, daily }

class RentalItem {
  final String id;
  final String title;
  final String category;
  final String description;
  final double hourlyRate;
  final double dailyRate;
  final double securityDeposit;
  final String imageUrl;
  final UserModel owner;
  final bool isAvailable;

  RentalItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.hourlyRate,
    required this.dailyRate,
    required this.securityDeposit,
    required this.imageUrl,
    required this.owner,
    this.isAvailable = true,
  });
}