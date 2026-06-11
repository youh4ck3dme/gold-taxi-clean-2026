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
    when(() => mockAuthCubit.stream).thenAnswer((_) => Stream.value(Unauthenticated()));

    getIt.registerSingleton<AuthCubit>(mockAuthCubit);
  });

  tearDownAll(() {
    getIt.reset();
  });

  testWidgets('LoginPage renders input fields and login button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    // Verify presence of email/username input
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Prihlásiť sa'), findsOneWidget); // Title or button text

    // Verify password field is obscured
    final passwordField = tester.widget<TextField>(
      find.byType(TextField).last,
    );
    expect(passwordField.obscureText, isTrue);
  });
}
