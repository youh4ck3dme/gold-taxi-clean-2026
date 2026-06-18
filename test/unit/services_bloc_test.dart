import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/services/presentation/bloc/services_bloc.dart';
import 'package:gold_taxi/features/services/presentation/bloc/services_event.dart';
import 'package:gold_taxi/features/services/presentation/bloc/services_state.dart';
import 'package:gold_taxi/features/services/data/repositories/services_repository.dart';
import 'package:gold_taxi/models/service_model.dart';

class MockServicesRepository extends Mock implements ServicesRepository {}

void main() {
  late ServicesBloc servicesBloc;
  late MockServicesRepository mockServicesRepository;

  setUp(() {
    mockServicesRepository = MockServicesRepository();
    servicesBloc = ServicesBloc(mockServicesRepository);
  });

  tearDown(() {
    servicesBloc.close();
  });

  group('ServicesBloc Tests', () {
    const testService = ServiceModel(
      id: 1,
      name: 'VIP Airport Shuttle',
      description: 'Luxury shuttle service',
      price: 45.0,
      rating: 4.8,
      reviewCount: 12,
      provider: 'Gold Taxi Express',
      category: 'Shuttle',
      images: ['https://example.com/shuttle.png'],
    );

    test('Initial state is ServicesInitial', () {
      expect(servicesBloc.state, isA<ServicesInitial>());
    });

    test(
      'FetchServices emits [ServicesLoading, ServicesLoaded] when repository succeeds',
      () async {
        when(
          () => mockServicesRepository.getServices(
            page: any(named: 'page'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => [testService]);

        expectLater(
          servicesBloc.stream,
          emitsInOrder([isA<ServicesLoading>(), isA<ServicesLoaded>()]),
        );

        servicesBloc.add(const FetchServices());
      },
    );

    test(
      'FetchServices emits [ServicesLoading, ServicesError] when repository throws error',
      () async {
        when(
          () => mockServicesRepository.getServices(
            page: any(named: 'page'),
            search: any(named: 'search'),
          ),
        ).thenThrow(Exception('API error'));

        expectLater(
          servicesBloc.stream,
          emitsInOrder([isA<ServicesLoading>(), isA<ServicesError>()]),
        );

        servicesBloc.add(const FetchServices());
      },
    );
  });
}
