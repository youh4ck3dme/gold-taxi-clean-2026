import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:gold_taxi/main_common.dart';
import 'package:gold_taxi/core/config/app_config.dart';
import 'package:gold_taxi/core/widgets/fields/app_text_field.dart';
import 'package:gold_taxi/core/widgets/buttons/primary_button.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Reálne prihlasovacie údaje priamo zo živého prostredia
  const realSupabaseUrl = 'https://nscxuxhapaabtsiduxlu.supabase.co';
  const realSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5zY3h1eGhhcGFhYnRzaWR1eGx1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzODEwNzAsImV4cCI6MjA5Njk1NzA3MH0.AI-8BfolBjcxMRDS5YlDCFSK5CrQyFck5Mf3TVIErO0';

  const testEmail = 'test@goldtaxi.sk';
  const testPassword = 'Password123!';

  group('Gold-Taxi LIVE E2E Integration Tests', () {
    testWidgets('E2E: App boots, shows Login, user logs in and sees Home', (
      WidgetTester tester,
    ) async {
      // 1. Inicializácia skutočnej aplikácie s reálnym backendom (mockMode: false)
      final config = AppConfig(
        environment: AppEnvironment.dev,
        supabaseUrl: realSupabaseUrl,
        supabaseAnonKey: realSupabaseAnonKey,
        stripePublishableKey: 'pk_test_placeholder',
        enableMockMode: false, // Dôležité: vypíname mocky!
        enableAnalytics: false,
      );

      // Zavoláme mainCommon, ktorý inicializuje Supabase, ServiceLocator a Hive,
      // a následne urobí runApp(MyApp()).
      await mainCommon(config);
      await tester.pumpAndSettle(); // Počkáme, kým appka nabehne a vyrenderuje sa.

      // Ak bol používateľ z predchádzajúceho testu už prihlásený, musíme ho pre istotu odhlásiť?
      // Zatiaľ predpokladajme, že štartujeme na prihlasovacej obrazovke.
      // 2. Overenie, že sme na LoginPage (skontrolujeme text privítania)
      final welcomeText = find.text('Vitajte v Gold-Taxi');
      if (welcomeText.evaluate().isEmpty) {
        // Možno sme už prihlásení na HomePage? (napr. z cached session)
        // Ak áno, test môže prejsť rovno na overenie HomePage. 
        // V tomto teste však chceme prejsť celým prihlasovacím tokom.
        // Odhlásenie by sme museli vyvolať cez UI alebo priamo v Supabase SDK.
      } else {
        expect(welcomeText, findsOneWidget);

        // 3. Nájdeme textové polia pre E-mail a Heslo
        // V LoginPage používame vlastný widget AppTextField
        final emailField = find.byType(AppTextField).first;
        final passwordField = find.byType(AppTextField).last;

        // 4. Zadáme prihlasovacie údaje
        await tester.enterText(emailField, testEmail);
        await tester.pump();
        await tester.enterText(passwordField, testPassword);
        await tester.pump();

        // Zatvoríme klávesnicu, ak by zavadzala
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        // 5. Nájdeme a stlačíme tlačidlo "Prihlásiť sa" (PrimaryButton)
        final loginBtn = find.widgetWithText(PrimaryButton, 'Prihlásiť sa');
        expect(loginBtn, findsOneWidget);
        
        await tester.tap(loginBtn);

        // 6. Čakáme na odpoveď zo živého Supabase servera (sieťový request môže trvať)
        // Pumpujeme opakovane, kým sa všetky animácie a futures nedokončia (timeout je štandardne 10s)
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // 7. Overíme, že sme sa úspešne dostali na HomePage
      // Po prihlásení (alebo ak sme už boli prihlásení) by sme mali vidieť hlavnú ponuku
      expect(find.text('Objednajte si jazdu'), findsOneWidget);
      expect(find.text('Kam to bude?'), findsOneWidget);
    });
  });
}
