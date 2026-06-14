import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/mock_geocoding_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../widgets/platform_map_widget.dart';
import '../widgets/multi_stop_timeline.dart';
import '../widgets/animated_price_text.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideCubit>().checkZoneAndSurge(_pickup);
    });
  }

  @override
  Widget build(BuildContext context) {
    const distance = 3.5; // Mock distance for demo

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
              child: BlocBuilder<RideCubit, RideState>(
                builder: (context, state) {
                  final baseEstimate = PricingService.calculateEstimate(
                    distanceInKm: distance,
                    type: _selectedType,
                  );
                  double waitingFee = 0.0;
                  for (final stop in state.intermediateStops) {
                    if (stop.isWaitingEnabled) {
                      waitingFee += stop.waitingMinutes * 0.30;
                    }
                  }
                  final estimate = (baseEstimate * state.surgeMultiplier) + waitingFee;

                  return SingleChildScrollView(
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
                      const SizedBox(height: 20),

                      // Multi Stop Timeline
                      MultiStopTimeline(
                        pickupAddress: 'Moja poloha (Centrum)',
                        dropoffAddress: widget.destination.name,
                      ),
                      const SizedBox(height: 12),

                      // Zone Checking Status
                      if (state.isCheckingZone)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                              ),
                              SizedBox(width: 10),
                              Text('Overujem zónu a ceny...', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),

                      // Not in zone warning
                      if (!state.isCheckingZone && !state.isInZone)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.errorMessage ?? 'V tejto oblasti zatiaľ nejazdíme',
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Surge Pricing Warning
                      if (!state.isCheckingZone && state.isInZone && state.surgeMultiplier > 1.0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flash_on, color: Colors.amber),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Zvýšený dopyt (násobič ${state.surgeMultiplier.toStringAsFixed(1)}x)',
                                  style: TextStyle(
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Promo Code Section
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_offer_outlined, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  state.appliedPromo != null
                                      ? 'Kód: ${state.appliedPromo!.code}'
                                      : 'Promo kód',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (state.appliedPromo != null)
                              Row(
                                children: [
                                  Text(
                                    '-${state.appliedPromo!.calculatedDiscount.toStringAsFixed(2)} €',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () {
                                      context.read<RideCubit>().removePromoCode();
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              )
                            else
                              TextButton(
                                onPressed: () => _showPromoDialog(context, estimate),
                                child: const Text('Zadať kód'),
                              ),
                          ],
                        ),
                      ),
                      if (state.promoError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            state.promoError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Odhadovaná cena',
                            style: TextStyle(fontSize: 16, color: AppColors.grey600),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (state.appliedPromo != null)
                                Text(
                                  '${estimate.toStringAsFixed(2)} €',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              AnimatedPriceText(
                                value: (estimate - (state.appliedPromo?.calculatedDiscount ?? 0.0)).clamp(0.0, double.infinity),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      PrimaryButton(
                        text: 'Potvrdiť jazdu',
                        onPressed: (state.isCheckingZone || !state.isInZone)
                            ? null
                            : () {
                                final authState = context.read<AuthCubit>().state;
                                String customerId = 'guest_user';
                                if (authState is Authenticated) {
                                  customerId = authState.user.id.toString();
                                }

                                final finalEstimate = (estimate - (state.appliedPromo?.calculatedDiscount ?? 0.0)).clamp(0.0, double.infinity);

                                context.read<RideCubit>().requestRide(
                                  customerId: customerId,
                                  pickupAddress: 'Moja poloha (Centrum)',
                                  pickupLatLng: _pickup,
                                  dropoffAddress: widget.destination.name,
                                  dropoffLatLng: widget.destination.position,
                                  serviceType: _selectedType,
                                  distance: distance,
                                  estimate: finalEstimate,
                                );
                                
                                // Navigate to active ride tracking
                                context.push('/active-ride');
                              },
                      ),
                    ],
                  ),
                );
                },
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

  void _showPromoDialog(BuildContext context, double rideAmount) {
    final controller = TextEditingController();
    final cubit = context.read<RideCubit>();
    final authState = context.read<AuthCubit>().state;
    final userId = authState is Authenticated ? authState.user.id.toString() : 'guest';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Zadať promo kód'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Kód',
              hintText: 'Napr. ZNAK10',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Zrušiť'),
            ),
            ElevatedButton(
              onPressed: () {
                final code = controller.text.trim();
                if (code.isNotEmpty) {
                  cubit.validateAndApplyPromo(code, userId, rideAmount);
                }
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Použiť'),
            ),
          ],
        );
      },
    );
  }
}
