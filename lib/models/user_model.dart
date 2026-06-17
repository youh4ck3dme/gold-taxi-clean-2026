import 'package:equatable/equatable.dart';

/// User Model
class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? profilePictureUrl;
  final String role;
  final String? bio;
  final bool isActive;
  final String? phone;
  final Map<String, dynamic> savedAddresses;
  final String? referralCode;
  final String? referredBy;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePictureUrl,
    required this.role,
    this.bio,
    this.isActive = true,
    this.phone,
    this.savedAddresses = const {},
    this.referralCode,
    this.referredBy,
  });

  /// Convert from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['full_name']) as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePictureUrl: _sanitizeUrl(json['profile_picture_url'] ?? _getAvatarUrl(json['avatar_urls'])),
      role: json['role'] as String? ?? _getRole(json['roles']),
      bio: json['bio'] ?? json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      phone: json['phone'] as String?,
      savedAddresses: json['saved_addresses'] as Map<String, dynamic>? ?? const {},
      referralCode: json['referral_code'] as String?,
      referredBy: json['referred_by'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'full_name': name,
    'email': email,
    'avatar_urls': {'96': profilePictureUrl},
    'profile_picture_url': profilePictureUrl,
    'role': role,
    'roles': [role],
    'description': bio,
    'bio': bio,
    'is_active': isActive,
    'phone': phone,
    'saved_addresses': savedAddresses,
    'referral_code': referralCode,
    'referred_by': referredBy,
  };

  /// Sanitize profile picture URL to handle empty or invalid values
  static String? _sanitizeUrl(dynamic url) {
    if (url == null) return null;
    final urlStr = url.toString().trim();
    if (urlStr.isEmpty || urlStr.toLowerCase() == 'null') {
      return null;
    }
    return urlStr;
  }

  /// Get avatar URL from nested JSON
  static String? _getAvatarUrl(dynamic avatarUrls) {
    if (avatarUrls is Map) {
      return _sanitizeUrl(avatarUrls['96']);
    }
    return null;
  }

  /// Get role from roles array
  static String _getRole(dynamic roles) {
    if (roles is List && roles.isNotEmpty) {
      return roles.first as String? ?? 'customer';
    }
    return 'customer';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        profilePictureUrl,
        role,
        bio,
        isActive,
        phone,
        savedAddresses,
        referralCode,
        referredBy,
      ];


  bool get isCustomer => role == 'customer' || role == 'subscriber';
  bool get isDriver => role == 'driver';
  bool get isAdmin => role == 'admin' || role == 'administrator';
}

