import 'package:hive_flutter/hive_flutter.dart';
import 'package:gold_taxi/models/service_model.dart';

class ServicesLocalDataSource {
  static const String _boxName = 'services_posts_box';

  /// Cache services locally
  Future<void> cacheServices(List<ServiceModel> services) async {
    final box = await Hive.openBox(_boxName);
    final servicesJson = services.map((service) => service.toJson()).toList();
    await box.put('cached_services', servicesJson);
  }

  /// Get cached services
  Future<List<ServiceModel>> getCachedServices() async {
    final box = await Hive.openBox(_boxName);
    final servicesJson = box.get('cached_services') as List?;
    if (servicesJson != null) {
      return servicesJson
          .map(
            (json) =>
                ServiceModel.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    }
    return [];
  }
}
