import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../../../../features/map/data/repositories/ride_repository.dart';
import '../../../../models/ride_model.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/constants/app_colors.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
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
      setState(() => _isOnline = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Vodiča'),
        actions: [
          Switch(
            value: _isOnline,
            onChanged: _toggleOnline,
            activeThumbColor: Colors.green,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            const Text(
              'Prichádzajúce požiadavky',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isOnline
                  ? StreamBuilder<List<RideModel>>(
                      stream: _rideRepository.getActiveRequests(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final rides = snapshot.data ?? [];
                        if (rides.isEmpty) {
                          return const Center(child: Text('Momentálne žiadne nové požiadavky.'));
                        }
                        return ListView.builder(
                          itemCount: rides.length,
                          itemBuilder: (context, index) => _buildRideRequestCard(rides[index]),
                        );
                      },
                    )
                  : const Center(child: Text('Ste offline. Pre príjem jázd sa zapnite.')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideRequestCard(RideModel ride) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(child: Text(ride.pickupAddress, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 11, top: 4, bottom: 4),
              child: Align(alignment: Alignment.centerLeft, child: Icon(Icons.more_vert, size: 16, color: Colors.grey)),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(child: Text(ride.dropoffAddress, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${ride.estimatedPrice.toStringAsFixed(2)} €',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                Text('${ride.estimatedDistance} km', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {}, // Reject logic
                    child: const Text('Odmietnuť'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () => _acceptRide(ride),
                    child: const Text('Prijať'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _acceptRide(RideModel ride) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      await _rideRepository.acceptRide(ride.id, authState.user.id.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jazda prijatá!')),
        );
      }
    }
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _isOnline ? 'ONLINE' : 'OFFLINE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isOnline ? Colors.green : Colors.grey,
              ),
            ),
            const Text('Váš aktuálny stav'),
          ],
        ),
      ),
    );
  }
}
