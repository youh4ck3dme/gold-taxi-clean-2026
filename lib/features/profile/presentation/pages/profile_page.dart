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
              body: Center(
                child: CircularProgressIndicator(),
              ),
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
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        'Nastala chyba: ${state.message}',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<ProfileCubit>().fetchProfile(),
                        child: const Text('Skúsiť znova'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (state is ProfileLoaded) {
            final user = state.user;
            if (user.isAdmin) {
              return const AdminProfilePage();
            } else if (user.isDriver) {
              return const DriverProfilePage();
            } else {
              return const CustomerProfilePage();
            }
          }
          return const SizedBox();
        },
      ),
    );
  }
}
