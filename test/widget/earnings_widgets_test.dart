import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/features/earnings/data/models/bank_account_model.dart';
import 'package:gold_taxi/features/earnings/presentation/widgets/bank_account_dialog.dart';

void main() {
  group('BankAccountDialog Widget Tests', () {
    testWidgets('1. BankAccountDialog renders fields and handles save', (WidgetTester tester) async {
      BankAccountModel? savedAccount;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => BankAccountDialog(
                      driverId: 'driver_test',
                      onSave: (account) {
                        savedAccount = account;
                      },
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            }
          ),
        ),
      ));

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check fields are present
      expect(find.text('Pridať Bankový Účet'), findsOneWidget);
      expect(find.text('Stripe Account ID'), findsOneWidget);
      expect(find.text('Názov banky'), findsOneWidget);
      expect(find.text('Meno majiteľa účtu'), findsOneWidget);
      expect(find.text('Posledné 4 číslice účtu / IBANu'), findsOneWidget);

      // Find TextFormFields
      final stripeField = find.ancestor(of: find.text('Stripe Account ID'), matching: find.byType(TextFormField));
      final bankField = find.ancestor(of: find.text('Názov banky'), matching: find.byType(TextFormField));
      final holderField = find.ancestor(of: find.text('Meno majiteľa účtu'), matching: find.byType(TextFormField));
      final digitsField = find.ancestor(of: find.text('Posledné 4 číslice účtu / IBANu'), matching: find.byType(TextFormField));

      // Enter details
      await tester.enterText(stripeField, 'acct_123456');
      await tester.enterText(bankField, 'Tatra Banka');
      await tester.enterText(holderField, 'Ján Kováč');
      await tester.enterText(digitsField, '1234');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Uložiť'));
      await tester.pumpAndSettle();

      // Verify onSave callback was executed with correct values
      expect(savedAccount, isNotNull);
      expect(savedAccount!.stripeAccountId, 'acct_123456');
      expect(savedAccount!.bankName, 'Tatra Banka');
      expect(savedAccount!.accountHolderName, 'Ján Kováč');
      expect(savedAccount!.bankAccountLast4, '1234');
    });

    testWidgets('2. BankAccountDialog validation works', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => BankAccountDialog(
                      driverId: 'driver_test',
                      onSave: (_) {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            }
          ),
        ),
      ));

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap save without filling
      await tester.tap(find.text('Uložiť'));
      await tester.pumpAndSettle();

      // Check validation error messages
      expect(find.text('Zadajte Stripe Account ID'), findsOneWidget);
      expect(find.text('Zadajte názov banky'), findsOneWidget);
      expect(find.text('Zadajte meno majiteľa'), findsOneWidget);
      expect(find.text('Zadajte 4 číslice'), findsOneWidget);
    });

    testWidgets('3. BankAccountDialog invalid Stripe ID validation works', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => BankAccountDialog(
                      driverId: 'driver_test',
                      onSave: (_) {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            }
          ),
        ),
      ));

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final stripeField = find.ancestor(of: find.text('Stripe Account ID'), matching: find.byType(TextFormField));
      await tester.enterText(stripeField, 'invalid_id');
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.text('Uložiť'));
      await tester.pumpAndSettle();

      // Check Stripe Account ID validation error
      expect(find.text('Stripe Account ID musí začínať s "acct_"'), findsOneWidget);
    });
  });
}
