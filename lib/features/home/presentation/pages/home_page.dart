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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ahoj, $userName 👋',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 26,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kam sa dnes chystáš?',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
                                    ),
                              ),
                            ],
                          ),
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

                      // Search Card (Where to? - Bolt Style)
                      InkWell(
                        onTap: () => context.push('/search'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? AppColors.grey900 : AppColors.grey50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode ? AppColors.grey800 : AppColors.grey200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: AppColors.secondary,
                                size: 28,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Kam to bude?',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: isDarkMode ? AppColors.grey400 : AppColors.grey500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: isDarkMode ? AppColors.grey600 : AppColors.grey400,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Section Title: Main Services
                      Text(
                        'Naše služby',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Grid of Services (Bolt Category Cards)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.15,
                        children: [
                          _buildServiceCard(
                            context: context,
                            title: 'Odvoz',
                            subtitle: 'Objednať taxík',
                            icon: Icons.local_taxi,
                            color: AppColors.secondary,
                            onTap: () => context.push('/services'),
                          ),
                          _buildServiceCard(
                            context: context,
                            title: 'Obchod',
                            subtitle: 'Gold-Taxi E-shop',
                            icon: Icons.shopping_bag,
                            color: AppColors.accent,
                            onTap: () => context.push('/products'),
                          ),
                          _buildServiceCard(
                            context: context,
                            title: 'Udalosti',
                            subtitle: 'Plánované jazdy',
                            icon: Icons.event,
                            color: AppColors.success,
                            onTap: () => context.push('/events'),
                          ),
                          _buildServiceCard(
                            context: context,
                            title: 'Novinky',
                            subtitle: 'Články & Blog',
                            icon: Icons.article,
                            color: Colors.purple,
                            onTap: () => context.push('/blog'),
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
                                Text(
                                  'Získaj zľavu 15%',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? AppColors.white : AppColors.black,
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

  Widget _buildServiceCard({
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
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDarkMode ? AppColors.grey800 : AppColors.grey100,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon container with circular background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDarkMode ? AppColors.grey400 : AppColors.grey500,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
