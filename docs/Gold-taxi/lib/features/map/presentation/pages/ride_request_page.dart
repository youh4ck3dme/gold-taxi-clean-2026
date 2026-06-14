import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/mock_geocoding_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../widgets/platform_map_widget.dart';
import '../cubits/ride_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';

class RideRequestPage extends StatefulWidget {
  final LocationModel destination;

  const RideRequestPage({super.key, required this.destination});

  @override
  State<RideRequestPage> createState() => _RideRequestPageState();
}

class _RideRequestPageState extends State<RideRequestPage> {
  ServiceType _selectedType = ServiceType.standard;
  
  // Mock current position: Centrum Košice
  final LatLng _pickup = const LatLng(48.7219, 21.2575);

  @override
  Widget build(BuildContext context) {
    const distance = 3.5; // Mock distance for demo
    final estimate = PricingService.calculateEstimate(
      distanceInKm: distance,
      type: _selectedType,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Potvrdenie jazdy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Map Background
          PlatformMapWidget(
            latitude: (_pickup.latitude + widget.destination.position.latitude) / 2,
            longitude: (_pickup.longitude + widget.destination.position.longitude) / 2,
            zoom: 13.0,
            markers: {
              MapMarkerData(
                id: 'pickup',
                latitude: _pickup.latitude,
                longitude: _pickup.longitude,
                title: 'Moja poloha',
                isAvailable: true,
              ),
              MapMarkerData(
                id: 'destination',
                latitude: widget.destination.position.latitude,
                longitude: widget.destination.position.longitude,
                title: widget.destination.name,
                isAvailable: true,
              ),
            },
          ),

          // Selection Bottom Sheet
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
                  // Service Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTypeOption(ServiceType.standard, 'Standard', Icons.directions_car),
                      _buildTypeOption(ServiceType.comfort, 'Comfort', Icons.weekend),
                      _buildTypeOption(ServiceType.premium, 'Premium', Icons.star),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Odhadovaná cena',
                        style: TextStyle(fontSize: 16, color: AppColors.grey600),
                      ),
                      Text(
                        '${estimate.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  PrimaryButton(
                    text: 'Potvrdiť jazdu',
                    onPressed: () {
                      final authState = context.read<AuthCubit>().state;
                      String customerId = 'guest_user';
                      if (authState is Authenticated) {
                        customerId = authState.user.id.toString();
                      }

                      context.read<RideCubit>().requestRide(
                        customerId: customerId,
                        pickupAddress: 'Moja poloha (Centrum)',
                        pickupLatLng: _pickup,
                        dropoffAddress: widget.destination.name,
                        dropoffLatLng: widget.destination.position,
                        serviceType: _selectedType,
                        distance: distance,
                        estimate: estimate,
                      );
                      
                      // Navigate to active ride tracking
                      context.push('/active-ride');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(ServiceType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondary : AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.grey600,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.secondary : AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}
