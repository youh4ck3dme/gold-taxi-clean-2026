import 'profile_repository.dart';
import '../../../../models/user_model.dart';

class MockProfileRepository implements ProfileRepository {
  UserModel _currentUser = const UserModel(
    id: 'dev_user_123',
    name: 'Developer',
    email: 'dev@localhost',
    role: 'administrator',
    isActive: true,
    phone: '+421900111222',
    savedAddresses: {},
  );

  // Mock driver record in drivers table
  final Map<String, dynamic> _driverRecord = {
    'vehicle_type': 'Škoda Superb',
    'vehicle_plate': 'KE-123AB',
    'service_classes': ['standard', 'comfort'],
    'is_online': false,
  };

  @override
  Future<UserModel> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  @override
  Future<UserModel> updateCustomerProfile({
    required String fullName,
    required String phone,
    required Map<String, dynamic> savedAddresses,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = UserModel(
      id: _currentUser.id,
      name: fullName,
      email: _currentUser.email,
      profilePictureUrl: _currentUser.profilePictureUrl,
      role: _currentUser.role,
      bio: _currentUser.bio,
      isActive: _currentUser.isActive,
      phone: phone,
      savedAddresses: savedAddresses,
    );
    return _currentUser;
  }

  @override
  Future<void> updateDriverProfile({
    required String vehicleType,
    required String vehiclePlate,
    required List<String> serviceClasses,
    required bool isOnline,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _driverRecord['vehicle_type'] = vehicleType;
    _driverRecord['vehicle_plate'] = vehiclePlate;
    _driverRecord['service_classes'] = serviceClasses;
    _driverRecord['is_online'] = isOnline;
  }

  @override
  Future<Map<String, dynamic>?> getDriverRecord(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _driverRecord;
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {
        'id': '1001',
        'total': '12.50',
        'date_created': '2026-06-12T14:30:00Z',
        'status': 'completed',
      },
      {
        'id': '1002',
        'total': '8.20',
        'date_created': '2026-06-13T09:15:00Z',
        'status': 'completed',
      }
    ];
  }

  @override
  Future<List<dynamic>> getBookingHistory(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  @override
  Future<Map<String, dynamic>> getDriverStats(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'ridesCount': 42,
      'totalEarnings': 256.40,
      'averageRating': 4.9,
    };
  }
}
