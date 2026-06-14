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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Admin Dashboard',
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
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.shield, color: AppColors.secondary, size: 28)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Quick Links
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/admin'),
                icon: const Icon(Icons.dashboard),
                label: const Text('Kompletný panel'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.settings),
                label: const Text('Nastavenia'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Live Statistics Stream
        const Text(
          'Živý prehľad jázd',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        StreamBuilder<List<RideModel>>(
          stream: rideRepository.getAllRides(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
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
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  context: context,
                  label: 'Aktívne jazdy',
                  value: activeRides.toString(),
                  icon: Icons.local_taxi,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  context: context,
                  label: 'Čakajúce požiadavky',
                  value: requestedRides.toString(),
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
                _buildStatCard(
                  context: context,
                  label: 'Dokončené dnes',
                  value: completedToday.toString(),
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                _buildStatCard(
                  context: context,
                  label: 'Všetky jazdy',
                  value: rides.length.toString(),
                  icon: Icons.list_alt,
                  color: Colors.purple,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDarkMode ? AppColors.grey900 : AppColors.grey50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.grey300.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
