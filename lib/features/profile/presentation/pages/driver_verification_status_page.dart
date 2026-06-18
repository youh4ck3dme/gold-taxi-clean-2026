import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../features/auth/presentation/cubits/auth_cubit.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';

class DriverVerificationStatusPage extends StatelessWidget {
  final String status; // 'pending_verification' or 'suspended'

  const DriverVerificationStatusPage({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending_verification';

    return Scaffold(
      appBar: AppBar(
        title: Text(isPending ? 'Verifikácia profilu' : 'Účet zablokovaný'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: BlocProvider(
        create: (_) => getIt<ProfileCubit>()..fetchProfile(),
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Visual Graphic
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isPending ? Colors.blue[50] : Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPending
                            ? Icons.verified_user_outlined
                            : Icons.gpp_bad_outlined,
                        size: 80,
                        color: isPending ? Colors.blue[800] : Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      isPending
                          ? 'Dokumenty sa kontrolujú'
                          : 'Váš účet vodiča bol zablokovaný',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      isPending
                          ? 'Naši administrátori momentálne overujú vaše nahrané dokumenty. Tento proces zvyčajne trvá menej ako 24 hodín. O schválení vás budeme informovať.'
                          : 'Váš účet vodiča bol zablokovaný z dôvodu porušenia našich obchodných podmienok alebo nízkeho priemerného hodnotenia. Ak si myslíte, že ide o chybu, kontaktujte našu podporu.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Buttons
                    if (isPending) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Aktualizovať stav'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          context.read<ProfileCubit>().fetchProfile();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text(
                        'Odhlásiť sa',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        getIt<AuthCubit>().logout();
                        context.go('/login');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
