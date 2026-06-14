import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../profile/presentation/bloc/profile_cubit.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/services')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/events')) return 3;
    if (location.startsWith('/blog')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/services');
        break;
      case 2:
        context.go('/products');
        break;
      case 3:
        context.go('/events');
        break;
      case 4:
        context.go('/blog');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = _getSelectedIndex(context);

    // Custom premium colors for BottomNavigationBar matching reference image
    final backgroundColor = isDarkMode ? AppColors.darkSurface : AppColors.white;
    const selectedItemColor = AppColors.secondary; // Gold accent
    final unselectedItemColor = isDarkMode ? AppColors.grey500 : AppColors.grey400;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<ProfileCubit>()),
      ],
      child: Scaffold(
        body: child,
        bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDarkMode ? AppColors.grey800 : AppColors.grey100,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) => _onItemTapped(index, context),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: selectedItemColor,
              unselectedItemColor: unselectedItemColor,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined),
                  activeIcon: Icon(Icons.grid_view),
                  label: 'Prehľad',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_taxi_outlined),
                  activeIcon: Icon(Icons.local_taxi),
                  label: 'Služby',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_bag_outlined),
                  activeIcon: Icon(Icons.shopping_bag),
                  label: 'Produkty',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event_outlined),
                  activeIcon: Icon(Icons.event),
                  label: 'Udalosti',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.article_outlined),
                  activeIcon: Icon(Icons.article),
                  label: 'Blog',
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
