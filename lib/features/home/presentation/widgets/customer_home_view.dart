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

  const CustomerHomeView({
    super.key,
    required this.userName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        bool showPhoneWarning = false;
        Map<String, dynamic> savedAddresses = {};

        if (profileState is ProfileLoaded) {
          showPhoneWarning = profileState.user.phone == null || profileState.user.phone!.trim().isEmpty;
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
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kam sa dnes chystáš?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                    foregroundImage: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                        ? NetworkImage(avatarUrl!)
                        : null,
                    onForegroundImageError: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                        ? (exception, stackTrace) {
                            debugPrint('Error loading customer avatar: $exception');
                          }
                        : null,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.secondary,
                      size: 28,
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
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pre objednanie jazdy je potrebné vyplniť telefónne číslo vo vašom profile.',
                        style: TextStyle(color: isDarkMode ? Colors.orange[200] : Colors.orange[800], fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/profile'),
                      child: const Text('Upraviť'),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.secondary),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_taxi, color: AppColors.secondary, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Máte aktívnu jazdu',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Stav: ${rideState.currentRide!.status.name}',
                                  style: TextStyle(color: isDarkMode ? AppColors.grey400 : AppColors.grey700),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: AppColors.secondary, size: 16),
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
                Text(
                  'Objednajte si jazdu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => context.push('/search'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.grey900 : AppColors.grey50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: AppColors.secondary,
                          size: 32,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Kam to bude?',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
                                  fontWeight: FontWeight.bold,
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
              Wrap(
                spacing: 8,
                children: savedAddresses.entries.map((entry) {
                  final key = entry.key; // 'home' or 'work'
                  final data = entry.value as Map<String, dynamic>? ?? {};
                  final label = data['label']?.toString() ?? key;
                  final address = data['address']?.toString() ?? '';
                  final lat = double.tryParse(data['lat']?.toString() ?? '0') ?? 0;
                  final lng = double.tryParse(data['lng']?.toString() ?? '0') ?? 0;

                  return ActionChip(
                    avatar: Icon(
                      key == 'home' ? Icons.home : (key == 'work' ? Icons.work : Icons.location_on),
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    label: Text(label),
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
                    backgroundColor: isDarkMode ? AppColors.grey800 : AppColors.grey100,
                    side: BorderSide(color: AppColors.grey300.withValues(alpha: 0.5)),
                  );
                }).toList(),
              ),
            
            const SizedBox(height: 24),

            // Promo Code Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [AppColors.secondary.withValues(alpha: 0.08), AppColors.secondary.withValues(alpha: 0.03)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_offer,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Získaj zľavu 15%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? AppColors.white : AppColors.black,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zadaj promo kód GOLDTAXI a ušetri 15% na svoju prvú rezervovanú jazdu cez našu aplikáciu!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? AppColors.grey300 : AppColors.grey700,
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
