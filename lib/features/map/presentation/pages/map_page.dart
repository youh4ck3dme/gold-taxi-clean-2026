import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gold_taxi/features/map/presentation/cubits/map_cubit.dart';
import 'package:gold_taxi/features/map/presentation/widgets/platform_map_widget.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_cubit.dart';
import '../../../../models/driver_position_model.dart';
import '../../../../models/service_model.dart';

/// Main Map Page with Realtime Driver Tracking
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late MapCubit _mapCubit;
  bool _isLoadingLocation = false;
  bool _hasLocationPermission = false;

  // Default position (Bratislava center)
  final LatLng _defaultPosition = const LatLng(48.1486, 17.1077);

  @override
  void initState() {
    super.initState();
    _mapCubit = context.read<MapCubit>();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS) {
      setState(() {
        _hasLocationPermission = true;
      });
      _getCurrentPosition();
      return;
    }

    final status = await Permission.locationWhenInUse.request();
    setState(() {
      _hasLocationPermission = status.isGranted;
    });

    if (status.isGranted) {
      _getCurrentPosition();
    }
  }

  Future<void> _getCurrentPosition() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        _mapCubit.updateCurrentPosition(LatLng(position.latitude, position.longitude));
        await _mapCubit.moveToCurrentPosition(LatLng(position.latitude, position.longitude));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nepodarilo sa získať polohu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa vodičov'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _getCurrentPosition(),
            tooltip: 'Obnoviť polohu',
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => _mapCubit.centerOnAllDrivers(),
            tooltip: 'Zobraziť všetkých vodičov',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().logout(),
            tooltip: 'Odhlásiť sa',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          BlocBuilder<MapCubit, MapState>(
            builder: (context, state) {
              if (state is MapError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _getCurrentPosition(),
                        child: const Text('Skúsiť znova'),
                      ),
                    ],
                  ),
                );
              }

              final currentPosition = state is MapLoaded ? state.currentPosition : null;
              final drivers = state is MapLoaded ? state.drivers : <DriverPositionModel>[];

              // Convert drivers to platform-agnostic marker data
              final platformMarkers = drivers.map((driver) {
                return MapMarkerData(
                  id: driver.driverId,
                  latitude: driver.lat,
                  longitude: driver.lng,
                  title: driver.name,
                  snippet:
                      '${driver.serviceType} • ${driver.rating}★ • ${driver.carModel}',
                  isAvailable: driver.isAvailable,
                  rotation: driver.bearing,
                  onTap: () => _mapCubit.selectDriver(driver.driverId),
                );
              }).toSet();

              final pos = currentPosition ?? _defaultPosition;

              return PlatformMapWidget(
                latitude: pos.latitude,
                longitude: pos.longitude,
                zoom: 14.0,
                markers: platformMarkers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                zoomControlsEnabled: false,
                padding: const EdgeInsets.only(bottom: 150),
                onMapCreated: (controller) {
                  if (state is! MapLoaded && controller is GoogleMapController) {
                    _mapCubit.initMap(controller);
                  }
                },
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
              );
            },
          ),

          // Current location button (floating)
          if (_hasLocationPermission) ...[
            Positioned(
              bottom: 180,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'currentLocation',
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                onPressed: _getCurrentPosition,
                child: _isLoadingLocation
                    ? const CircularProgressIndicator(color: Colors.blue)
                    : const Icon(Icons.my_location, size: 28),
              ),
            ),
          ],

          // Driver info panel (bottom)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: BlocBuilder<MapCubit, MapState>(
              builder: (context, state) {
                if (state is MapLoaded && state.selectedDriverId != null) {
                  final driver = state.drivers
                      .where((d) => d.driverId == state.selectedDriverId)
                      .firstOrNull;
                  if (driver != null) {
                    return _DriverInfoCard(driver: driver);
                  }
                }
                return _DriverListCard(drivers: state is MapLoaded ? state.drivers : []);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapCubit.close();
    super.dispose();
  }
}

/// Driver Info Card (when driver is selected)
class _DriverInfoCard extends StatelessWidget {
  final DriverPositionModel driver;

  const _DriverInfoCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 35,
              backgroundImage: NetworkImage(driver.avatar),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text('${driver.rating}'),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: driver.isAvailable
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          driver.isAvailable ? 'Dostupný' : 'Zaneprazdnený',
                          style: TextStyle(
                            color: driver.isAvailable ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${driver.serviceType} • ${driver.carModel} • ${driver.carPlate}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.call, size: 16),
                          label: const Text('Zavolať'),
                          onPressed: () => _makePhoneCall(driver.phone, context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.navigation, size: 16),
                          label: const Text('Objednať'),
                          onPressed: () => _bookDriver(driver, context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phone, BuildContext context) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefónne číslo nie je k dispozícii')),
      );
      return;
    }
    // Normalize: strip spaces so 'tel:' URI is valid
    final normalized = phone.replaceAll(' ', '');
    final uri = Uri(scheme: 'tel', path: normalized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nepodarilo sa vytočiť číslo $phone')),
        );
      }
    }
  }

  void _bookDriver(DriverPositionModel driver, BuildContext context) {
    // Build a ServiceModel from the selected driver and push to /booking
    final service = ServiceModel(
      id: driver.driverId.hashCode.abs(),
      name: '${driver.serviceType} – ${driver.name}',
      description:
          '${driver.carModel} (${driver.carPlate}) · Hodnotenie: ${driver.rating}★\n'
          'Tel: ${driver.phone.isNotEmpty ? driver.phone : "N/A"}',
      price: 0.0, // actual price calculated by backend
      category: driver.serviceType,
      provider: driver.name,
      images: [driver.avatar],
      rating: driver.rating,
    );
    context.push('/booking', extra: service);
  }
}

/// Driver List Card (when no driver selected)
class _DriverListCard extends StatelessWidget {
  final List<DriverPositionModel> drivers;

  const _DriverListCard({required this.drivers});

  @override
  Widget build(BuildContext context) {
    final availableDrivers = drivers.where((d) => d.isAvailable).toList();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dostupní vodiči',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${availableDrivers.length}/${drivers.length}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (drivers.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Žiadni vodiči v okruhu'),
                ),
              ),
            ] else ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = availableDrivers[index];
                    return GestureDetector(
                      onTap: () => context.read<MapCubit>().selectDriver(driver.driverId),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 100,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(driver.avatar),
                              backgroundColor: Colors.grey[200],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              driver.name.split(' ').first,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${driver.rating}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
