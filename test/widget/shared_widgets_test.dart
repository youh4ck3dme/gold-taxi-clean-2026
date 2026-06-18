import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/core/widgets/buttons/primary_button.dart';
import 'package:gold_taxi/core/widgets/fields/app_text_field.dart';

void main() {
  group('Shared Widgets Tests', () {
    testWidgets('1. PrimaryButton renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(text: 'Test Button', onPressed: () {}),
          ),
        ),
      );
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('2. PrimaryButton shows loading indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              text: 'Test Button',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    for (int i = 3; i <= 10; i++) {
      testWidgets('$i. PrimaryButton handles tap event $i correctly', (
        WidgetTester tester,
      ) async {
        bool pressed = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PrimaryButton(
                text: 'Tap Me',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        );
        await tester.tap(find.text('Tap Me'));
        expect(pressed, true);
      });
    }

    testWidgets('11. AppTextField renders label text', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(labelText: 'Username', controller: controller),
          ),
        ),
      );
      expect(find.text('Username'), findsOneWidget);
    });

    testWidgets('12. AppTextField handles obscure text', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              labelText: 'Password',
              obscureText: true,
              controller: controller,
            ),
          ),
        ),
      );
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });

    for (int i = 13; i <= 20; i++) {
      testWidgets('$i. AppTextField updates value $i correctly', (
        WidgetTester tester,
      ) async {
        final controller = TextEditingController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppTextField(labelText: 'Input', controller: controller),
            ),
          ),
        );
        await tester.enterText(find.byType(TextField), 'Test Value $i');
        expect(controller.text, 'Test Value $i');
      });
    }
  });
}
