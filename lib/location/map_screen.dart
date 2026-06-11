import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_state.dart';
import 'bloc/driver_location_bloc.dart';
import 'bloc/driver_location_event.dart';
import 'bloc/driver_location_state.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  static const LatLng _bratislavaCenter = LatLng(48.1485, 17.1077);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final role = authState.userProfile.role;
        if (role == 'customer') {
          context.read<DriverLocationBloc>().add(StartListeningToOnlineDrivers());
        } else if (role == 'driver') {
          context.read<DriverLocationBloc>().add(InitializeDriverState(authState.userProfile.id));
        }
      }
    });
  }

  @override
  void dispose() {
    context.read<DriverLocationBloc>().add(StopListeningToOnlineDrivers());
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _centerOnPosition(Position pos) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(pos.latitude, pos.longitude),
        15.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final userProfile = authState.userProfile;
    final isDriver = userProfile.role == 'driver';

    return BlocBuilder<DriverLocationBloc, DriverLocationState>(
      builder: (context, state) {
        // Build markers list
        final Set<Marker> markers = {};

        if (isDriver) {
          if (state.currentPosition != null) {
            final pos = state.currentPosition!;
            markers.add(
              Marker(
                markerId: const MarkerId('driver_self'),
                position: LatLng(pos.latitude, pos.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                infoWindow: const InfoWindow(title: 'Vaša poloha'),
              ),
            );
          }
        } else {
          // Customer: show all online drivers
          for (final driver in state.onlineDrivers) {
            markers.add(
              Marker(
                markerId: MarkerId(driver.id),
                position: LatLng(driver.latitude, driver.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow), // Yellow color for Gold Taxi
                infoWindow: InfoWindow(
                  title: driver.fullName.isNotEmpty ? driver.fullName : 'Vodič Gold Taxi',
                  snippet: 'Aktívny',
                ),
              ),
            );
          }
        }

        // Determine initial camera target
        LatLng initialTarget = _bratislavaCenter;
        if (isDriver && state.currentPosition != null) {
          initialTarget = LatLng(
            state.currentPosition!.latitude,
            state.currentPosition!.longitude,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(isDriver ? 'Sledovanie polohy - Vodič' : 'Dostupní vodiči v okolí'),
            actions: [
              IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: () {
                  if (isDriver && state.currentPosition != null) {
                    _centerOnPosition(state.currentPosition!);
                  } else if (!isDriver && state.onlineDrivers.isNotEmpty) {
                    final firstDriver = state.onlineDrivers.first;
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(firstDriver.latitude, firstDriver.longitude),
                        14.0,
                      ),
                    );
                  }
                },
              )
            ],
          ),
          body: Stack(
            children: [
              // Google Map Widget
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: 12.0,
                ),
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                markers: markers,
              ),

              // Error Overlay (if any)
              if (state.errorMessage != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.red[900],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Bottom Control Card for DRIVER
              if (isDriver)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          border: Border.all(color: Colors.white24, width: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: state.isOnline ? Colors.green : Colors.red,
                                    boxShadow: [
                                      BoxShadow(
                                        color: state.isOnline ? Colors.green : Colors.red,
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  state.isOnline 
                                      ? 'Ste ONLINE a viditeľný' 
                                      : 'Ste OFFLINE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.isOnline
                                  ? 'Vaša GPS poloha sa odosiela priebežne na pozadí.'
                                  : 'Prejdite do stavu online, aby ste sa zobrazili na mape zákazníkov.',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: state.isOnline 
                                      ? Colors.red[700] 
                                      : Colors.yellow[700],
                                  foregroundColor: state.isOnline 
                                      ? Colors.white 
                                      : Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: () => context.read<DriverLocationBloc>().add(ToggleOnline(userProfile.id)),
                                child: Text(
                                  state.isOnline 
                                      ? 'Odhlásiť sa (OFFLINE)' 
                                      : 'Prihlásiť sa (ONLINE)',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Bottom Info Card for CUSTOMER
              if (!isDriver)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          border: Border.all(color: Colors.white24, width: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Dostupnosť taxíkov',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${state.onlineDrivers.length} aktívnych vodičov',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.local_taxi,
                              color: Colors.yellow[700],
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
