import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../features/auth/presentation/cubits/auth_cubit.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is! ProfileLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil Administrátora'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                onPressed: () => getIt<AuthCubit>().logout(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Admin Info Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.red.shade100,
                        child: Icon(Icons.admin_panel_settings, size: 55, color: Colors.red.shade900),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          'Administrátor',
                          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Quick Navigation Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.dashboard_customize_outlined, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text(
                              'Ovládací panel',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Máte prístup do administrátorskej sekcie na monitorovanie jázd a celkového chodu systému.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const Divider(height: 32),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text('Otvoriť Admin Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          onPressed: () => context.push('/admin'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Account settings card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.security, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text(
                              'Zabezpečenie účtu',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow('Identifikačné číslo (ID)', user.id),
                        const SizedBox(height: 16),
                        _buildInfoRow('Úroveň oprávnení', 'Super Administrátor'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
