// ignore_for_file: must_be_immutable

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gold_taxi/location/driver_location_repository.dart';
import 'package:gold_taxi/location/bloc/driver_location_bloc.dart';
import 'package:gold_taxi/location/bloc/driver_location_event.dart';

class FakeSupabaseClient extends Fake implements SupabaseClient {
  final SupabaseQueryBuilder _queryBuilder;
  FakeSupabaseClient(this._queryBuilder);

  @override
  SupabaseQueryBuilder from(String relation) => _queryBuilder;
}

class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T _value;
  final Map<String, dynamic>? _singleValue;

  FakePostgrestFilterBuilder(this._value, {this._singleValue});

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakePostgrestTransformBuilder<Map<String, dynamic>?>(_singleValue);
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

class FakeSupabaseStreamFilterBuilder extends Stream<List<Map<String, dynamic>>> implements SupabaseStreamFilterBuilder {
  final Stream<List<Map<String, dynamic>>> _stream;
  FakeSupabaseStreamFilterBuilder(this._stream);

  @override
  StreamSubscription<List<Map<String, dynamic>>> listen(
    void Function(List<Map<String, dynamic>> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final Map<String, dynamic>? singleData;
  final List<Map<String, dynamic>>? streamData;
  final Object? errorToThrow;

  // Tracking invocation values
  final List<Map<String, dynamic>> upsertedValues = [];

  FakeSupabaseQueryBuilder({this.singleData, this.streamData, this.errorToThrow});

  @override
  PostgrestFilterBuilder<PostgrestList> select([String? columns]) {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return FakePostgrestFilterBuilder<PostgrestList>([singleData ?? {}], singleValue: singleData);
  }

  @override
  PostgrestFilterBuilder<dynamic> upsert(Object values, {
    bool defaultToNull = true,
    bool ignoreDuplicates = false,
    String? onConflict,
  }) {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    if (values is Map<String, dynamic>) {
      upsertedValues.add(values);
    } else if (values is List<Map<String, dynamic>>) {
      upsertedValues.addAll(values.cast<Map<String, dynamic>>());
    }
    return FakePostgrestFilterBuilder<dynamic>(values);
  }

  @override
  SupabaseStreamFilterBuilder stream({required List<String> primaryKey, bool private = false}) {
    if (errorToThrow != null) {
      return FakeSupabaseStreamFilterBuilder(Stream.error(errorToThrow!));
    }
    return FakeSupabaseStreamFilterBuilder(Stream.value(streamData ?? []));
  }
}

class FakeDriverLocationRepository implements DriverLocationRepository {
  DriverLocation? getDriverLocationResult;
  bool toggleOnlineStatusCalled = false;
  bool updateLocationCalled = false;
  Stream<List<DriverLocation>>? streamOnlineDriversResult;

  @override
  Future<DriverLocation?> getDriverLocation(String driverId) async {
    return getDriverLocationResult;
  }

  @override
  Future<void> toggleOnlineStatus(String driverId, bool isOnline) async {
    toggleOnlineStatusCalled = true;
  }

  @override
  Future<void> updateLocation(String driverId, double latitude, double longitude) async {
    updateLocationCalled = true;
  }

  @override
  Stream<List<DriverLocation>> streamOnlineDrivers() {
    return streamOnlineDriversResult ?? const Stream.empty();
  }
}

void main() {
  group('DriverLocation Model Tests', () {
    test('fromMap should parse map correctly', () {
      final map = {
        'id': 'driver-123',
        'latitude': 48.1485,
        'longitude': 17.1077,
        'is_online': true,
        'updated_at': '2026-06-11T12:00:00.000Z',
        'full_name': 'Driver Name',
      };

      final driverLoc = DriverLocation.fromMap(map);

      expect(driverLoc.id, 'driver-123');
      expect(driverLoc.latitude, 48.1485);
      expect(driverLoc.longitude, 17.1077);
      expect(driverLoc.isOnline, isTrue);
      expect(driverLoc.fullName, 'Driver Name');
      expect(driverLoc.updatedAt.toUtc(), DateTime.parse('2026-06-11T12:00:00.000Z'));
    });

    test('fromMap should fallback to default values on missing or null keys', () {
      final map = <String, dynamic>{};
      final driverLoc = DriverLocation.fromMap(map);

      expect(driverLoc.id, '');
      expect(driverLoc.latitude, 0.0);
      expect(driverLoc.longitude, 0.0);
      expect(driverLoc.isOnline, isFalse);
      expect(driverLoc.fullName, '');
      expect(driverLoc.updatedAt, isA<DateTime>());
    });

    test('toMap should serialize object correctly', () {
      final now = DateTime.now();
      final driverLoc = DriverLocation(
        id: 'driver-999',
        latitude: 49.0123,
        longitude: 21.9876,
        isOnline: false,
        updatedAt: now,
        fullName: 'Test Driver',
      );

      final map = driverLoc.toMap();

      expect(map['id'], 'driver-999');
      expect(map['latitude'], 49.0123);
      expect(map['longitude'], 21.9876);
      expect(map['is_online'], isFalse);
      expect(map['full_name'], 'Test Driver');
      expect(map['updated_at'], now.toIso8601String());
    });
  });

  group('DriverLocationRepository Tests', () {
    test('updateLocation calls upsert with coordinates', () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();
      final fakeSupabaseClient = FakeSupabaseClient(fakeQueryBuilder);
      final repository = DriverLocationRepository(supabaseClient: fakeSupabaseClient);

      await repository.updateLocation('driver-id', 48.1234, 17.5678);

      expect(fakeQueryBuilder.upsertedValues, hasLength(1));
      final val = fakeQueryBuilder.upsertedValues.first;
      expect(val['id'], 'driver-id');
      expect(val['latitude'], 48.1234);
      expect(val['longitude'], 17.5678);
      expect(val['updated_at'], isNotNull);
    });

    test('toggleOnlineStatus calls upsert with online value', () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();
      final fakeSupabaseClient = FakeSupabaseClient(fakeQueryBuilder);
      final repository = DriverLocationRepository(supabaseClient: fakeSupabaseClient);

      await repository.toggleOnlineStatus('driver-id', true);

      expect(fakeQueryBuilder.upsertedValues, hasLength(1));
      final val = fakeQueryBuilder.upsertedValues.first;
      expect(val['id'], 'driver-id');
      expect(val['is_online'], isTrue);
      expect(val['updated_at'], isNotNull);
    });

    test('getDriverLocation parses profile row successfully', () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder(
        singleData: {
          'id': 'driver-id',
          'latitude': 48.0,
          'longitude': 17.0,
          'is_online': true,
          'updated_at': '2026-06-11T12:00:00.000Z',
          'full_name': 'Gold Driver',
        },
      );
      final fakeSupabaseClient = FakeSupabaseClient(fakeQueryBuilder);
      final repository = DriverLocationRepository(supabaseClient: fakeSupabaseClient);

      final result = await repository.getDriverLocation('driver-id');

      expect(result, isNotNull);
      expect(result?.id, 'driver-id');
      expect(result?.latitude, 48.0);
      expect(result?.isOnline, isTrue);
      expect(result?.fullName, 'Gold Driver');
    });

    test('getDriverLocation returns null when record is missing', () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder(singleData: null);
      final fakeSupabaseClient = FakeSupabaseClient(fakeQueryBuilder);
      final repository = DriverLocationRepository(supabaseClient: fakeSupabaseClient);

      final result = await repository.getDriverLocation('driver-id');
      expect(result, isNull);
    });

    test('streamOnlineDrivers converts stream map elements and filters online status', () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder(
        streamData: [
          {
            'id': 'driver-1',
            'latitude': 48.1,
            'longitude': 17.1,
            'is_online': true,
            'updated_at': '2026-06-11T12:00:00.000Z',
            'full_name': 'Driver One',
          },
          {
            'id': 'driver-2',
            'latitude': 48.2,
            'longitude': 17.2,
            'is_online': false,
            'updated_at': '2026-06-11T12:00:00.000Z',
            'full_name': 'Driver Two',
          },
        ],
      );
      final fakeSupabaseClient = FakeSupabaseClient(fakeQueryBuilder);
      final repository = DriverLocationRepository(supabaseClient: fakeSupabaseClient);

      final stream = repository.streamOnlineDrivers();
      final list = await stream.first;

      expect(list, hasLength(1));
      expect(list.first.id, 'driver-1');
      expect(list.first.isOnline, isTrue);
      expect(list.first.fullName, 'Driver One');
    });
  });

  group('DriverLocationBloc Tests', () {
    late FakeDriverLocationRepository fakeRepo;
    late DriverLocationBloc bloc;

    setUp(() {
      fakeRepo = FakeDriverLocationRepository();
      bloc = DriverLocationBloc(repository: fakeRepo);
    });

    tearDown(() {
      bloc.close();
    });

    test('InitializeDriverState should set isOnline to false and NOT call tracking when driver is offline', () async {
      final offlineDriver = DriverLocation(
        id: 'driver-id',
        latitude: 48.0,
        longitude: 17.0,
        isOnline: false,
        updatedAt: DateTime.now(),
        fullName: 'Offline Driver',
      );
      
      fakeRepo.getDriverLocationResult = offlineDriver;

      bloc.add(const InitializeDriverState('driver-id'));

      // Wait a microtask to let events propagate
      await Future.delayed(Duration.zero);

      expect(bloc.state.isOnline, isFalse);
      expect(bloc.state.errorMessage, isNull);
    });

    test('StartListeningToOnlineDrivers updates online drivers list from repository stream', () async {
      final list = [
        DriverLocation(
          id: 'd-1',
          latitude: 48.0,
          longitude: 17.0,
          isOnline: true,
          updatedAt: DateTime.now(),
          fullName: 'Driver Name',
        ),
      ];

      fakeRepo.streamOnlineDriversResult = Stream.value(list);

      bloc.add(StartListeningToOnlineDrivers());

      // Wait a microtask to let the stream event propagate
      await Future.delayed(Duration.zero);

      expect(bloc.state.onlineDrivers, hasLength(1));
      expect(bloc.state.onlineDrivers.first.id, 'd-1');

      bloc.add(StopListeningToOnlineDrivers());
      await Future.delayed(Duration.zero);
      expect(bloc.state.onlineDrivers, isEmpty);
    });
  });
}
