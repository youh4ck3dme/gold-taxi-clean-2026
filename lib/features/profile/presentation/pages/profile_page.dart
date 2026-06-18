import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_taxi/core/di/service_locator.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';
import 'customer_profile_page.dart';
import 'driver_profile_page.dart';
import 'admin_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..fetchProfile(),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (state is ProfileError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Profil')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nastala chyba: ${state.message}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<ProfileCubit>().fetchProfile(),
                        child: const Text('Skúsiť znova'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (state is ProfileLoaded) {
            final user = state.user;

            // Determine which view to show based on activeRole
            Widget currentView;
            String title = 'Profil';

            if (state.activeRole == 'admin') {
              currentView = const AdminProfilePage();
              title = 'Admin Panel';
            } else if (state.activeRole == 'driver') {
              currentView = const DriverProfilePage();
              title = 'Profil Vodiča';
            } else {
              currentView = const CustomerProfilePage();
              title = 'Môj Profil';
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(title),
                actions: [
                  if (user.isAdmin || user.isDriver)
                    _buildRoleSwitcher(context, state),
                ],
              ),
              body: currentView,
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildRoleSwitcher(BuildContext context, ProfileLoaded state) {
    final user = state.user;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: PopupMenuButton<String>(
        icon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                state.activeRole.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),
        onSelected: (role) => context.read<ProfileCubit>().switchRole(role),
        itemBuilder: (context) => [
          if (user.isAdmin)
            const PopupMenuItem(
              value: 'admin',
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, size: 20),
                  SizedBox(width: 8),
                  Text('Admin View'),
                ],
              ),
            ),
          if (user.isDriver || user.isAdmin)
            const PopupMenuItem(
              value: 'driver',
              child: Row(
                children: [
                  Icon(Icons.local_taxi, size: 20),
                  SizedBox(width: 8),
                  Text('Driver View'),
                ],
              ),
            ),
          const PopupMenuItem(
            value: 'customer',
            child: Row(
              children: [
                Icon(Icons.person, size: 20),
                SizedBox(width: 8),
                Text('Customer View'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
