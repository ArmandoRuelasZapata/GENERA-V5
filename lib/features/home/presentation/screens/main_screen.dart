import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/providers/providers.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_animated_background.dart';
import '../providers/navigation_provider.dart';
import 'home_tab.dart';
import 'store_tab.dart';
import 'profile_tab.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../widgets/custom_drawer.dart';
import '../../../tickets/presentation/screens/red_negocios_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  Widget build(BuildContext context) {
    // OWASP M3 — Escucha el logout por inactividad y por 401
    ref.listen<AuthState>(authProvider, (previous, next) {
      next.whenOrNull(
        unauthenticated: () {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => const LoginScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
            (route) => false,
          );
        },
      );
    });

    final currentIndex = ref.watch(navigationIndexProvider);

    final screens = [
      const HomeTab(),
      const StoreTab(),
      const RedNegociosScreen(),
      const ProfileTab(),
    ];

    return AppAnimatedBackground(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,

          // ── AppBar — solo visible en Home (índice 0) ───────────────
          appBar: null,
          // ── Body ──────────────────────────────────────────────────
          body: PageTransitionSwitcher(
            transitionBuilder: (child, animation, secondaryAnimation) =>
                FadeThroughTransition(
              fillColor: Colors.transparent,
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            ),
            child: screens[currentIndex],
          ),

          // ── Bottom Navigation Bar ─────────────────────────────────
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (i) =>
                ref.read(navigationIndexProvider.notifier).state = i,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primaryNavy,
            unselectedItemColor: const Color(0xFF9E9E9E),
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            elevation: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payments_outlined),
                activeIcon: Icon(Icons.payments),
                label: 'Productos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.language_outlined),
                activeIcon: Icon(Icons.language),
                label: 'Red',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}