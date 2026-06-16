import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_state.dart';
import 'package:gold_taxi/features/auth/presentation/pages/login_page.dart';

class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  final getIt = GetIt.instance;
  late MockAuthCubit mockAuthCubit;

  setUpAll(() {
    mockAuthCubit = MockAuthCubit();
    // Stub AuthCubit stream and state
    when(() => mockAuthCubit.state).thenReturn(Unauthenticated());
    when(
      () => mockAuthCubit.stream,
    ).thenAnswer((_) => Stream.value(Unauthenticated()));
    when(() => mockAuthCubit.close()).thenAnswer((_) async {});

    getIt.registerSingleton<AuthCubit>(mockAuthCubit);
  });

  tearDownAll(() async {
    await mockAuthCubit.close();
    await getIt.reset();
  });

  testWidgets('LoginPage renders input fields and login button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Používateľské meno / E-mail'), findsOneWidget);
    expect(find.text('Heslo'), findsOneWidget);
    expect(find.text('PRIHLÁSIŤ SA'), findsOneWidget);
    expect(find.text('Pokračovať cez Google'), findsOneWidget);
  });
}
