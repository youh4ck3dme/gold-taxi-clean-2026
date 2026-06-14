import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/ride_status.dart';
import '../cubits/ride_cubit.dart';
import '../widgets/platform_map_widget.dart';

class ActiveRidePage extends StatefulWidget {
  const ActiveRidePage({super.key});

  @override
  State<ActiveRidePage> createState() => _ActiveRidePageState();
}

class _ActiveRidePageState extends State<ActiveRidePage> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RideCubit, RideState>(
      listener: (context, state) {
        if (state.status == RideStatus.completed) {
          _showCompletionDialog();
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              // Live Map
              PlatformMapWidget(
                latitude: state.driver?.lat ?? 48.7219,
                longitude: state.driver?.lng ?? 21.2575,
                zoom: 15.0,
                markers: state.driver != null
                    ? {
                        MapMarkerData(
                          id: 'driver',
                          latitude: state.driver!.lat,
                          longitude: state.driver!.lng,
                          title: state.driver!.name,
                          rotation: state.driver!.bearing,
                          isAvailable: false,
                        )
                      }
                    : {},
              ),

              // Top Status Indicator
              Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        state.status.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Info Panel
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.driver != null) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(state.driver!.avatar),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.driver!.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${state.driver!.carModel} • ${state.driver!.carPlate}',
                                    style: const TextStyle(color: AppColors.grey600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                context.push('/chat', extra: {
                                  'rideId': state.currentRide?.id ?? '',
                                  'driverId': state.driver?.driverId ?? '',
                                  'driverName': state.driver?.name ?? 'Vodič',
                                });
                              },
                              icon: const Icon(Icons.chat, color: Colors.green),
                            ),
                            IconButton(
                              onPressed: () {}, // Mock call
                              icon: const Icon(Icons.call, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (state.status.canCancel)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              context.read<RideCubit>().cancelRide();
                              context.pop();
                            },
                            child: const Text(
                              'Zrušiť jazdu',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cieľ dosiahnutý!'),
        content: const Text('Dúfame, že ste mali príjemnú jazdu. Vaša platba bude spracovaná automaticky.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // pop dialog
              context.go('/'); // go home
            },
            child: const Text('Späť domov'),
          ),
        ],
      ),
    );
  }
}
