import 'package:flutter/material.dart';
import '../../../../features/map/data/repositories/ride_repository.dart';
import '../../../../models/ride_model.dart';
import '../../../../models/ride_status.dart';
import '../../../../core/di/service_locator.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rideRepository = getIt<RideRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: StreamBuilder<List<RideModel>>(
        stream: rideRepository.getAllRides(),
        builder: (context, snapshot) {
          final rides = snapshot.data ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatGrid(rides),
                const SizedBox(height: 24),
                _buildActiveRidesList(rides),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatGrid(List<RideModel> rides) {
    final activeRides = rides
        .where(
          (r) =>
              r.status != RideStatus.completed &&
              r.status != RideStatus.cancelled,
        )
        .length;
    final completedToday = rides
        .where((r) => r.status == RideStatus.completed)
        .length;
    final totalRevenue = rides
        .where((r) => r.status == RideStatus.completed)
        .fold(0.0, (sum, r) => sum + (r.finalPrice ?? r.estimatedPrice));

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Aktívne jazdy', activeRides.toString(), Colors.blue),
        _buildStatCard(
          'Dokončené dnes',
          completedToday.toString(),
          Colors.green,
        ),
        _buildStatCard(
          'Dnešný obrat',
          '${totalRevenue.toStringAsFixed(2)} €',
          Colors.orange,
        ),
        _buildStatCard('Celkom jázd', rides.length.toString(), Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRidesList(List<RideModel> rides) {
    final activeRides = rides
        .where(
          (r) =>
              r.status != RideStatus.completed &&
              r.status != RideStatus.cancelled,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aktuálne prebiehajúce jazdy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (activeRides.isEmpty)
          const Card(child: ListTile(title: Text('Žiadne aktívne jazdy'))),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeRides.length,
          itemBuilder: (context, index) {
            final ride = activeRides[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.local_taxi),
                title: Text('Jazda #${ride.id.substring(0, 8)}'),
                subtitle: Text('Smer: ${ride.dropoffAddress}'),
                trailing: Text(
                  ride.status.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
