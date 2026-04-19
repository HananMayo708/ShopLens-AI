class User {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatar;
  final bool isVerified;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;
  final List<String> preferredCategories;
  final double? priceAlertThreshold;

  // Computed properties
  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (username.isNotEmpty) {
      return username[0].toUpperCase();
    }
    return 'U';
  }

  String get fullName {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (username.isNotEmpty) {
      return username;
    }
    return 'User';
  }

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.avatar,
    this.isVerified = false,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.dateOfBirth,
    required this.createdAt,
    this.address,
    this.city,
    this.country,
    this.postalCode,
    this.preferredCategories = const [],
    this.priceAlertThreshold,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
      isVerified: json['is_verified'] ?? false,
      isEmailVerified: json['is_email_verified'] ?? false,
      isPhoneVerified: json['is_phone_verified'] ?? false,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      postalCode: json['postal_code']?.toString(),
      preferredCategories: json['preferred_categories'] != null
          ? List<String>.from(json['preferred_categories'])
          : [],
      priceAlertThreshold: json['price_alert_threshold'] != null
          ? double.tryParse(json['price_alert_threshold'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'avatar': avatar,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'city': city,
      'country': country,
      'postal_code': postalCode,
      'preferred_categories': preferredCategories,
      'price_alert_threshold': priceAlertThreshold,
    };
  }
}
