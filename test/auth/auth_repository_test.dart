// ignore_for_file: must_be_immutable

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gold_taxi/auth/auth_repository.dart';

class FakeUser extends Fake implements User {
  final String _id;
  final String? _email;
  FakeUser(this._id, this._email);

  @override
  String get id => _id;

  @override
  String? get email => _email;
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  User? currentUserValue;
  AuthResponse? authResponseResult;
  bool signOutCalled = false;
  Object? errorToThrow;

  @override
  User? get currentUser => currentUserValue;

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return authResponseResult ?? AuthResponse(user: null);
  }

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    dynamic channel,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return authResponseResult ?? AuthResponse(user: null);
  }

  @override
  Future<void> signOut({dynamic scope}) async {
    signOutCalled = true;
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  final GoTrueClient _auth;
  final SupabaseQueryBuilder _queryBuilder;

  FakeSupabaseClient(this._auth, this._queryBuilder);

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseQueryBuilder from(String relation) => _queryBuilder;
}

class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T _value;
  FakePostgrestFilterBuilder(this._value);

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    if (_value is List && (_value as List).isNotEmpty) {
      return FakePostgrestTransformBuilder<Map<String, dynamic>?>(_value[0]);
    }
    return FakePostgrestTransformBuilder<Map<String, dynamic>?>(null);
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    if (_value is List && (_value as List).isNotEmpty) {
      return FakePostgrestTransformBuilder<Map<String, dynamic>>(_value[0]);
    }
    throw const PostgrestException(message: 'No profile found');
  }

  @override
  Future<U> then<U>(FutureOr<U> Function(T) onValue, {Function? onError}) {
    return Future.value(_value).then(onValue, onError: onError);
  }
}

class FakePostgrestTransformBuilder<T> extends Fake implements PostgrestTransformBuilder<T> {
  final T _value;
  FakePostgrestTransformBuilder(this._value);

  @override
  Future<U> then<U>(FutureOr<U> Function(T) onValue, {Function? onError}) {
    return Future.value(_value).then(onValue, onError: onError);
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final Map<String, dynamic>? profileData;
  final Object? errorToThrow;
  FakeSupabaseQueryBuilder({this.profileData, this.errorToThrow});

  @override
  PostgrestFilterBuilder<PostgrestList> select([String? columns]) {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return FakePostgrestFilterBuilder<PostgrestList>([profileData ?? {}]);
  }

  @override
  PostgrestFilterBuilder<dynamic> insert(Object values, {
    bool defaultToNull = true,
  }) {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return FakePostgrestFilterBuilder<dynamic>([]);
  }
}

void main() {
  late AuthRepository authRepository;
  late FakeSupabaseClient fakeSupabaseClient;
  late FakeGoTrueClient fakeAuth;
  late FakeUser fakeUser;

  group('AuthRepository Tests', () {
    test('login: Úspešné prihlásenie', () async {
      const email = 'test@example.com';
      const password = 'password123';
      fakeUser = FakeUser('user-id', email);
      fakeAuth = FakeGoTrueClient()..authResponseResult = AuthResponse(user: fakeUser);
      
      final mockProfileData = {
        'id': 'user-id',
        'email': email,
        'role': 'customer',
        'full_name': 'Test User',
      };
      final fakeQueryBuilder = FakeSupabaseQueryBuilder(profileData: mockProfileData);
      fakeSupabaseClient = FakeSupabaseClient(fakeAuth, fakeQueryBuilder);
      authRepository = AuthRepository(supabaseClient: fakeSupabaseClient);

      final result = await authRepository.login(email, password);
      expect(result, isA<UserProfile>());
      expect(result?.email, email);
      expect(result?.role, 'customer');
    });

    test('login: Nesprávny email alebo heslo', () async {
      const email = 'wrong@example.com';
      const password = 'wrongpassword';
      fakeAuth = FakeGoTrueClient()..errorToThrow = Exception('Invalid credentials');
      fakeSupabaseClient = FakeSupabaseClient(fakeAuth, FakeSupabaseQueryBuilder());
      authRepository = AuthRepository(supabaseClient: fakeSupabaseClient);

      expect(() => authRepository.login(email, password), throwsException);
    });

    test('login: Chýbajúci profil', () async {
      const email = 'no-profile@example.com';
      const password = 'password123';
      fakeUser = FakeUser('no-profile-id', email);
      fakeAuth = FakeGoTrueClient()..authResponseResult = AuthResponse(user: fakeUser);
      
      final fakeQueryBuilder = FakeSupabaseQueryBuilder(errorToThrow: Exception('No profile found'));
      fakeSupabaseClient = FakeSupabaseClient(fakeAuth, fakeQueryBuilder);
      authRepository = AuthRepository(supabaseClient: fakeSupabaseClient);

      expect(() => authRepository.login(email, password), throwsException);
    });

    test('register: Úspešná registrácia', () async {
      const email = 'new@example.com';
      const password = 'password123';
      const fullName = 'New User';
      const role = 'driver';
      fakeUser = FakeUser('new-user-id', email);
      fakeAuth = FakeGoTrueClient()..authResponseResult = AuthResponse(user: fakeUser);
      
      final mockProfileData = {
        'id': 'new-user-id',
        'email': email,
        'role': role,
        'full_name': fullName,
      };
      final fakeQueryBuilder = FakeSupabaseQueryBuilder(profileData: mockProfileData);
      fakeSupabaseClient = FakeSupabaseClient(fakeAuth, fakeQueryBuilder);
      authRepository = AuthRepository(supabaseClient: fakeSupabaseClient);

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
      fakeAuth = FakeGoTrueClient()..errorToThrow = Exception('Registration failed');
      fakeSupabaseClient = FakeSupabaseClient(fakeAuth, FakeSupabaseQueryBuilder());
      authRepository = AuthRepository(supabaseClient: fakeSupabaseClient);

      expect(
        () => authRepository.register(email: email, password: password, fullName: 'Test', role: 'customer'),
        throwsException,
      );
    });

    test('logout: Úspešné odhlásenie', () async {
      fakeAuth = FakeGoTrueClient();
      fakeSupabaseClient = FakeSupabaseClient(fakeAuth, FakeSupabaseQueryBuilder());
      authRepository = AuthRepository(supabaseClient: fakeSupabaseClient);

      await authRepository.logout();
      expect(fakeAuth.signOutCalled, isTrue);
    });

    test('getCurrentUser: Používateľ je prihlásený', () async {
      const email = 'current@example.com';
      fakeUser = FakeUser('current-user-id', email);
      fakeAuth = FakeGoTrueClient()..currentUserValue = fakeUser;
      
      final mockProfileData = {
        'id': 'current-user-id',
        'email': email,
        'role': 'customer',
        'full_name': 'Current User',
      };
      final fakeQueryBuilder = FakeSupabaseQueryBuilder(profileData: mockProfileData);
      fakeSupabaseClient = FakeSupabaseClient(fakeAuth, fakeQueryBuilder);
      authRepository = AuthRepository(supabaseClient: fakeSupabaseClient);

      final result = await authRepository.getCurrentUser();
      expect(result, isA<UserProfile>());
      expect(result?.email, email);
    });

    test('getCurrentUser: Žiadny používateľ', () async {
      fakeAuth = FakeGoTrueClient()..currentUserValue = null;
      fakeSupabaseClient = FakeSupabaseClient(fakeAuth, FakeSupabaseQueryBuilder());
      authRepository = AuthRepository(supabaseClient: fakeSupabaseClient);

      final result = await authRepository.getCurrentUser();
      expect(result, isNull);
    });
  });
}
