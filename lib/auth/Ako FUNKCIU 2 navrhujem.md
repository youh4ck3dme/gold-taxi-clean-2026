Ako FUNKCIU 2 navrhujem:
FUNKCIA 2 – Sledovanie polohy vodičov a zobrazenie na mape
(Driver Location Tracking & Real-Time Map Display)
Ciele:

Vodiči môžu zapnúť/vypnúť online stav (is_online v driver_locations).
Vodiči automaticky aktualizujú svoju polohu (cez geolocator).
Zákazníci vidia reálny zoznam a polohu dostupných vodičov na mape (google_maps_flutter).
Systém filtruje len online vodičov a zobrazuje ich na mape.

Štruktúra súborov (analogicky k FUNKCIE 1):
text
Copy

lib/
├── location/
│   ├── driver_location_repository.dart  // Supabase operácie pre `driver_locations`
│   ├── driver_location_provider.dart     // State management (online stav, poloha)
│   └── map_screen.dart                    // Zobrazenie mapy s vodičmi (pre zákazníkov i vodičov)




Chceš, aby som vygeneroval kód pre túto funkciu?
Ak áno, potvrď, a hneď ti vyrobím:

Repository (update polohy, online/offline stav, načítanie blízky vodičov).
Provider (správa stavu polohy a online statusu).
UI (mapa s markerami vodičov, tlačidlo pre zap/vyp online).





// ============================================
// FILE: lib/auth/auth_repository.dart
// ============================================
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model pre používateľský profil z tabuľky `profiles`
class UserProfile {
  final String id;
  final String email;
  final String role;
  final String fullName;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      fullName: map['full_name'] ?? '',
    );
  }
}

/// Repository pre autentifikáciu a správu používateľov
class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Prihlásenie používateľa cez email a heslo
  Future<UserProfile?> login(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Prihlásenie zlyhalo: Nesprávny email alebo heslo');
      }

      // Načítanie roly z tabuľky `profiles`
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('email', email)
          .single();

      return UserProfile.fromMap(profileData);
    } catch (e) {
      throw Exception('Chyba pri prihlásení: ${e.toString()}');
    }
  }

  /// Registrácia nového používateľa
  Future<UserProfile?> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      // Vytvorenie používateľa v Supabase Auth
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Registrácia zlyhala');
      }

      // Vloženie profilu do tabuľky `profiles`
      final profileData = {
        'id': authResponse.user!.id,
        'email': email,
        'role': role,
        'full_name': fullName,
      };

      await _supabase.from('profiles').insert(profileData);

      // Načítanie a vrátenie profilu
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('email', email)
          .single();

      return UserProfile.fromMap(profile);
    } catch (e) {
      throw Exception('Chyba pri registrácii: ${e.toString()}');
    }
  }

  /// Odhlásenie používateľa
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  /// Získanie aktuálne prihláseného používateľa
  Future<UserProfile?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('email', user.email!)
          .single();

      return UserProfile.fromMap(profile);
    } catch (e) {
      return null;
    }
  }
}


// ============================================
// FILE: lib/auth/auth_provider.dart
// ============================================
import 'package:flutter/material.dart';
import 'auth_repository.dart';

/// Stavy autentifikácie
enum AuthStatus {
  unauthenticated,
  authenticated,
  loading,
  error,
}

/// Provider pre správu stavu autentifikácie
class AuthProvider with ChangeNotifier {
  AuthRepository _authRepository = AuthRepository();

  AuthStatus _status = AuthStatus.unauthenticated;
  UserProfile? _userProfile;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initialize();
  }

  /// Inicializácia: Skontroluje, či je používateľ už prihlásený
  Future<void> _initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      _userProfile = await _authRepository.getCurrentUser();
      _status = _userProfile != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Chyba pri inicializácii: ${e.toString()}';
    }

    notifyListeners();
  }

  /// Prihlásenie používateľa
  Future<void> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _authRepository.login(email, password);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Registrácia používateľa
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Odhlásenie používateľa
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authRepository.logout();
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }
}


// ============================================
// FILE: lib/auth/login_screen.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Prihlásenie')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Heslo'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (authProvider.status == AuthStatus.loading)
              const CircularProgressIndicator(),
            if (authProvider.status == AuthStatus.error)
              Text(
                authProvider.errorMessage ?? 'Chyba',
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await authProvider.login(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                );
              },
              child: const Text('Prihlásiť sa'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text('Nemáte účet? Registrujte sa'),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================
// FILE: lib/auth/register_screen.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController fullNameController = TextEditingController();
    final TextEditingController roleController = TextEditingController(text: 'customer');
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrácia')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Heslo'),
              obscureText: true,
            ),
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(labelText: 'Celé meno'),
            ),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(
                labelText: 'Rola (customer/driver)',
                hintText: 'customer',
              ),
            ),
            const SizedBox(height: 24),
            if (authProvider.status == AuthStatus.loading)
              const CircularProgressIndicator(),
            if (authProvider.status == AuthStatus.error)
              Text(
                authProvider.errorMessage ?? 'Chyba',
                style: const TextStyle(color: Colors.red),
              ),
            ElevatedButton(
              onPressed: () async {
                await authProvider.register(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  fullName: fullNameController.text.trim(),
                  role: roleController.text.trim(),
                );
                if (authProvider.status == AuthStatus.authenticated) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Registrovať sa'),
            ),
          ].map((widget) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: widget,
              )).toList(),
        ),
      ),
    );
  }
}


// ============================================
// FILE: lib/screens/customer_home_screen.dart
// ============================================
import 'package:flutter/material.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Domov - Zákazník')),
      body: const Center(child: Text('Vitajte, zákazník!')),
    );
  }
}


// ============================================
// FILE: lib/screens/driver_home_screen.dart
// ============================================
import 'package:flutter/material.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Domov - Vodič')),
      body: const Center(child: Text('Vitajte, vodič!')),
    );
  }
}


// ============================================
// FILE: lib/main.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/auth_provider.dart';
import 'screens/customer_home_screen.dart';
import 'screens/driver_home_screen.dart';
import 'auth/login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.status == AuthStatus.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (authProvider.status == AuthStatus.authenticated) {
            final role = authProvider.userProfile?.role;
            if (role == 'customer') {
              return const CustomerHomeScreen();
            } else if (role == 'driver') {
              return const DriverHomeScreen();
            }
          }

          return const LoginScreen();
        },
      ),
    );
  }
}


// ============================================
// FILE: test/auth/auth_repository_test.dart
// ============================================
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../lib/auth/auth_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockAuth extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}

void main() {
  late AuthRepository authRepository;
  late MockSupabaseClient mockSupabaseClient;
  late MockAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockAuth();
    mockUser = MockUser();
    Supabase.instance = SupabaseClient('http://test.com', 'test-key');
    when(Supabase.instance.client).thenReturn(mockSupabaseClient);
    when(mockSupabaseClient.auth).thenReturn(mockAuth);
    authRepository = AuthRepository();
  });

  group('AuthRepository Tests', () {
    test('login: Úspešné prihlásenie', () async {
      const email = 'test@example.com';
      const password = 'password123';
      final mockAuthResponse = AuthResponse(user: mockUser);
      final mockProfileData = {
        'id': 'user-id',
        'email': email,
        'role': 'customer',
        'full_name': 'Test User',
      };

      when(mockAuth.signInWithPassword(email: email, password: password))
          .thenAnswer((_) async => mockAuthResponse);
      when(mockSupabaseClient.from('profiles').select())
          .thenReturn(MockPostgrestFilterBuilder());
      when(mockSupabaseClient.from('profiles').select().eq('email', email))
          .thenReturn(MockPostgrestFilterBuilder());
      when(mockSupabaseClient.from('profiles').select().eq('email', email).single())
          .thenAnswer((_) async => mockProfileData);

      final result = await authRepository.login(email, password);
      expect(result, isA<UserProfile>());
      expect(result?.email, email);
      expect(result?.role, 'customer');
    });

    test('login: Nesprávny email alebo heslo', () async {
      const email = 'wrong@example.com';
      const password = 'wrongpassword';
      when(mockAuth.signInWithPassword(email: email, password: password))
          .thenThrow(Exception('Invalid credentials'));
      expect(() => authRepository.login(email, password), throwsException);
    });

    test('login: Chýbajúci profil', () async {
      const email = 'no-profile@example.com';
      const password = 'password123';
      final mockAuthResponse = AuthResponse(user: mockUser);
      when(mockAuth.signInWithPassword(email: email, password: password))
          .thenAnswer((_) async => mockAuthResponse);
      when(mockSupabaseClient.from('profiles').select())
          .thenReturn(MockPostgrestFilterBuilder());
      when(mockSupabaseClient.from('profiles').select().eq('email', email))
          .thenReturn(MockPostgrestFilterBuilder());
      when(mockSupabaseClient.from('profiles').select().eq('email', email).single())
          .thenThrow(PostgrestException(message: 'No profile found'));
      expect(() => authRepository.login(email, password), throwsException);
    });

    test('register: Úspešná registrácia', () async {
      const email = 'new@example.com';
      const password = 'password123';
      const fullName = 'New User';
      const role = 'driver';
      final mockAuthResponse = AuthResponse(user: mockUser);
      final mockProfileData = {
        'id': 'new-user-id',
        'email': email,
        'role': role,
        'full_name': fullName,
      };
      when(mockUser.id).thenReturn('new-user-id');
      when(mockAuth.signUp(email: email, password: password))
          .thenAnswer((_) async => mockAuthResponse);
      when(mockSupabaseClient.from('profiles').insert(any))
          .thenAnswer((_) async => []);
      when(mockSupabaseClient.from('profiles').select())
          .thenReturn(MockPostgrestFilterBuilder());
      when(mockSupabaseClient.from('profiles').select().eq('email', email))
          .thenReturn(MockPostgrestFilterBuilder());
      when(mockSupabaseClient.from('profiles').select().eq('email', email).single())
          .thenAnswer((_) async => mockProfileData);

      final result = await authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      expect(result, isA<UserProfile>());
      expect(result?.role, role);
    });

    test('register: Chyba pri registrácii', () async {
      const email = 'error@example.com';
      const password = 'password123';
      when(mockAuth.signUp(email: email, password: password))
          .thenThrow(Exception('Registration failed'));
      expect(
        () => authRepository.register(email: email, password: password, fullName: 'Test', role: 'customer'),
        throwsException,
      );
    });

    test('logout: Úspešné odhlásenie', () async {
      when(mockAuth.signOut()).thenAnswer((_) async => {});
      await expectLater(() => authRepository.logout(), completes);
      verify(mockAuth.signOut()).called(1);
    });

    test('getCurrentUser: Pouvžívateľ je prihlásený', () async {
      const email = 'current@example.com';
      final mockProfileData = {
        'id': 'current-user-id',
        'email': email,
        'role': 'customer',
        'full_name': 'Current User',
      };
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.email).thenReturn(email);
      when(mockSupabaseClient.from('profiles').select())
          .thenReturn(MockPostgrestFilterBuilder());
      when(mockSupabaseClient.from('profiles').select().eq('email', email))
          .thenReturn(MockPostgrestFilterBuilder());
      when(mockSupabaseClient.from('profiles').select().eq('email', email).single())
          .thenAnswer((_) async => mockProfileData);

      final result = await authRepository.getCurrentUser();
      expect(result, isA<UserProfile>());
      expect(result?.email, email);
    });

    test('getCurrentUser: Žiadny používateľ', () async {
      when(mockAuth.currentUser).thenReturn(null);
      final result = await authRepository.getCurrentUser();
      expect(result, isNull);
    });
  });
}


// ============================================
// FILE: test/auth/auth_provider_test.dart
// ============================================
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../../lib/auth/auth_provider.dart';
import '../../lib/auth/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthProvider authProvider;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authProvider = AuthProvider();
    authProvider._authRepository = mockAuthRepository;
  });

  group('AuthProvider Tests', () {
    test('initialize: Úspešné načítanie používateľa', () async {
      final mockProfile = UserProfile(
        id: 'user-id',
        email: 'test@example.com',
        role: 'customer',
        fullName: 'Test User',
      );
      when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => mockProfile);
      await authProvider._initialize();
      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.userProfile, mockProfile);
    });

    test('initialize: Žiadny používateľ', () async {
      when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => null);
      await authProvider._initialize();
      expect(authProvider.status, AuthStatus.unauthenticated);
    });

    test('login: Úspešné prihlásenie', () async {
      final mockProfile = UserProfile(
        id: 'user-id',
        email: 'test@example.com',
        role: 'driver',
        fullName: 'Test Driver',
      );
      when(mockAuthRepository.login('test@example.com', 'password123'))
          .thenAnswer((_) async => mockProfile);
      await authProvider.login('test@example.com', 'password123');
      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.userProfile, mockProfile);
    });

    test('login: Chyba', () async {
      when(mockAuthRepository.login('wrong@example.com', 'wrong'))
          .thenThrow(Exception('Login failed'));
      await authProvider.login('wrong@example.com', 'wrong');
      expect(authProvider.status, AuthStatus.error);
      expect(authProvider.errorMessage, contains('Login failed'));
    });

    test('register: Úspešná registrácia', () async {
      final mockProfile = UserProfile(
        id: 'new-user-id',
        email: 'new@example.com',
        role: 'customer',
        fullName: 'New User',
      );
      when(mockAuthRepository.register(
        email: 'new@example.com',
        password: 'password123',
        fullName: 'New User',
        role: 'customer',
      )).thenAnswer((_) async => mockProfile);
      await authProvider.register(
        email: 'new@example.com',
        password: 'password123',
        fullName: 'New User',
        role: 'customer',
      );
      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.userProfile, mockProfile);
    });

    test('logout: Úspešné odhlásenie', () async {
      authProvider._userProfile = UserProfile(
        id: 'user-id',
        email: 'test@example.com',
        role: 'customer',
        fullName: 'Test User',
      );
      authProvider._status = AuthStatus.authenticated;
      when(mockAuthRepository.logout()).thenAnswer((_) async => {});
      await authProvider.logout();
      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(authProvider.userProfile, isNull);
    });

    test('logout: Chyba', () async {
      authProvider._userProfile = UserProfile(
        id: 'user-id',
        email: 'test@example.com',
        role: 'customer',
        fullName: 'Test User',
      );
      authProvider._status = AuthStatus.authenticated;
      when(mockAuthRepository.logout()).thenThrow(Exception('Logout failed'));
      await authProvider.logout();
      expect(authProvider.status, AuthStatus.error);
      expect(authProvider.errorMessage, contains('Logout failed'));
    });
  });
}


// ============================================
// FILE: test/auth/user_profile_test.dart
// ============================================
import 'package:flutter_test/flutter_test.dart';
import '../../lib/auth/auth_repository.dart';

void main() {
  group('UserProfile Tests', () {
    test('fromMap: Úspešné vytvorenie', () {
      final map = {
        'id': 'user-id',
        'email': 'test@example.com',
        'role': 'driver',
        'full_name': 'Test Driver',
      };
      final userProfile = UserProfile.fromMap(map);
      expect(userProfile.id, 'user-id');
      expect(userProfile.email, 'test@example.com');
      expect(userProfile.role, 'driver');
      expect(userProfile.fullName, 'Test Driver');
    });

    test('fromMap: Default hodnoty', () {
      final userProfile = UserProfile.fromMap({});
      expect(userProfile.id, '');
      expect(userProfile.email, '');
      expect(userProfile.role, 'customer');
      expect(userProfile.fullName, '');
    });
  });
}
