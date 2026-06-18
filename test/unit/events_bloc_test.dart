import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gold_taxi/features/events/presentation/bloc/events_bloc.dart';
import 'package:gold_taxi/features/events/presentation/bloc/events_event.dart';
import 'package:gold_taxi/features/events/presentation/bloc/events_state.dart';
import 'package:gold_taxi/features/events/data/repositories/events_repository.dart';
import 'package:gold_taxi/models/event_model.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  late EventsBloc eventsBloc;
  late MockEventsRepository mockEventsRepository;

  setUp(() {
    mockEventsRepository = MockEventsRepository();
    eventsBloc = EventsBloc(mockEventsRepository);
  });

  tearDown(() {
    eventsBloc.close();
  });

  group('EventsBloc Tests', () {
    final testEvent = EventModel(
      id: 1,
      date: DateTime(2026, 12, 15),
      title: 'Grand Taxi Gala',
      content: 'Annual driver celebration event',
      startDate: DateTime(2026, 12, 15, 18, 0),
      endDate: DateTime(2026, 12, 15, 23, 30),
      location: 'Grand Hotel Bratislava',
      latitude: 48.1485,
      longitude: 17.1077,
      category: 'Celebration',
      price: 25.0,
      images: const ['https://example.com/gala.png'],
    );

    test('Initial state is EventsInitial', () {
      expect(eventsBloc.state, isA<EventsInitial>());
    });

    test(
      'FetchEvents emits [EventsLoading, EventsLoaded] when repository succeeds',
      () async {
        when(
          () => mockEventsRepository.getEvents(
            page: any(named: 'page'),
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => [testEvent]);

        expectLater(
          eventsBloc.stream,
          emitsInOrder([isA<EventsLoading>(), isA<EventsLoaded>()]),
        );

        eventsBloc.add(const FetchEvents());
      },
    );

    test(
      'FetchEvents emits [EventsLoading, EventsError] when repository throws error',
      () async {
        when(
          () => mockEventsRepository.getEvents(
            page: any(named: 'page'),
            search: any(named: 'search'),
          ),
        ).thenThrow(Exception('API error'));

        expectLater(
          eventsBloc.stream,
          emitsInOrder([isA<EventsLoading>(), isA<EventsError>()]),
        );

        eventsBloc.add(const FetchEvents());
      },
    );
  });
}
