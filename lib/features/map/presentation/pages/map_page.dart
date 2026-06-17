// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gold_taxi/features/map/presentation/cubits/map_cubit.dart';
import 'package:gold_taxi/features/map/presentation/widgets/platform_map_widget.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:gold_taxi/features/search/presentation/widgets/search_bottom_sheet.dart';
import '../../../../core/constants/app_colors.dart';
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

  // Default position: Centrum Košice (instead of Bratislava)
  final LatLng _defaultPosition = const LatLng(48.7219, 21.2575);

  @override
  void initState() {
    super.initState();
    _mapCubit = context.read<MapCubit>();

    // Set initial position to default immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapCubit.updateCurrentPosition(_defaultPosition);
    });

    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission;

    // Test if location services are enabled.
    await Geolocator.isLocationServiceEnabled();

    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS) {
      // On Web/macOS, we proceed but handle potential failure in _getCurrentPosition
      setState(() {
        _hasLocationPermission = true;
      });
      _getCurrentPosition();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _hasLocationPermission = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _hasLocationPermission = false);
      return;
    }

    setState(() {
      _hasLocationPermission = true;
    });
    _getCurrentPosition();
  }

  Future<void> _getCurrentPosition() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      if (mounted) {
        _mapCubit.updateCurrentPosition(LatLng(position.latitude, position.longitude));
        await _mapCubit.moveToCurrentPosition(LatLng(position.latitude, position.longitude));
      }
    } catch (e) {
      debugPrint('Geolocation error: $e');
      if (mounted) {
        // Non-blocking warning: fallback to default Košice
        _mapCubit.updateCurrentPosition(_defaultPosition);

        // Show a more friendly message for common web/macOS location issues
        String message = 'Nepodarilo sa získať presnú polohu. Používam predvolenú (Košice).';
        if (e.toString().contains('kCLErrorLocationUnknown') || e.toString().contains('User denied')) {
          message = 'Prístup k polohe je obmedzený. Používam predvolenú polohu v Košiciach.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
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
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.luxuryGold),
            onPressed: () => _getCurrentPosition(),
            tooltip: 'Obnoviť polohu',
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_rounded, color: AppColors.luxuryGold),
            onPressed: () => _mapCubit.centerOnAllDrivers(),
            tooltip: 'Zobraziť všetkých vodičov',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white24),
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
                  snippet: '${driver.carModel} • ${driver.carPlate}',
                  isAvailable: driver.isAvailable,
                  rotation: driver.bearing,
                  onTap: () {
                    if (!driver.isAvailable) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vodič je momentálne offline.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      _mapCubit.selectDriver(driver.driverId);
                    }
                  },
                );
              }).toSet();

              final pos = currentPosition ?? _defaultPosition;
              final isTracking = state is MapLoaded ? state.isTracking : false;
              final selectedDriverId = state is MapLoaded ? state.selectedDriverId : null;

              return PlatformMapWidget(
                latitude: pos.latitude,
                longitude: pos.longitude,
                zoom: 14.0,
                markers: platformMarkers,
                isAutoTracking: isTracking,
                autoTrackMarkerId: selectedDriverId,
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

          // Search Bar Overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () async {
                final currentPos = context.read<MapCubit>().state is MapLoaded
                    ? (context.read<MapCubit>().state as MapLoaded).currentPosition
                    : null;

                final selectedPlace = await SearchBottomSheet.show(
                  context,
                  currentLocation: currentPos ?? _defaultPosition,
                );

                if (!mounted) return;

                if (selectedPlace != null && selectedPlace.lat != null && selectedPlace.lng != null) {
                  // Move map to selected place
                  _mapCubit.moveToCurrentPosition(LatLng(selectedPlace.lat!, selectedPlace.lng!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vybraté: ${selectedPlace.primaryText}')),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.luxuryGold.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.luxuryGold, size: 24),
                    const SizedBox(width: 16),
                    const Text(
                      'Kam to bude?',
                      style: TextStyle(
                        color: Color(0xFFB8BEC9), 
                        fontSize: 18, 
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Current location button (floating)
          if (_hasLocationPermission) ...[
            Positioned(
              bottom: 180,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'currentLocation',
                backgroundColor: const Color(0xFF111111),
                foregroundColor: AppColors.luxuryGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.luxuryGold.withOpacity(0.3)),
                ),
                onPressed: _getCurrentPosition,
                child: _isLoadingLocation
                    ? const CircularProgressIndicator(color: AppColors.luxuryGold)
                    : const Icon(Icons.my_location_rounded, size: 24),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.luxuryGold.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.luxuryGold, Color(0xFFFFD700)]),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: AppColors.deepBlack,
              foregroundImage: (driver.avatar.isNotEmpty)
                  ? NetworkImage(driver.avatar)
                  : null,
              onForegroundImageError: (driver.avatar.isNotEmpty)
                  ? (exception, stackTrace) {
                      debugPrint('Error loading map driver card avatar: $exception');
                    }
                  : null,
              child: const Icon(Icons.person, size: 35, color: AppColors.luxuryGold),
            ),
          ),
          const SizedBox(width: 20),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  driver.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.luxuryGold, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${driver.rating}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: driver.isAvailable
                            ? Colors.greenAccent.withOpacity(0.1)
                            : Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: driver.isAvailable ? Colors.greenAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        driver.isAvailable ? 'AVAILABLE' : 'BUSY',
                        style: TextStyle(
                          color: driver.isAvailable ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${driver.serviceType.toUpperCase()} • ${driver.carModel}',
                  style: const TextStyle(
                    color: Color(0xFFB8BEC9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('CALL'),
                        onPressed: () => _makePhoneCall(driver.phone, context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: const Text('BOOK'),
                        onPressed: driver.isAvailable
                            ? () => _bookDriver(driver, context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppColors.luxuryGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

class _DriverListCard extends StatelessWidget {
  final List<DriverPositionModel> drivers;

  const _DriverListCard({required this.drivers});

  @override
  Widget build(BuildContext context) {
    final availableDrivers = drivers.where((d) => d.isAvailable).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.luxuryGold.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PREMIUM VODIČI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.luxuryGold,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.luxuryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${availableDrivers.length} ONLINE',
                  style: const TextStyle(
                    color: AppColors.luxuryGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (drivers.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('VYHĽADÁVAME VODIČOV...', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  final isOnline = driver.isAvailable;
                  return GestureDetector(
                    onTap: () {
                      if (isOnline) {
                        context.read<MapCubit>().selectDriver(driver.driverId);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      width: 85,
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isOnline ? AppColors.luxuryGold.withOpacity(0.5) : Colors.white10,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  foregroundImage: (driver.avatar.isNotEmpty)
                                      ? NetworkImage(driver.avatar)
                                      : null,
                                  child: const Icon(Icons.person, size: 28, color: Colors.white12),
                                ),
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF111111), width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            driver.name.split(' ').first.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isOnline ? Colors.white : Colors.white24,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    );
  }
}
