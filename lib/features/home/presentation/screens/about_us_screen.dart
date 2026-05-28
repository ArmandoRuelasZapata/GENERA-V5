import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/features/home/presentation/providers/home_data_provider.dart';
import 'package:theoriginallab_v2/features/home/presentation/widgets/about_us_sections.dart';
import 'package:theoriginallab_v2/shared/widgets/app_animated_background.dart';
import 'package:theoriginallab_v2/shared/widgets/state_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AboutUsScreen extends ConsumerWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(homeAboutUsProvider);
    final statsAsync = ref.watch(homeStatsAndContactProvider);
    final projectsAsync = ref.watch(homeIncubatedProjectsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: aboutAsync.when(
          data: (data) {
            final missionData = data; // Root object contains Mission/Vision
            final values = List<dynamic>.from(data['valores'] ?? []);
            final methodology = List<dynamic>.from(data['metodologia'] ?? []);
            final advantages = List<String>.from(data['ventajas'] ?? []);

            return CustomScrollView(
              slivers: [
                // 1. Parallax Header
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    centerTitle: true,
                    titlePadding: const EdgeInsets.only(bottom: 16),
                    title: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sobre Nosotros',
                                style: AppTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Soluciones digitales innovadoras',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white70,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    background: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image background
                          Image.asset(
                            'assets/images/sobrenosotros.jpg',
                            fit: BoxFit.cover,
                          ),
                          // Overlay gradient for text readability - Bottom heavy dark fade
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.2),
                                  Colors.black.withValues(alpha: 0.6),
                                  Colors.black.withValues(alpha: 0.9),
                                ],
                                stops: const [0.0, 0.4, 0.7, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Content
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Mission & Vision
                      AboutUsMissionVision(data: missionData),
                      const SizedBox(height: AppSpacing.xlPadding),

                      // Values
                      Text('Nuestros Valores',
                          style: AppTypography.headlineMedium
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.mediumGap),
                      AboutUsValues(values: values),
                      const SizedBox(height: AppSpacing.xlPadding),

                      // Methodology
                      Text('Cómo Trabajamos',
                          style: AppTypography.headlineMedium
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.mediumGap),
                      AboutUsTimeline(steps: methodology),
                      const SizedBox(height: AppSpacing.xlPadding),

                      // Advantages
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.05),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ventajas',
                                style: AppTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.primaryNavy)),
                            const SizedBox(height: 16),
                            ...advantages.map((adv) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: AppColors.accentCyan,
                                          size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(adv,
                                              style: AppTypography.bodyMedium)),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xlPadding),

                      // Stats
                      statsAsync.when(
                        data: (statsData) {
                          final statsList =
                              List<dynamic>.from(statsData['datos'] ?? []);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Impacto',
                                  style: AppTypography.headlineMedium
                                      .copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: AppSpacing.mediumGap),
                              AboutUsStats(stats: statsList),

                              const SizedBox(height: AppSpacing.xlPadding),

                              // Projects
                              projectsAsync.when(
                                data: (projects) {
                                  if (projects.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Proyectos Incubados',
                                          style: AppTypography.headlineMedium
                                              .copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      const SizedBox(
                                          height: AppSpacing.mediumGap),
                                      AboutUsProjects(projects: projects),
                                      const SizedBox(
                                          height: AppSpacing.xlPadding),
                                    ],
                                  );
                                },
                                loading: () => const SizedBox(
                                    height: 100,
                                    child: Center(
                                        child: CircularProgressIndicator())),
                                error: (_, __) => const SizedBox.shrink(),
                              ),

                              // Contact
                              Text('Contáctanos',
                                  style: AppTypography.headlineMedium
                                      .copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: AppSpacing.mediumGap),
                              AboutUsContact(
                                  contactData: statsData['contacto'] ?? {}),
                            ],
                          );
                        },
                        loading: () => const AppLoadingState(),
                        error: (err, _) => Text('Error loading stats: $err'),
                      ),

                      const SizedBox(height: 50),
                    ].animate(interval: 100.ms).fade(duration: 500.ms).slideY(
                        begin: 0.1,
                        duration: 500.ms,
                        curve: Curves.easeOutQuad)),
                  ),
                ),
              ],
            );
          },
          loading: () => const Scaffold(
              backgroundColor: Colors.transparent,
              body: AppLoadingState(message: 'Cargando información...')),
          error: (err, stack) => Scaffold(
              backgroundColor: Colors.transparent,
              body: AppErrorWidget(
                  message: 'Error: $err',
                  onRetry: () => ref.refresh(homeAboutUsProvider))),
        ),
      ),
    );
  }
}
