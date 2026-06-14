class PlaceModel {
  final String placeId;
  final String primaryText;
  final String secondaryText;
  final double? lat;
  final double? lng;
  final double? distanceInMeters;

  const PlaceModel({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    this.lat,
    this.lng,
    this.distanceInMeters,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      placeId: json['place_id'] ?? '',
      primaryText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
      lat: json['geometry']?['location']?['lat'],
      lng: json['geometry']?['location']?['lng'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'primary_text': primaryText,
      'secondary_text': secondaryText,
      'lat': lat,
      'lng': lng,
      'last_used_at': DateTime.now().toIso8601String(),
    };
  }

  factory PlaceModel.fromCache(Map<dynamic, dynamic> json) {
    return PlaceModel(
      placeId: json['place_id'] ?? '',
      primaryText: json['primary_text'] ?? '',
      secondaryText: json['secondary_text'] ?? '',
      lat: json['lat'],
      lng: json['lng'],
    );
  }

  PlaceModel copyWith({
    String? placeId,
    String? primaryText,
    String? secondaryText,
    double? lat,
    double? lng,
    double? distanceInMeters,
  }) {
    return PlaceModel(
      placeId: placeId ?? this.placeId,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
    );
  }
}
