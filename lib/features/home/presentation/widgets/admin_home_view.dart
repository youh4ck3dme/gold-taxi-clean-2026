import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../map/data/repositories/ride_repository.dart';
import '../../../../models/ride_model.dart';
import '../../../../models/ride_status.dart';

class AdminHomeView extends StatelessWidget {
  final String userName;
  final String? avatarUrl;

  const AdminHomeView({
    super.key,
    required this.userName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final rideRepository = getIt<RideRepository>();

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
                    'Ahoj, $userName 🛡️',
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
                    'SYSTÉMOVÁ ADMINISTRÁCIA',
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
                  foregroundImage: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                      ? NetworkImage(avatarUrl!)
                      : null,
                  onForegroundImageError: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                      ? (exception, stackTrace) {
                          debugPrint('Error loading admin avatar: $exception');
                        }
                      : null,
                  child: const Icon(
                    Icons.shield,
                    color: AppColors.luxuryGold,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Quick Links
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.luxuryGold.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/admin'),
                  icon: const Icon(Icons.dashboard_rounded),
                  label: const Text('FULL PANEL'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: AppColors.luxuryGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('NASTAVENIA'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Live Statistics Stream
        const Text(
          'Živý prehľad platformy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 16),

        StreamBuilder<List<RideModel>>(
          stream: rideRepository.getAllRides(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.luxuryGold));
            }

            final rides = snapshot.data ?? [];
            final activeRides = rides.where((r) => r.status != RideStatus.completed && r.status != RideStatus.cancelled).length;
            final requestedRides = rides.where((r) => r.status == RideStatus.requested).length;
            final completedToday = rides.where((r) => r.status == RideStatus.completed).length;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard(
                  label: 'AKTÍVNE',
                  value: activeRides.toString(),
                  icon: Icons.local_taxi_rounded,
                  color: Colors.blueAccent,
                ),
                _buildStatCard(
                  label: 'ČAKAJÚCE',
                  value: requestedRides.toString(),
                  icon: Icons.notifications_active_rounded,
                  color: Colors.orangeAccent,
                ),
                _buildStatCard(
                  label: 'DOKONČENÉ',
                  value: completedToday.toString(),
                  icon: Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                ),
                _buildStatCard(
                  label: 'CELKOVO',
                  value: rides.length.toString(),
                  icon: Icons.analytics_rounded,
                  color: AppColors.luxuryGold,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
