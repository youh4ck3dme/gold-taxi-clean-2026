import 'profile_repository.dart';
import '../../../../models/user_model.dart';

class MockProfileRepository implements ProfileRepository {
  UserModel _currentUser = const UserModel(
    id: 'dev_user_123',
    name: 'Developer',
    email: 'dev@localhost',
    role: 'customer',
    isActive: true,
    phone: '+421900111222',
    savedAddresses: {},
    referralCode: 'JOZO50',
  );

  // Mock driver record in drivers table
  final Map<String, dynamic> _driverRecord = {
    'id': 'driver_123',
    'vehicle_type': 'Škoda Superb',
    'vehicle_plate': 'KE-123AB',
    'service_classes': ['standard', 'comfort'],
    'is_online': false,
    'verification_status': 'pending_verification',
  };

  Map<String, dynamic>? _mockDocuments;

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
      referralCode: _currentUser.referralCode,
      referredBy: _currentUser.referredBy,
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
    // Return record only if user has driver role
    if (_currentUser.isDriver) {
      return _driverRecord;
    }
    return null;
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

  @override
  Future<void> registerAsDriver({
    required String vehicleType,
    required String vehiclePlate,
    required List<String> serviceClasses,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = UserModel(
      id: _currentUser.id,
      name: _currentUser.name,
      email: _currentUser.email,
      profilePictureUrl: _currentUser.profilePictureUrl,
      role: 'driver',
      bio: _currentUser.bio,
      isActive: _currentUser.isActive,
      phone: _currentUser.phone,
      savedAddresses: _currentUser.savedAddresses,
    );
    _driverRecord['vehicle_type'] = vehicleType;
    _driverRecord['vehicle_plate'] = vehiclePlate;
    _driverRecord['service_classes'] = serviceClasses;
    _driverRecord['is_online'] = false;
    _driverRecord['verification_status'] = 'pending_verification';
  }

  @override
  Future<String> uploadDocument({
    required String documentType,
    required List<int> bytes,
    required String fileName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final ext = fileName.split('.').last.toLowerCase();
    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      throw Exception('Nepodporovaný formát súboru. Nahrajte iba JPG, JPEG alebo PNG.');
    }
    if (bytes.length > 5 * 1024 * 1024) {
      throw Exception('Súbor je príliš veľký. Maximálna veľkosť je 5 MB.');
    }
    return 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=500&q=60';
  }

  @override
  Future<void> saveDriverDocuments({
    required String profilePhotoUrl,
    required String idCardUrl,
    required String licenseUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockDocuments = {
      'profile_photo_url': profilePhotoUrl,
      'id_card_url': idCardUrl,
      'license_url': licenseUrl,
    };
    _driverRecord['verification_status'] = 'pending_verification';
  }

  @override
  Future<Map<String, dynamic>?> getDriverDocuments(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockDocuments;
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<bool> verifyPhoneOtp(String phone, String code) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return code == '123456';
  }

  @override
  Future<void> applyReferralCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final cleanCode = code.trim().toUpperCase();

    if (cleanCode == (_currentUser.referralCode ?? '').toUpperCase()) {
      throw Exception('Nemôžete použiť vlastný referenčný kód.');
    }

    if (_currentUser.referredBy != null) {
      throw Exception('Už ste zadali referenčný kód.');
    }

    if (cleanCode == 'MICHAL80' || cleanCode == 'JOZO50' || cleanCode == 'TAXI5' || cleanCode.startsWith('GOLD')) {
      _currentUser = UserModel(
        id: _currentUser.id,
        name: _currentUser.name,
        email: _currentUser.email,
        profilePictureUrl: _currentUser.profilePictureUrl,
        role: _currentUser.role,
        bio: _currentUser.bio,
        isActive: _currentUser.isActive,
        phone: _currentUser.phone,
        savedAddresses: _currentUser.savedAddresses,
        referralCode: _currentUser.referralCode,
        referredBy: 'referrer_user_id_999',
      );
    } else {
      throw Exception('Neplatný referenčný kód.');
    }
  }
}
