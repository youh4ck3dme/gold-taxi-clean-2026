import 'package:equatable/equatable.dart';

/// User Model
class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? profilePictureUrl;
  final String role;
  final String? bio;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePictureUrl,
    required this.role,
    this.bio,
    this.isActive = true,
  });

  /// Convert from JSON (WordPress API response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePictureUrl: _getAvatarUrl(json['avatar_urls']),
      role: _getRole(json['roles']),
      bio: json['description'] as String?,
      isActive: true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar_urls': {'96': profilePictureUrl},
    'roles': [role],
    'description': bio,
  };

  /// Get avatar URL from nested JSON
  static String? _getAvatarUrl(dynamic avatarUrls) {
    if (avatarUrls is Map) {
      return avatarUrls['96'] as String?;
    }
    return null;
  }

  /// Get role from roles array
  static String _getRole(dynamic roles) {
    if (roles is List && roles.isNotEmpty) {
      return roles.first as String? ?? 'subscriber';
    }
    return 'subscriber';
  }

  @override
  List<Object?> get props => [id, name, email, profilePictureUrl, role, bio, isActive];

  bool get isCustomer => role == 'customer' || role == 'subscriber';
  bool get isDriver => role == 'driver';
  bool get isAdmin => role == 'admin' || role == 'administrator';
}
