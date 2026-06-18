import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../../../profile/presentation/bloc/profile_cubit.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../map/presentation/cubits/ride_cubit.dart';
import '../widgets/customer_home_view.dart';
import '../widgets/driver_home_view.dart';
import '../widgets/admin_home_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();
    // Trigger profile fetch when home page loads so that addresses/vehicle data is fresh
    _profileCubit = getIt<ProfileCubit>()..fetchProfile();
  }

  @override
  void dispose() {
    _profileCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? AppColors.darkSurface : AppColors.white;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: _profileCubit),
        // Add RideCubit if it's registered in DI
        if (getIt.isRegistered<RideCubit>())
          BlocProvider.value(value: getIt<RideCubit>()),
      ],
      child: Scaffold(
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            return BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                String userName = 'Hosť';
                String? avatarUrl;
                bool isDriver = false;
                bool isAdmin = false;

                if (authState is Authenticated) {
                  userName = authState.user.name;
                  avatarUrl = authState.user.profilePictureUrl;
                  isDriver = authState.user.isDriver;
                  isAdmin = authState.user.isAdmin;
                }

                if (profileState is ProfileLoaded) {
                  userName = profileState.user.name;
                  avatarUrl = profileState.user.profilePictureUrl;
                  isDriver = profileState.user.isDriver;
                  isAdmin = profileState.user.isAdmin;
                }

                return SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isDriver)
                            DriverHomeView(
                              userName: userName,
                              avatarUrl: avatarUrl,
                            )
                          else if (isAdmin)
                            AdminHomeView(
                              userName: userName,
                              avatarUrl: avatarUrl,
                            )
                          else
                            CustomerHomeView(
                              userName: userName,
                              avatarUrl: avatarUrl,
                            ),

                          // Common Elements below the role-specific dashboard
                          const SizedBox(height: 28),

                          // Support / FAQs Button
                          ListTile(
                            onTap: () => context.push('/faq'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDarkMode
                                    ? AppColors.grey800
                                    : AppColors.grey200,
                              ),
                            ),
                            tileColor: surfaceColor,
                            leading: const CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Icon(
                                Icons.help_outline,
                                color: AppColors.white,
                              ),
                            ),
                            title: const Text(
                              'Centrum podpory & FAQ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Máte otázky? Sme tu pre vás.',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                          const SizedBox(height: 12),

                          // Insolvency Monitoring Button
                          ListTile(
                            onTap: () => context.push('/insolvency'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDarkMode
                                    ? AppColors.grey800
                                    : AppColors.grey200,
                              ),
                            ),
                            tileColor: surfaceColor,
                            leading: const CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              child: Icon(
                                Icons.analytics_outlined,
                                color: AppColors.white,
                              ),
                            ),
                            title: const Text(
                              'Monitoring úpadku',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Predikcia platobnej neschopnosti a morálka',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
