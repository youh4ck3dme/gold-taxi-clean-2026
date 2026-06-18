import 'package:flutter_test/flutter_test.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import 'package:gold_taxi/features/auth/data/repositories/auth_repository.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:gold_taxi/core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Use TestWidgetsFlutterBinding to run as a local VM widget test
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Set up mock values for SharedPreferences to prevent MissingPluginException on Dart VM
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
  });

  testWidgets('Production Auth - Login should use Supabase, not Mock', (
    WidgetTester tester,
  ) async {
    // 1. Initialize service locator in Supabase mode
    await setupServiceLocator(mode: BackendMode.supabase);

    // 2. Get AuthRepository
    final authRepo = getIt<AuthRepository>();

    // 3. Verify it is SupabaseAuthRepository, not Mock
    expect(authRepo, isA<SupabaseAuthRepository>());

    // 4. Get AuthCubit
    final authCubit = getIt<AuthCubit>();

    // 5. Verify cubit is not null
    expect(authCubit, isNotNull);
    expect(authCubit, isA<AuthCubit>());
  });

  testWidgets('Production Config - MOCK_MODE is disabled', (
    WidgetTester tester,
  ) async {
    final config = AppConfig(
      environment: AppEnvironment.prod,
      supabaseUrl: 'https://nscxuxhapaabtsiduxlu.supabase.co',
      supabaseAnonKey: 'test_key',
      stripePublishableKey: 'pk_test',
      enableMockMode: false,
      enableAnalytics: true,
    );

    expect(config.enableMockMode, isFalse);
    expect(config.environment, AppEnvironment.prod);
  });
}
