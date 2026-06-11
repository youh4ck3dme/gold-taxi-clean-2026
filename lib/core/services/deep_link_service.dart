import 'package:app_links/app_links.dart';
import 'package:logger/logger.dart';
import 'package:gold_taxi/routes/app_router.dart';

class DeepLinkService {
  final _appLinks = AppLinks();
  final Logger _logger = Logger();

  /// Initialize deep linking listeners
  void initialize() {
    // 1. Listen to incoming links when app is in background/foreground
    _appLinks.uriLinkStream.listen(
      (uri) {
        _logger.i('🔗 Incoming deep link URI: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        _logger.e('🔗 Error listening to deep links: $err');
      },
    );

    // 2. Handle app start link (if app was terminated and opened by deep link)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _logger.i('🔗 Terminated app start deep link URI: $uri');
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    // Scheme format: bolt://products/12 -> path: /products/detail, extra: ProductModel with ID 12
    // For simplicity, we can route to paths or trigger details directly.
    _logger.i('🔗 Handling deep link path: ${uri.path}');
    final segments = uri.pathSegments; // e.g. ['products', '12']

    if (segments.length >= 2) {
      final section = segments[0]; // e.g. products
      final id = segments[1]; // e.g. 12
      _logger.i('🔗 Deep link section: $section, ID: $id');

      if (section == 'products') {
        appRouter.go('/products'); // Or navigate to lists first
        // Note: For full production routing with direct models loading, 
        // we can fetch by ID from repository or construct path with query params.
      } else if (section == 'services') {
        appRouter.go('/services');
      } else if (section == 'events') {
        appRouter.go('/events');
      }
    }
  }
}
