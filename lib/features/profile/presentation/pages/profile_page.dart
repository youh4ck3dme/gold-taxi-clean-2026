import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import 'package:gold_taxi/features/auth/presentation/cubits/auth_cubit.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(FetchProfile()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Môj profil'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/profile/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () {
                getIt<AuthCubit>().logout();
              },
            ),
          ],
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProfileError) {
              return Center(
                child: Text('Chyba: ${state.message}', style: const TextStyle(color: Colors.red)),
              );
            } else if (state is ProfileLoaded) {
              final user = state.user;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar & Info Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundImage: user.profilePictureUrl != null
                                  ? NetworkImage(user.profilePictureUrl!)
                                  : null,
                              child: user.profilePictureUrl == null
                                  ? const Icon(Icons.person, size: 45)
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                            if (user.bio != null && user.bio!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                user.bio!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Loyalty Points Card
                    Card(
                      color: Colors.orange[50],
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.orange[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vernostný program',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Získané body za nákupy',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.stars, color: Colors.orange, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  '${state.loyaltyPoints}',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bookings Tab
                    const Text(
                      'Moje Rezervácie',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (state.bookings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            'Nemáte žiadne aktívne rezervácie.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.bookings.length,
                        itemBuilder: (context, index) {
                          final booking = state.bookings[index];
                          final dateStr = DateFormat('dd.MM.yyyy').format(booking.bookingDate);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.drive_eta, color: Colors.blue),
                              title: Text('Služba ID: #${booking.serviceId}'),
                              subtitle: Text('$dateStr o ${booking.timeSlot}'),
                              trailing: Chip(
                                label: Text(
                                  booking.status.toUpperCase(),
                                  style: const TextStyle(fontSize: 10, color: Colors.white),
                                ),
                                backgroundColor: booking.status == 'approved' ? Colors.green : Colors.orange,
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),

                    // Orders Tab
                    const Text(
                      'História Objednávok',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (state.orders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            'Zatiaľ žiadne objednávky.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.orders.length,
                        itemBuilder: (context, index) {
                          final order = state.orders[index];
                          final total = double.tryParse(order['total'].toString()) ?? 0.0;
                          final dateStr = order['date_created'] != null
                              ? DateFormat('dd.MM.yyyy').format(DateTime.parse(order['date_created']))
                              : '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.shopping_bag_outlined, color: Colors.green),
                              title: Text('Objednávka #${order['id']}'),
                              subtitle: Text('$dateStr • Celkom: ${total.toStringAsFixed(2)} €'),
                              trailing: Chip(
                                label: Text(
                                  (order['status'] as String).toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
