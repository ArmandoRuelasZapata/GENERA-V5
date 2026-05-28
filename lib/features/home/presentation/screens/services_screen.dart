import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/features/home/presentation/providers/home_data_provider.dart';
import 'package:theoriginallab_v2/features/home/presentation/providers/navigation_provider.dart';
import 'package:theoriginallab_v2/features/home/presentation/widgets/service_card.dart';
import 'package:theoriginallab_v2/features/meetings/presentation/screens/service_selection_screen.dart';
import 'package:theoriginallab_v2/shared/widgets/state_widgets.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(homeServicesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        key: const Key('services_scroll_view'),
        slivers: [
          // 1. Premium Header with Abstract Hero
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.baseDark : AppColors.primaryNavy,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.baseDark,
                            AppColors.primaryNavy,
                          ]
                        : [
                            AppColors.primaryNavy,
                            AppColors.accentCyan,
                          ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Abstract overlapping circles for "Tech" feel
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentCyan.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    // Content
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                'CATÁLOGO DE SERVICIOS',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.mediumGap),
                            Text(
                              'Impulsamos tu\nCrecimiento',
                              style: AppTypography.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Soluciones tecnológicas a tu medida',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.mediumGap),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Services List
          servicesAsync.when(
            data: (items) {
              // Sorting logic (as requested)
              final order = [
                'Incubación',
                'Consultoría',
                'Desarrollo',
                'Outsourcing',
                'Capacitación',
                'Alianzas'
              ];

              final sortedItems = List<dynamic>.from(items);
              sortedItems.sort((a, b) {
                final titleA = (a['titulo'] as String).split(' ').first;
                final titleB = (b['titulo'] as String).split(' ').first;
                final indexA = order.indexWhere((o) => titleA.contains(o));
                final indexB = order.indexWhere((o) => titleB.contains(o));

                // If both found in order list
                if (indexA != -1 && indexB != -1) {
                  return indexA.compareTo(indexB);
                }
                // If only one found, prioritize it
                if (indexA != -1) return -1;
                if (indexB != -1) return 1;
                // Default: alphabetical
                return titleA.compareTo(titleB);
              });

              if (sortedItems.isEmpty) {
                return const SliverFillRemaining(
                  child: AppEmptyWidget(
                    message: 'No hay servicios disponibles por el momento.',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = sortedItems[index];
                      return ServiceCard(
                        item: item,
                        index: index,
                        onCtaTap: () {
                          // Navigate to Ticket creation or detail
                          // For now, switch to Tickets tab with a pre-message?
                          // Or pop back to main and go to tickets.
                          Navigator.pop(context); // Close Request
                          ref.read(navigationIndexProvider.notifier).state =
                              2; // Go to Tickets
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Inicia un ticket para cotizar este servicio')),
                          );
                        },
                      );
                    },
                    childCount: sortedItems.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: AppLoadingState(),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: AppErrorWidget(
                message: 'Error cargando servicios: $err',
                onRetry: () => ref.refresh(homeServicesProvider),
              ),
            ),
          ),

          // 3. Final CTA Block
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.xlPadding,
              ),
              padding: const EdgeInsets.all(AppSpacing.largePadding),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: AppColors.primaryNavy.withValues(alpha: 0.1),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.rocket_launch,
                    size: 40,
                    color:
                        isDark ? AppColors.accentCyan : AppColors.primaryNavy,
                  ),
                  const SizedBox(height: AppSpacing.mediumGap),
                  Text(
                    '¿Listo para comenzar?',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primaryNavy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Convierte tu idea en realidad con nuestros expertos.',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.largePadding),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(navigationIndexProvider.notifier).state =
                          2; // Go to Tickets
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentCyan,
                      foregroundColor:
                          isDark ? AppColors.baseDark : AppColors.primaryNavy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Crear Ticket de Cotización'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServiceSelectionScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white : AppColors.primaryNavy,
                      side: BorderSide(
                          color:
                              isDark ? Colors.white54 : AppColors.primaryNavy),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Agendar Reunión con Experto'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
