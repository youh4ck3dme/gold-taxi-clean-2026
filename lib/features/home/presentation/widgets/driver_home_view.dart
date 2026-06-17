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
                    style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'CENTRÁLA VODIČA',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                          color: AppColors.luxuryGold,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.5,
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
                    color: AppColors.luxuryGold,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Online Status Card
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isOnline ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: _isOnline ? [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ] : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: _isOnline ? Colors.greenAccent : Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isOnline ? 'Prijímate nové jazdy' : 'Jazdy sú pozastavené',
                      style: const TextStyle(color: Color(0xFFB8BEC9), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 1.2,
                  child: Switch(
                    value: _isOnline,
                    onChanged: _toggleOnline,
                    activeTrackColor: Colors.green.withOpacity(0.5),
                    activeColor: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Incoming Rides
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktuálne požiadavky',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            TextButton(
              onPressed: () => context.push('/driver'),
              child: const Text('HISTÓRIA', style: TextStyle(color: AppColors.luxuryGold, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (!_isOnline)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Icon(Icons.power_settings_new_rounded, size: 48, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),
                const Text(
                  'Pre príjem jázd sa zapnite do režimu ONLINE',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        else
          StreamBuilder<List<RideModel>>(
            stream: _rideRepository.getActiveRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.luxuryGold));
              }
              final rides = snapshot.data ?? [];
              if (rides.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Momentálne žiadne nové požiadavky.',
                    style: TextStyle(color: Color(0xFFB8BEC9)),
                  ),
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
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.luxuryGold.withOpacity(0.2)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_pin_circle_rounded, color: Colors.greenAccent),
                      ),
                      title: Text(
                        ride.pickupAddress, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${ride.estimatedPrice.toStringAsFixed(2)} € • ${ride.estimatedDistance} km',
                          style: const TextStyle(color: AppColors.luxuryGold, fontWeight: FontWeight.bold),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
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
