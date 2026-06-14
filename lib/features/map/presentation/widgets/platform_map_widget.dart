import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:gold_taxi/core/utils/math_utils.dart';
import 'google_maps_loader_stub.dart'
    if (dart.library.js) 'google_maps_loader_web.dart'
    if (dart.library.io) 'google_maps_loader_mobile.dart';

/// A platform-adaptive map widget.
///
/// Uses Google Maps on Web, Android, and iOS when a platform key is configured.
/// Falls back to flutter_map (OpenStreetMap) on macOS (and any other platform
/// where google_maps_flutter is not supported).
class PlatformMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final Set<MapMarkerData> markers;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool compassEnabled;
  final bool zoomControlsEnabled;
  final EdgeInsets padding;
  final String? autoTrackMarkerId;
  final bool isAutoTracking;
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
    this.autoTrackMarkerId,
    this.isAutoTracking = false,
    this.onMapCreated,
    this.gestureRecognizers,
  });

  @override
  State<PlatformMapWidget> createState() => _PlatformMapWidgetState();
}

class _PlatformMapWidgetState extends State<PlatformMapWidget> with TickerProviderStateMixin {
  bool _googleMapsReady = false;
  late AnimationController _animationController;
  final Map<String, _MarkerAnimationData> _animatedMarkers = {};
  gmaps.BitmapDescriptor? _carIcon;
  gmaps.GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _googleMapsReady = _useGoogleMaps && isGoogleMapsInitialized();
    if (_useGoogleMaps && !_googleMapsReady) {
      ensureGoogleMapsInitialized().then((ready) {
        if (mounted) {
          setState(() => _googleMapsReady = ready);
        }
      });
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _initAnimatedMarkers(widget.markers);
    _loadCustomCarIcon();
  }

  Future<void> _loadCustomCarIcon() async {
    try {
      if (kIsWeb) {
        _carIcon = gmaps.BitmapDescriptor.defaultMarker;
      } else {
        _carIcon = await gmaps.BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/images/car_top_view.png',
        );
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to load custom car icon: $e');
      _carIcon = gmaps.BitmapDescriptor.defaultMarker;
    }
  }

  void _initAnimatedMarkers(Set<MapMarkerData> markers) {
    for (final marker in markers) {
      _animatedMarkers[marker.id] = _MarkerAnimationData(
        startLat: marker.latitude,
        startLng: marker.longitude,
        endLat: marker.latitude,
        endLng: marker.longitude,
        startRotation: marker.rotation,
        endRotation: marker.rotation,
        title: marker.title,
        snippet: marker.snippet,
        isAvailable: marker.isAvailable,
        onTap: marker.onTap,
      );
    }
  }

  @override
  void didUpdateWidget(PlatformMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    bool needsAnimation = false;

    // Remove stale markers
    final incomingIds = widget.markers.map((m) => m.id).toSet();
    _animatedMarkers.removeWhere((key, value) => !incomingIds.contains(key));

    for (final marker in widget.markers) {
      final existing = _animatedMarkers[marker.id];
      if (existing != null) {
        // Did it move?
        if (existing.endLat != marker.latitude || existing.endLng != marker.longitude) {
          // It moved. Set start to current interpolated position
          double currentLat = existing.startLat + (existing.endLat - existing.startLat) * _animationController.value;
          double currentLng = existing.startLng + (existing.endLng - existing.startLng) * _animationController.value;
          
          double currentRotation = existing.startRotation + MathUtils.shortestAngle(existing.startRotation, existing.endRotation) * _animationController.value;

          // Calculate new heading (rotation) based on movement direction if the backend didn't provide one
          double newRotation = marker.rotation;
          // Note: Geolocator.bearingBetween could be used here if needed, but we assume backend sends rotation

          _animatedMarkers[marker.id] = existing.copyWith(
            startLat: currentLat,
            startLng: currentLng,
            endLat: marker.latitude,
            endLng: marker.longitude,
            startRotation: currentRotation,
            endRotation: newRotation,
            title: marker.title,
            snippet: marker.snippet,
            isAvailable: marker.isAvailable,
            onTap: marker.onTap,
          );
          needsAnimation = true;
        } else {
          // Just update info
          _animatedMarkers[marker.id] = existing.copyWith(
            title: marker.title,
            snippet: marker.snippet,
            isAvailable: marker.isAvailable,
            onTap: marker.onTap,
          );
        }
      } else {
        // New marker
        _animatedMarkers[marker.id] = _MarkerAnimationData(
          startLat: marker.latitude,
          startLng: marker.longitude,
          endLat: marker.latitude,
          endLng: marker.longitude,
          startRotation: marker.rotation,
          endRotation: marker.rotation,
          title: marker.title,
          snippet: marker.snippet,
          isAvailable: marker.isAvailable,
          onTap: marker.onTap,
        );
      }
    }

    if (needsAnimation) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  /// Get taxi icon for Google Maps based on availability status
  gmaps.BitmapDescriptor _getTaxiIcon(bool isAvailable) {
    if (kIsWeb) {
      return gmaps.BitmapDescriptor.defaultMarker;
    }
    return gmaps.BitmapDescriptor.defaultMarkerWithHue(
      isAvailable ? gmaps.BitmapDescriptor.hueOrange : gmaps.BitmapDescriptor.hueViolet,
    );
  }

  /// Build taxi marker icon for flutter_map
  Widget _buildTaxiMarkerIcon(bool isAvailable) {
    return Container(
      decoration: BoxDecoration(
        color: isAvailable ? Colors.orange : Colors.grey,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(4),
      child: const Icon(
        Icons.local_taxi,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_useGoogleMaps && _googleMapsReady) {
      return _buildGoogleMap();
    }
    return _buildFlutterMap();
  }

  /// Google Maps implementation (Web, Android, iOS)
  Widget _buildGoogleMap() {
    final t = _animationController.value;
    
    final gMarkers = _animatedMarkers.entries.map((entry) {
      final id = entry.key;
      final data = entry.value;
      
      final currentLat = data.startLat + (data.endLat - data.startLat) * t;
      final currentLng = data.startLng + (data.endLng - data.startLng) * t;
      final currentRotation = data.startRotation + MathUtils.shortestAngle(data.startRotation, data.endRotation) * t;

      if (widget.isAutoTracking && widget.autoTrackMarkerId == id && _mapController != null) {
        _mapController!.moveCamera(
          gmaps.CameraUpdate.newLatLng(gmaps.LatLng(currentLat, currentLng)),
        );
      }

      return gmaps.Marker(
        markerId: gmaps.MarkerId(id),
        position: gmaps.LatLng(currentLat, currentLng),
        infoWindow: gmaps.InfoWindow(
          title: data.title,
          snippet: data.snippet,
        ),
        icon: _carIcon ?? _getTaxiIcon(data.isAvailable),
        rotation: currentRotation,
        onTap: data.onTap,
      );
    }).toSet();

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(widget.latitude, widget.longitude),
        zoom: widget.zoom,
      ),
      markers: gMarkers,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      compassEnabled: widget.compassEnabled,
      zoomControlsEnabled: widget.zoomControlsEnabled,
      padding: widget.padding,
      onMapCreated: (controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
      },
      gestureRecognizers: widget.gestureRecognizers ?? {},
    );
  }

  /// Flutter Map (OpenStreetMap) implementation (macOS fallback)
  Widget _buildFlutterMap() {
    final fMarkers = widget.markers.map((m) {
      return Marker(
        point: ll.LatLng(m.latitude, m.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: m.onTap,
          child: Tooltip(
            message: '${m.title}\n${m.snippet ?? ''}',
            child: _buildTaxiMarkerIcon(m.isAvailable),
          ),
        ),
      );
    }).toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: ll.LatLng(widget.latitude, widget.longitude),
        initialZoom: widget.zoom,
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

class _MarkerAnimationData {
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double startRotation;
  final double endRotation;
  final String title;
  final String? snippet;
  final bool isAvailable;
  final VoidCallback? onTap;

  _MarkerAnimationData({
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.startRotation,
    required this.endRotation,
    required this.title,
    this.snippet,
    required this.isAvailable,
    this.onTap,
  });

  _MarkerAnimationData copyWith({
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    double? startRotation,
    double? endRotation,
    String? title,
    String? snippet,
    bool? isAvailable,
    VoidCallback? onTap,
  }) {
    return _MarkerAnimationData(
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      startRotation: startRotation ?? this.startRotation,
      endRotation: endRotation ?? this.endRotation,
      title: title ?? this.title,
      snippet: snippet ?? this.snippet,
      isAvailable: isAvailable ?? this.isAvailable,
      onTap: onTap ?? this.onTap,
    );
  }
}
