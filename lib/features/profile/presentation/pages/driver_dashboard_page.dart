import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../../../../features/map/data/repositories/ride_repository.dart';
import '../../../../features/map/data/repositories/mock_ride_repository.dart';
import '../../../../models/ride_model.dart';
import '../../../../models/ride_status.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';
import 'driver_verification_status_page.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/constants/app_colors.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  bool _isOnline = false;
  bool _isAcceptingRide = false;
  bool _isUpdatingStatus = false;
  late final RideRepository _rideRepository;
  final Map<String, Future<String>> _passengerNameCache = {};

  @override
  void initState() {
    super.initState();
    _rideRepository = getIt<RideRepository>();
  }

  void _updateStatus(String rideId, RideStatus status, {String? cancellationReason}) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await _rideRepository.updateRideStatus(rideId, status, cancellationReason: cancellationReason);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nepodarilo sa aktualizovať stav: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<String> _getPassengerName(String customerId) {
    return _passengerNameCache.putIfAbsent(
      customerId,
      () => _fetchPassengerName(customerId),
    );
  }

  Future<String> _fetchPassengerName(String customerId) async {
    if (_rideRepository is MockRideRepository) {
      return 'Mock Zákazník';
    }
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', customerId)
          .single();
      return response['full_name'] as String? ?? 'Zákazník';
    } catch (_) {
      return 'Zákazník';
    }
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
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileInitial || state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileLoaded) {
          final driverId = state.user.id;
          final verificationStatus = state.driverRecord?['verification_status'] as String? ?? 'pending_verification';
          final hasDocs = state.driverDocs != null &&
              state.driverDocs!['profile_photo_url'] != null &&
              state.driverDocs!['id_card_url'] != null &&
              state.driverDocs!['license_url'] != null;

          if (!hasDocs) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Panel Vodiča'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/profile'),
                ),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.assignment_late_outlined, size: 80, color: Colors.orange[800]),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Chýbajúce dokumenty',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Na aktiváciu vášho účtu a prijímanie jázd musíte nahrať profilovú fotku, občiansky preukaz a licenciu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Nahrať dokumenty'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[800],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.go('/driver/onboarding'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (verificationStatus == 'pending_verification') {
            return const DriverVerificationStatusPage(status: 'pending_verification');
          }

          if (verificationStatus == 'suspended') {
            return const DriverVerificationStatusPage(status: 'suspended');
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Panel Vodiča'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/profile'),
              ),
              actions: [
                Switch(
                  value: _isOnline,
                  onChanged: _toggleOnline,
                  activeThumbColor: Colors.green,
                ),
              ],
            ),
            body: StreamBuilder<RideModel?>(
              stream: _rideRepository.getDriverActiveRide(driverId),
              builder: (context, activeRideSnapshot) {
                final activeRide = activeRideSnapshot.data;
                if (activeRide != null) {
                  return _buildActiveRidePanel(context, activeRide);
                }

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StatusCard(isOnline: _isOnline),
                      const SizedBox(height: 16),
                      const _EarningsButton(),
                      const SizedBox(height: 16),
                      const Text(
                        'Prichádzajúce požiadavky',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _IncomingRequestsList(
                          rideRepository: _rideRepository,
                          isOnline: _isOnline,
                          buildRideCard: _buildRideRequestCard,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        return const Scaffold(
          body: Center(child: Text('Nepodarilo sa načítať profil.')),
        );
      },
    );
  }

  Widget _buildRideRequestCard(RideModel ride) {
    final timeStr = '${ride.createdAt.hour.toString().padLeft(2, '0')}:${ride.createdAt.minute.toString().padLeft(2, '0')}';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Žiadosť o jazdu • $timeStr',
                  style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${ride.estimatedDistance} km',
                  style: const TextStyle(color: AppColors.grey500, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(ride.pickupAddress, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 2, top: 4, bottom: 4),
              child: Icon(Icons.more_vert, size: 16, color: Colors.grey),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(ride.dropoffAddress, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            if (ride.passengerNote != null && ride.passengerNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.grey800 : AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Poznámka: ${ride.passengerNote}',
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${ride.estimatedPrice.toStringAsFixed(2)} €',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                const SizedBox.shrink(),
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
                    onPressed: _isAcceptingRide ? null : () => _acceptRide(ride),
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
      setState(() => _isAcceptingRide = true);
      try {
        await _rideRepository.acceptRide(ride.id, authState.user.id.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jazda prijatá!')),
          );
        }
      } catch (e) {
        if (mounted) {
          final isTaken = e.toString().contains('no longer available') || e.toString().contains('already taken') || e.toString().contains('not found');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isTaken ? 'Jazda už nie je k dispozícii' : 'Chyba: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isAcceptingRide = false);
        }
      }
    }
  }

  Widget _buildActiveRidePanel(BuildContext context, RideModel ride) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary, width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.directions_car, color: AppColors.secondary, size: 40),
                const SizedBox(height: 8),
                const Text(
                  'AKTÍVNA JAZDA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ride.status.label,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Passenger Info Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zákazník',
                    style: TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<String>(
                    future: _getPassengerName(ride.customerId),
                    builder: (context, snapshot) {
                      final name = snapshot.data ?? 'Načítavam...';
                      return Text(
                        name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  if (ride.passengerNote != null && ride.passengerNote!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Poznámka k jazde',
                      style: TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.grey800 : AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ride.passengerNote!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Route Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Miesto vyzdvihnutia', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(ride.pickupAddress, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(indent: 32),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cieľová adresa', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(ride.dropoffAddress, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Status Control Actions
          if (_isUpdatingStatus)
            const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          else ...[
            if (ride.status == RideStatus.accepted)
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_run),
                label: const Text('Smerujem k zákazníkovi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () => _updateStatus(ride.id, RideStatus.driverArriving),
              ),
            if (ride.status == RideStatus.driverArriving)
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Začať jazdu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () => _updateStatus(ride.id, RideStatus.inProgress),
              ),
            if (ride.status == RideStatus.inProgress)
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Dokončiť jazdu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: AppColors.secondary,
                  minimumSize: const Size(double.infinity, 54),
                  side: const BorderSide(color: AppColors.secondary, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () => _updateStatus(ride.id, RideStatus.completed),
              ),
            if (ride.status == RideStatus.accepted || ride.status == RideStatus.driverArriving) ...[
              const SizedBox(height: 12),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _showCancellationDialog(context, ride.id),
                child: const Text('Zrušiť jazdu', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showCancellationDialog(BuildContext context, String rideId) {
    showDialog(
      context: context,
      builder: (context) => _CancellationDialog(
        rideId: rideId,
        onConfirm: (reason) {
          _updateStatus(rideId, RideStatus.cancelled, cancellationReason: reason);
        },
      ),
    );
  }
}

class _CancellationDialog extends StatefulWidget {
  final String rideId;
  final Function(String reason) onConfirm;

  const _CancellationDialog({
    required this.rideId,
    required this.onConfirm,
  });

  @override
  State<_CancellationDialog> createState() => _CancellationDialogState();
}

class _CancellationDialogState extends State<_CancellationDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Zrušiť jazdu?'),
      content: TextField(
        controller: _reasonController,
        decoration: const InputDecoration(
          labelText: 'Dôvod zrušenia',
          hintText: 'Napr. zákazník nenastúpil',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Späť'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final reason = _reasonController.text.trim();
            Navigator.pop(context);
            widget.onConfirm(reason.isNotEmpty ? reason : 'Zrušené vodičom');
          },
          child: const Text('Zrušiť jazdu'),
        ),
      ],
    );
  }
}

class _IncomingRequestsList extends StatelessWidget {
  final RideRepository rideRepository;
  final bool isOnline;
  final Widget Function(RideModel) buildRideCard;

  const _IncomingRequestsList({
    required this.rideRepository,
    required this.isOnline,
    required this.buildRideCard,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline) {
      return const Center(child: Text('Ste offline. Pre príjem jázd sa zapnite.'));
    }

    return StreamBuilder<List<RideModel>>(
      stream: rideRepository.getActiveRequests(),
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
          itemBuilder: (context, index) => buildRideCard(rides[index]),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isOnline;

  const _StatusCard({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              isOnline ? 'ONLINE' : 'OFFLINE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isOnline ? Colors.green : Colors.grey,
              ),
            ),
            const Text('Váš aktuálny stav'),
          ],
        ),
      ),
    );
  }
}

class _EarningsButton extends StatelessWidget {
  const _EarningsButton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/earnings'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.euro, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zárobky',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Zobrazte si svoj finančný prehľad',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
