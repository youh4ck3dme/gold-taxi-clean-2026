import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../profile/presentation/bloc/profile_cubit.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../map/presentation/cubits/ride_cubit.dart';
import '../../../../core/services/mock_geocoding_service.dart';
import '../../../../models/ride_status.dart';

class CustomerHomeView extends StatelessWidget {
  final String userName;
  final String? avatarUrl;

  const CustomerHomeView({super.key, required this.userName, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        bool showPhoneWarning = false;
        Map<String, dynamic> savedAddresses = {};

        if (profileState is ProfileLoaded) {
          showPhoneWarning =
              profileState.user.phone == null ||
              profileState.user.phone!.trim().isEmpty;
          savedAddresses = profileState.user.savedAddresses;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: User Profile & Greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahoj, $userName 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kam sa dnes chystáš?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFB8BEC9),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.luxuryGold, Color(0xFFFFD700)],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.deepBlack,
                      foregroundImage:
                          (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                          ? NetworkImage(avatarUrl!)
                          : null,
                      onForegroundImageError:
                          (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                          ? (exception, stackTrace) {
                              debugPrint(
                                'Error loading customer avatar: $exception',
                              );
                            }
                          : null,
                      child: const Icon(
                        Icons.person,
                        color: AppColors.luxuryGold,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (showPhoneWarning)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Doplňte telefónne číslo pre objednanie jazdy.',
                        style: TextStyle(
                          color: Color(0xFFFFCC80),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/profile'),
                      child: const Text(
                        'Upraviť',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

            // Active Ride Card
            BlocBuilder<RideCubit, RideState>(
              builder: (context, rideState) {
                if (rideState.currentRide != null &&
                    rideState.currentRide!.status != RideStatus.completed &&
                    rideState.currentRide!.status != RideStatus.cancelled) {
                  return GestureDetector(
                    onTap: () => context.push('/active-ride'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.luxuryGold, Color(0xFF8B6E2A)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.luxuryGold.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_taxi,
                            color: Colors.black,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AKTÍVNA JAZDA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: Colors.black54,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  rideState.currentRide!.status.name
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.black,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // On-Demand Flow Card
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Objednajte si jazdu',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => context.push('/search'),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.luxuryGold.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.luxuryGold.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.luxuryGold.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: AppColors.luxuryGold,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Kam to bude?',
                            style: TextStyle(
                              color: Color(0xFFB8BEC9),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Saved Addresses Chips
            if (savedAddresses.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: savedAddresses.entries.map((entry) {
                    final key = entry.key;
                    final data = entry.value as Map<String, dynamic>? ?? {};
                    final label = data['label']?.toString() ?? key;
                    final address = data['address']?.toString() ?? '';
                    final lat =
                        double.tryParse(data['lat']?.toString() ?? '0') ?? 0;
                    final lng =
                        double.tryParse(data['lng']?.toString() ?? '0') ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        avatar: Icon(
                          key == 'home'
                              ? Icons.home_filled
                              : (key == 'work'
                                    ? Icons.work
                                    : Icons.location_on),
                          size: 16,
                          color: AppColors.luxuryGold,
                        ),
                        label: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          if (address.isNotEmpty) {
                            final location = LocationModel(
                              name: label,
                              address: address,
                              position: LatLng(lat, lng),
                            );
                            context.push('/ride-request', extra: location);
                          }
                        },
                        backgroundColor: const Color(0xFF1A1A1A),
                        side: BorderSide(
                          color: AppColors.luxuryGold.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),

            // Promo Code Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.luxuryGold.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.luxuryGold,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'LIMITOVANÁ PONUKA',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          color: AppColors.luxuryGold.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Získaj zľavu 15%',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Zadaj promo kód GOLDTAXI a ušetri na svoju prvú jazdu.',
                    style: TextStyle(
                      color: Color(0xFFB8BEC9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
