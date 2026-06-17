import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../../../map/data/repositories/ride_repository.dart';
import '../../../../models/ride_model.dart';
import '../../../profile/presentation/bloc/profile_cubit.dart';
import '../../../profile/presentation/bloc/profile_state.dart';

class DriverHomeView extends StatefulWidget {
  final String userName;
  final String? avatarUrl;

  const DriverHomeView({
    super.key,
    required this.userName,
    this.avatarUrl,
  });

  @override
  State<DriverHomeView> createState() => _DriverHomeViewState();
}

class _DriverHomeViewState extends State<DriverHomeView> {
  bool _isOnline = false;
  late final RideRepository _rideRepository;

  @override
  void initState() {
    super.initState();
    _rideRepository = getIt<RideRepository>();
  }

  void _toggleOnline(bool value) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      await _rideRepository.updateDriverStatus(authState.user.id.toString(), value);
      if (mounted) {
        setState(() => _isOnline = value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ahoj, ${widget.userName} 🚖',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pripravený na jazdu?',
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
                foregroundImage: (widget.avatarUrl != null && widget.avatarUrl!.trim().isNotEmpty)
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
                onForegroundImageError: (widget.avatarUrl != null && widget.avatarUrl!.trim().isNotEmpty)
                    ? (exception, stackTrace) {
                        debugPrint('Error loading driver avatar: $exception');
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

        // Online Status Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Príjem nových požiadaviek'),
                  ],
                ),
                Switch(
                  value: _isOnline,
                  onChanged: _toggleOnline,
                  activeThumbColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Vehicle Info
        BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoaded && state.driverRecord != null) {
              final vehicleType = state.driverRecord!['vehicle_type']?.toString() ?? 'Neznáme vozidlo';
              final vehiclePlate = state.driverRecord!['vehicle_plate']?.toString() ?? 'Bez EČV';
              final serviceClasses = state.driverRecord!['service_classes'] as List<dynamic>? ?? [];

              return Card(
                elevation: 0,
                color: isDarkMode ? AppColors.grey900 : AppColors.grey50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.grey300.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car, color: AppColors.secondary, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicleType,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text('$vehiclePlate • ${serviceClasses.join(', ')}'),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => context.push('/profile'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 24),

        // Incoming Rides
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktuálne požiadavky',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push('/driver'),
              child: const Text('Všetky jazdy'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (!_isOnline)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.grey800 : AppColors.grey100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('Ste offline. Pre príjem jázd sa zapnite.'),
          )
        else
          StreamBuilder<List<RideModel>>(
            stream: _rideRepository.getActiveRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final rides = snapshot.data ?? [];
              if (rides.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.grey800 : AppColors.grey100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Momentálne žiadne nové požiadavky.'),
                );
              }
              
              // Show only first 3 requests
              final displayRides = rides.take(3).toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayRides.length,
                itemBuilder: (context, index) {
                  final ride = displayRides[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(ride.pickupAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${ride.estimatedPrice.toStringAsFixed(2)} € • ${ride.estimatedDistance} km'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/driver'),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
