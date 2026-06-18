import 'package:hive_flutter/hive_flutter.dart';
import 'package:gold_taxi/models/event_model.dart';

class EventsLocalDataSource {
  static const String _boxName = 'events_posts_box';

  /// Cache events locally
  Future<void> cacheEvents(List<EventModel> events) async {
    final box = await Hive.openBox(_boxName);
    final eventsJson = events.map((event) => event.toJson()).toList();
    await box.put('cached_events', eventsJson);
  }

  /// Get cached events
  Future<List<EventModel>> getCachedEvents() async {
    final box = await Hive.openBox(_boxName);
    final eventsJson = box.get('cached_events') as List?;
    if (eventsJson != null) {
      return eventsJson
          .map(
            (json) =>
                EventModel.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    }
    return [];
  }
}
