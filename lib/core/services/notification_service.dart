import 'package:logger/logger.dart';

class NotificationService {
  final Logger _logger = Logger();

  /// Initialize notifications (Firebase completely disabled)
  Future<void> initialize() async {
    _logger.i('🔔 NotificationService initialized (No Firebase).');
  }
}
