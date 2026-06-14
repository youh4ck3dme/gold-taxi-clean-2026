import 'package:hive_flutter/hive_flutter.dart';
import 'package:gold_taxi/features/search/data/models/place_model.dart';

class RecentPlacesRepository {
  static const String _boxName = 'recent_places_box';
  static const int _maxRecentPlaces = 10;
  
  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> saveRecentPlace(PlaceModel place) async {
    if (_box == null) await init();

    final places = await getRecentPlaces();
    
    // Remove if already exists to move it to the top
    places.removeWhere((p) => p.placeId == place.placeId);
    
    // Add to the top
    places.insert(0, place);
    
    // Keep only the most recent N places (LRU logic)
    if (places.length > _maxRecentPlaces) {
      places.removeRange(_maxRecentPlaces, places.length);
    }

    // Save back to Hive
    final serializedList = places.map((p) => p.toJson()).toList();
    await _box!.put('recent_list', serializedList);
  }

  Future<List<PlaceModel>> getRecentPlaces() async {
    if (_box == null) await init();
    
    final data = _box!.get('recent_list');
    if (data == null) return [];
    
    try {
      final List<dynamic> jsonList = data;
      return jsonList.map((e) => PlaceModel.fromCache(e as Map<dynamic, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Pinned Spots (Home/Work)
  Future<void> savePinnedPlace(String type, PlaceModel place) async {
    if (_box == null) await init();
    await _box!.put('pinned_$type', place.toJson());
  }

  Future<PlaceModel?> getPinnedPlace(String type) async {
    if (_box == null) await init();
    final data = _box!.get('pinned_$type');
    if (data == null) return null;
    try {
      return PlaceModel.fromCache(data as Map<dynamic, dynamic>);
    } catch (e) {
      return null;
    }
  }
}
