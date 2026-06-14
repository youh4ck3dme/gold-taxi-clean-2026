import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? AppColors.darkSurface : AppColors.white;

    return BlocProvider.value(
      value: getIt<AuthCubit>(),
      child: Scaffold(
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            String userName = 'Hosť';
            String? avatarUrl;
            if (state is Authenticated) {
              userName = state.user.name;
              avatarUrl = state.user.profilePictureUrl;
            }

            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: User Profile & Greeting
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ahoj, $userName 👋',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 26,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kam sa dnes chystáš?',
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
                              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      color: AppColors.secondary,
                                      size: 28,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // On-Demand Flow Card (Bolt Style)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Objednajte si jazdu',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => context.push('/search'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              decoration: BoxDecoration(
                                color: isDarkMode ? AppColors.grey900 : AppColors.grey50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    color: AppColors.secondary,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'Kam to bude?',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Secondary CTA: Schedule Ride (Hybrid Model)
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionTile(
                              context: context,
                              title: 'Naplánovať jazdu',
                              subtitle: 'Letiská, limuzíny...',
                              icon: Icons.calendar_month,
                              color: Colors.blue,
                              onTap: () => context.push('/services'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionTile(
                              context: context,
                              title: 'Mapa vodičov',
                              subtitle: 'Sledovať okolie',
                              icon: Icons.map,
                              color: Colors.green,
                              onTap: () => context.push('/map'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Promo Code Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDarkMode
                                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                : [AppColors.secondary.withValues(alpha: 0.08), AppColors.secondary.withValues(alpha: 0.03)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_offer,
                                  color: AppColors.secondary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Získaj zľavu 15%',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? AppColors.white : AppColors.black,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Zadaj promo kód GOLDTAXI a ušetri 15% na svoju prvú rezervovanú jazdu cez našu aplikáciu!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDarkMode ? AppColors.grey300 : AppColors.grey700,
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Support / FAQs Button
                      ListTile(
                        onTap: () => context.push('/faq'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDarkMode ? AppColors.grey800 : AppColors.grey200,
                          ),
                        ),
                        tileColor: surfaceColor,
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.help_outline, color: AppColors.white),
                        ),
                        title: const Text(
                          'Centrum podpory & FAQ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Máte otázky? Sme tu pre vás.'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                      const SizedBox(height: 12),

                      // Insolvency Monitoring Button
                      ListTile(
                        onTap: () => context.push('/insolvency'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDarkMode ? AppColors.grey800 : AppColors.grey200,
                          ),
                        ),
                        tileColor: surfaceColor,
                        leading: const CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.analytics_outlined, color: AppColors.white),
                        ),
                        title: const Text(
                          'Monitoring úpadku',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Predikcia platobnej neschopnosti a morálka'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? AppColors.grey800 : AppColors.grey100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isDarkMode ? AppColors.grey400 : AppColors.grey500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
