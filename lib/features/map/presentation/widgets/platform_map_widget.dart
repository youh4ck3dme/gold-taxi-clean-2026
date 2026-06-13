import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'google_maps_loader_stub.dart'
    if (dart.library.js) 'google_maps_loader_web.dart'
    if (dart.library.io) 'google_maps_loader_mobile.dart';

/// A platform-adaptive map widget.
///
/// Uses Google Maps on Web and iOS (where the native plugin is available).
/// Falls back to flutter_map (OpenStreetMap) on macOS (and any other platform
/// where google_maps_flutter is not supported).
class PlatformMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final Set<MapMarkerData> markers;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool compassEnabled;
  final bool zoomControlsEnabled;
  final EdgeInsets padding;
  final void Function(dynamic controller)? onMapCreated;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  const PlatformMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoom = 14.0,
    this.markers = const {},
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = true,
    this.compassEnabled = true,
    this.zoomControlsEnabled = false,
    this.padding = EdgeInsets.zero,
    this.onMapCreated,
    this.gestureRecognizers,
  });

  /// Check if Google Maps is supported on this platform.
  static bool get _useGoogleMaps {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_useGoogleMaps && isGoogleMapsInitialized()) {
      return _buildGoogleMap();
    }
    return _buildFlutterMap();
  }

  /// Google Maps implementation (Web, iOS)
  Widget _buildGoogleMap() {
    final gMarkers = markers.map((m) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(m.id),
        position: gmaps.LatLng(m.latitude, m.longitude),
        infoWindow: gmaps.InfoWindow(
          title: m.title,
          snippet: m.snippet,
        ),
        icon: m.isAvailable
            ? gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueGreen)
            : gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueRed),
        rotation: m.rotation,
        onTap: m.onTap,
      );
    }).toSet();

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(latitude, longitude),
        zoom: zoom,
      ),
      markers: gMarkers,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      compassEnabled: compassEnabled,
      zoomControlsEnabled: zoomControlsEnabled,
      padding: padding,
      onMapCreated: (controller) => onMapCreated?.call(controller),
      gestureRecognizers: gestureRecognizers ?? {},
    );
  }

  /// Flutter Map (OpenStreetMap) implementation (macOS fallback)
  Widget _buildFlutterMap() {
    final fMarkers = markers.map((m) {
      return Marker(
        point: ll.LatLng(m.latitude, m.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: m.onTap,
          child: Tooltip(
            message: '${m.title}\n${m.snippet ?? ''}',
            child: Icon(
              Icons.location_on,
              color: m.isAvailable ? Colors.green : Colors.red,
              size: 40,
            ),
          ),
        ),
      );
    }).toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: ll.LatLng(latitude, longitude),
        initialZoom: zoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.goldtaxi.app',
        ),
        MarkerLayer(markers: fMarkers),
      ],
    );
  }
}

/// Platform-agnostic marker data shared between Google Maps and flutter_map.
class MapMarkerData {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String? snippet;
  final bool isAvailable;
  final double rotation;
  final VoidCallback? onTap;

  const MapMarkerData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.snippet,
    this.isAvailable = true,
    this.rotation = 0.0,
    this.onTap,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapMarkerData &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
