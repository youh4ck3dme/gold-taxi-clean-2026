import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:gold_taxi/core/utils/math_utils.dart';
import 'google_maps_loader_stub.dart'
    if (dart.library.js) 'google_maps_loader_web.dart'
    if (dart.library.io) 'google_maps_loader_mobile.dart';

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

class _PlatformMapWidgetState extends State<PlatformMapWidget> {
  bool _googleMapsReady = false;
  gmaps.BitmapDescriptor? _carIcon;
  gmaps.GoogleMapController? _mapController;
  
  late ClusterManager<MapMarkerData> _clusterManager;
  Set<gmaps.Marker> _gmapMarkers = {};

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

    _clusterManager = ClusterManager<MapMarkerData>(
      widget.markers,
      _updateGoogleMarkers,
      markerBuilder: _markerBuilder,
      levels: const [1, 4.25, 6.75, 8.25, 11.5, 14.5, 16.0, 16.5, 20.0],
    );

    _loadCustomCarIcon();
  }

  void _updateGoogleMarkers(Set<gmaps.Marker> markers) {
    if (mounted) {
      setState(() {
        _gmapMarkers = markers;
      });
    }
  }

  Future<void> _loadCustomCarIcon() async {
    try {
      if (kIsWeb) {
        _carIcon = null;
      } else {
        _carIcon = await gmaps.BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/images/car_top_view.png',
        );
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to load custom car icon: $e');
      _carIcon = null;
    }
  }

  @override
  void didUpdateWidget(PlatformMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.markers != oldWidget.markers) {
      _clusterManager.setItems(widget.markers.toList());
      
      // Auto-tracking logic if needed
      if (widget.isAutoTracking && widget.autoTrackMarkerId != null && _mapController != null) {
        try {
          final target = widget.markers.firstWhere((m) => m.id == widget.autoTrackMarkerId);
          _mapController!.animateCamera(
            gmaps.CameraUpdate.newLatLng(gmaps.LatLng(target.latitude, target.longitude)),
          );
        } catch (_) {}
      }
    }
  }

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

  gmaps.BitmapDescriptor _getTaxiIcon(bool isAvailable) {
    return gmaps.BitmapDescriptor.defaultMarkerWithHue(
      isAvailable ? gmaps.BitmapDescriptor.hueGreen : gmaps.BitmapDescriptor.hueRed,
    );
  }

  Future<gmaps.Marker> _markerBuilder(Cluster<MapMarkerData> cluster) async {
    return gmaps.Marker(
      markerId: gmaps.MarkerId(cluster.getId()),
      position: cluster.location,
      onTap: () {
        if (cluster.isMultiple) {
          _mapController?.animateCamera(gmaps.CameraUpdate.newLatLngZoom(cluster.location, 14));
        } else {
          cluster.items.first.onTap?.call();
        }
      },
      icon: cluster.isMultiple 
        ? await _getClusterBitmap(cluster.count.toString())
        : (_carIcon ?? _getTaxiIcon(cluster.items.first.isAvailable)),
      rotation: cluster.isMultiple ? 0.0 : cluster.items.first.rotation,
      infoWindow: cluster.isMultiple 
        ? gmaps.InfoWindow.noText 
        : gmaps.InfoWindow(
            title: cluster.items.first.title,
            snippet: cluster.items.first.snippet,
          ),
    );
  }
  
  Future<gmaps.BitmapDescriptor> _getClusterBitmap(String text) async {
    // Basic fallback to default hue for cluster if custom painter is not implemented yet
    return gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure);
  }

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

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(widget.latitude, widget.longitude),
        zoom: widget.zoom,
      ),
      markers: _gmapMarkers,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      compassEnabled: widget.compassEnabled,
      zoomControlsEnabled: widget.zoomControlsEnabled,
      padding: widget.padding,
      onMapCreated: (controller) {
        _mapController = controller;
        _clusterManager.setMapId(controller.mapId);
        widget.onMapCreated?.call(controller);
      },
      onCameraMove: _clusterManager.onCameraMove,
      onCameraIdle: _clusterManager.updateMap,
      gestureRecognizers: widget.gestureRecognizers ?? {},
    );
  }

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
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 45,
            size: const Size(40, 40),
            markers: fMarkers,
            builder: (context, markers) {
              return Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: Colors.blue,
                ),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MapMarkerData with ClusterItem {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String? snippet;
  final bool isAvailable;
  final double rotation;
  final VoidCallback? onTap;

  MapMarkerData({
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
  gmaps.LatLng get location => gmaps.LatLng(latitude, longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapMarkerData &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
