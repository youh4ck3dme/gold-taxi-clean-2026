import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';

import 'package:gold_taxi/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_state.dart';
import 'package:gold_taxi/features/auth/presentation/pages/login_page.dart';

import 'package:gold_taxi/features/home/presentation/pages/home_page.dart';

import 'package:gold_taxi/features/products/presentation/pages/products_page.dart';
import 'package:gold_taxi/features/products/presentation/bloc/products_bloc.dart';
import 'package:gold_taxi/features/products/presentation/bloc/products_state.dart';

import 'package:gold_taxi/features/services/presentation/pages/services_page.dart';
import 'package:gold_taxi/features/services/presentation/bloc/services_bloc.dart';
import 'package:gold_taxi/features/services/presentation/bloc/services_state.dart';

import 'package:gold_taxi/features/events/presentation/pages/events_page.dart';
import 'package:gold_taxi/features/events/presentation/bloc/events_bloc.dart';
import 'package:gold_taxi/features/events/presentation/bloc/events_state.dart';

import 'package:gold_taxi/features/blog/presentation/pages/blog_page.dart';
import 'package:gold_taxi/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:gold_taxi/features/blog/presentation/bloc/blog_state.dart';

import 'package:gold_taxi/features/faq/presentation/pages/faq_page.dart';
import 'package:gold_taxi/features/faq/presentation/bloc/faq_bloc.dart';
import 'package:gold_taxi/features/faq/presentation/bloc/faq_state.dart';

import 'package:gold_taxi/features/insolvency_monitoring/presentation/pages/insolvency_dashboard_page.dart';
import 'package:gold_taxi/features/insolvency_monitoring/presentation/cubits/insolvency_cubit.dart';

import 'package:gold_taxi/models/user_model.dart';
import 'package:gold_taxi/models/product_model.dart';
import 'package:gold_taxi/models/service_model.dart';
import 'package:gold_taxi/models/event_model.dart';
import 'package:gold_taxi/models/post_model.dart';
import 'package:gold_taxi/models/faq_model.dart';
import 'package:gold_taxi/models/invoice_model.dart';
import 'package:gold_taxi/core/services/insolvency_predictor_service.dart';

class MockAuthCubit extends Mock implements AuthCubit {
  @override
  Future<void> close() async {}
}
class MockInsolvencyCubit extends Mock implements InsolvencyCubit {
  @override
  Future<void> close() async {}
}
class MockBlogBloc extends Mock implements BlogBloc {
  @override
  Future<void> close() async {}
}
class MockProductsBloc extends Mock implements ProductsBloc {
  @override
  Future<void> close() async {}
}
class MockServicesBloc extends Mock implements ServicesBloc {
  @override
  Future<void> close() async {}
}
class MockEventsBloc extends Mock implements EventsBloc {
  @override
  Future<void> close() async {}
}
class MockFaqBloc extends Mock implements FaqBloc {
  @override
  Future<void> close() async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final getIt = GetIt.instance;
  late MockAuthCubit mockAuthCubit;
  late MockInsolvencyCubit mockInsolvencyCubit;
  late MockBlogBloc mockBlogBloc;
  late MockProductsBloc mockProductsBloc;
  late MockServicesBloc mockServicesBloc;
  late MockEventsBloc mockEventsBloc;
  late MockFaqBloc mockFaqBloc;

  setUpAll(() {
    mockAuthCubit = MockAuthCubit();
    mockInsolvencyCubit = MockInsolvencyCubit();
    mockBlogBloc = MockBlogBloc();
    mockProductsBloc = MockProductsBloc();
    mockServicesBloc = MockServicesBloc();
    mockEventsBloc = MockEventsBloc();
    mockFaqBloc = MockFaqBloc();

    getIt.registerSingleton<AuthCubit>(mockAuthCubit);
    getIt.registerSingleton<InsolvencyCubit>(mockInsolvencyCubit);
    getIt.registerSingleton<BlogBloc>(mockBlogBloc);
    getIt.registerSingleton<ProductsBloc>(mockProductsBloc);
    getIt.registerSingleton<ServicesBloc>(mockServicesBloc);
    getIt.registerSingleton<EventsBloc>(mockEventsBloc);
    getIt.registerSingleton<FaqBloc>(mockFaqBloc);
  });

  tearDownAll(() {
    getIt.reset();
  });

  group('Gold-Taxi Integration/Widget Tests', () {
    const testUser = UserModel(
      id: '1',
      name: 'Test Driver',
      email: 'driver@test.com',
      role: 'driver',
    );

    testWidgets('1. LoginPage renders form components and bypass button', (WidgetTester tester) async {
      when(() => mockAuthCubit.state).thenReturn(Unauthenticated());
      when(() => mockAuthCubit.stream).thenAnswer((_) => Stream.value(Unauthenticated()));

      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      expect(find.text('Vitajte v Gold-Taxi'), findsOneWidget);
      expect(find.text('Prihlásiť sa'), findsOneWidget);
      expect(find.text('🔧 DEVELOPER BYPASS → DOMOV'), findsOneWidget);
    });

    testWidgets('2. HomePage displays personalized greeting and services grid', (WidgetTester tester) async {
      when(() => mockAuthCubit.state).thenReturn(const Authenticated(testUser));
      when(() => mockAuthCubit.stream).thenAnswer((_) => Stream.value(const Authenticated(testUser)));

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Ahoj, Test Driver 👋'), findsOneWidget);
      expect(find.text('Naše služby'), findsOneWidget);
      expect(find.text('Odvoz'), findsOneWidget);
      expect(find.text('Obchod'), findsOneWidget);
      expect(find.text('Udalosti'), findsOneWidget);
      expect(find.text('Novinky'), findsOneWidget);
      expect(find.text('Centrum podpory & FAQ'), findsOneWidget);
      expect(find.text('Monitoring úpadku'), findsOneWidget);
    });

    testWidgets('3. ProductsPage loads list and builds product cards', (WidgetTester tester) async {
      const product = ProductModel(
        id: 10,
        name: 'Taxi Premium Cap',
        description: 'Cap with Taxi Logo',
        price: 12.0,
        salePrice: 10.0,
        sku: 'CAP-10',
        stock: 5,
      );

      when(() => mockProductsBloc.state).thenReturn(const ProductsLoaded(products: [product]));
      when(() => mockProductsBloc.stream).thenAnswer((_) => Stream.value(const ProductsLoaded(products: [product])));

      await tester.pumpWidget(const MaterialApp(home: ProductsPage()));
      await tester.pump();

      expect(find.text('Produkty'), findsOneWidget);
      expect(find.text('Taxi Premium Cap'), findsOneWidget);
      expect(find.text('12.00 €'), findsOneWidget);
    });

    testWidgets('4. ServicesPage renders standard services list', (WidgetTester tester) async {
      const service = ServiceModel(
        id: 20,
        name: 'VIP Standard Drive',
        description: 'Safe city ride',
        price: 15.0,
        rating: 4.9,
        reviewCount: 30,
        provider: 'Gold Taxi',
        category: 'Ride',
      );

      when(() => mockServicesBloc.state).thenReturn(const ServicesLoaded(services: [service]));
      when(() => mockServicesBloc.stream).thenAnswer((_) => Stream.value(const ServicesLoaded(services: [service])));

      await tester.pumpWidget(const MaterialApp(home: ServicesPage()));
      await tester.pump();

      expect(find.text('Služby'), findsOneWidget);
      expect(find.text('VIP Standard Drive'), findsOneWidget);
    });

    testWidgets('5. EventsPage loads and lists planned taxi routes', (WidgetTester tester) async {
      final event = EventModel(
        id: 30,
        date: DateTime(2026, 6, 15),
        title: 'Weekly Tour Bratislava',
        content: 'Standard group route',
        startDate: DateTime(2026, 6, 15, 12, 0),
        endDate: DateTime(2026, 6, 15, 15, 0),
        location: 'Bratislava Main Station',
        latitude: 48.14,
        longitude: 17.10,
        category: 'Tour',
        price: 10.0,
      );

      when(() => mockEventsBloc.state).thenReturn(EventsLoaded(events: [event]));
      when(() => mockEventsBloc.stream).thenAnswer((_) => Stream.value(EventsLoaded(events: [event])));

      await tester.pumpWidget(const MaterialApp(home: EventsPage()));
      await tester.pump();

      expect(find.text('Udalosti'), findsOneWidget);
      expect(find.text('Weekly Tour Bratislava'), findsOneWidget);
    });

    testWidgets('6. BlogPage lists published news posts', (WidgetTester tester) async {
      final post = PostModel(
        id: 40,
        date: DateTime(2026, 6, 11),
        title: 'New Taxi Fleet Arrived',
        content: 'We added 10 new cars.',
        excerpt: 'New fleet update',
        slug: 'new-fleet',
        authorId: 1,
        categoryIds: const [],
        tagIds: const [],
      );

      when(() => mockBlogBloc.state).thenReturn(BlogLoaded(posts: [post], hasReachedMax: true));
      when(() => mockBlogBloc.stream).thenAnswer((_) => Stream.value(BlogLoaded(posts: [post], hasReachedMax: true)));

      await tester.pumpWidget(const MaterialApp(home: BlogPage()));
      await tester.pump();

      expect(find.text('Blog & Novinky'), findsOneWidget);
      expect(find.text('New Taxi Fleet Arrived'), findsOneWidget);
    });

    testWidgets('7. FAQ Page displays question expansion tiles', (WidgetTester tester) async {
      const faq = FaqModel(
        id: 50,
        question: 'Ako stornovať jazdu?',
        answer: 'Kliknite na tlačidlo storno v detaile jazdy.',
        category: 'Objednávky',
      );

      when(() => mockFaqBloc.state).thenReturn(const FaqLoaded(faqs: [faq]));
      when(() => mockFaqBloc.stream).thenAnswer((_) => Stream.value(const FaqLoaded(faqs: [faq])));

      await tester.pumpWidget(const MaterialApp(home: FaqPage()));
      await tester.pump();

      expect(find.text('Často kladené otázky'), findsOneWidget);
      expect(find.text('Ako stornovať jazdu?'), findsOneWidget);
    });

    testWidgets('8. InsolvencyDashboardPage renders risk gauge and factors', (WidgetTester tester) async {
      final invoice = InvoiceModel(
        id: 'FA-2026-901',
        amount: 1500.0,
        issueDate: DateTime(2026, 5, 15),
        dueDate: DateTime(2026, 5, 29),
      );

      const prediction = InsolvencyPrediction(
        riskScore: 75.0,
        riskLevel: 'Vysoké',
        predictsInsolvencyIn3Months: true,
        riskFactors: ['Oneskorenie platieb viac ako 60 dní'],
        averageDelayDays: 10.0,
        delayTrend: 0.0,
        unpaidRatio: 0.5,
      );

      when(() => mockInsolvencyCubit.loadScenario(any())).thenAnswer((_) async {});
      when(() => mockInsolvencyCubit.state).thenReturn(InsolvencyLoaded(
        invoices: [invoice],
        prediction: prediction,
        activeScenario: 'Reálne dáta (WordPress)',
      ));
      when(() => mockInsolvencyCubit.stream).thenAnswer((_) => Stream.value(InsolvencyLoaded(
        invoices: [invoice],
        prediction: prediction,
        activeScenario: 'Reálne dáta (WordPress)',
      )));

      await tester.pumpWidget(const MaterialApp(home: InsolvencyDashboardPage()));
      await tester.pump();

      expect(find.text('Monitoring úpadku'), findsOneWidget);
      expect(find.text('Vysoké riziko'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Oneskorenie platieb viac ako 60 dní', skipOffstage: false), findsOneWidget);
      expect(find.text('FA-2026-901', skipOffstage: false), findsOneWidget);
    });
  });
}
