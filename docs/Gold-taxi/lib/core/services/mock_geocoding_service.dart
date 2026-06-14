import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationModel {
  final String name;
  final String address;
  final LatLng position;

  const LocationModel({
    required this.name,
    required this.address,
    required this.position,
  });
}

class MockGeocodingService {
  static const List<LocationModel> kosiceLocations = [
    LocationModel(
      name: 'Centrum Košice',
      address: 'Hlavná ulica, 040 01 Košice',
      position: LatLng(48.7219, 21.2575),
    ),
    LocationModel(
      name: 'Letisko Košice',
      address: 'Letisková ulica, 041 75 Košice',
      position: LatLng(48.6631, 21.2403),
    ),
    LocationModel(
      name: 'Železničná stanica Košice',
      address: 'Staničné námestie, 040 01 Košice',
      position: LatLng(48.7224, 21.2675),
    ),
    LocationModel(
      name: 'Aupark Košice',
      address: 'Námestie osloboditeľov 1, 040 01 Košice',
      position: LatLng(48.7188, 21.2614),
    ),
    LocationModel(
      name: 'Steel Aréna',
      address: 'Nerudova 12, 040 01 Košice',
      position: LatLng(48.7154, 21.2492),
    ),
    LocationModel(
      name: 'Atrium Optima',
      address: 'Moldavská cesta 32, 040 11 Košice',
      position: LatLng(48.6998, 21.2335),
    ),
    LocationModel(
      name: 'Sídlisko KVP',
      address: 'Trieda KVP, 040 23 Košice',
      position: LatLng(48.7150, 21.2142),
    ),
    LocationModel(
      name: 'Sídlisko Terasa',
      address: 'Trieda SNP, 040 11 Košice',
      position: LatLng(48.7167, 21.2356),
    ),
    LocationModel(
      name: 'Sídlisko Furča (Dargovských hrdinov)',
      address: 'Trieda arm. gen. Svobodu, 040 22 Košice',
      position: LatLng(48.7364, 21.2869),
    ),
    LocationModel(
      name: 'Sídlisko Nad jazerom',
      address: 'Napájadlá, 040 12 Košice',
      position: LatLng(48.6874, 21.2882),
    ),
    LocationModel(
      name: 'Sídlisko Ťahanovce',
      address: 'Americká trieda, 040 13 Košice',
      position: LatLng(48.7542, 21.2631),
    ),
  ];

  static Future<List<LocationModel>> search(String query) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
    if (query.isEmpty) return kosiceLocations;
    return kosiceLocations
        .where((loc) => 
            loc.name.toLowerCase().contains(query.toLowerCase()) ||
            loc.address.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
