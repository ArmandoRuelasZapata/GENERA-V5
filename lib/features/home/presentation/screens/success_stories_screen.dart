import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';

import 'package:theoriginallab_v2/features/home/presentation/providers/home_data_provider.dart';
import 'package:theoriginallab_v2/features/home/presentation/widgets/success_story_list_card.dart';
import 'package:theoriginallab_v2/shared/widgets/state_widgets.dart';

// Local provider for filter state
final storiesFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'Todos');
final storiesSearchProvider = StateProvider.autoDispose<String>((ref) => '');

class SuccessStoriesScreen extends ConsumerWidget {
  const SuccessStoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(homeSuccessStoriesProvider);
    final selectedFilter = ref.watch(storiesFilterProvider);
    final searchQuery = ref.watch(storiesSearchProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Defined filters (inferred as they aren't in JSON)
    final filters = ['Todos', 'Web', 'App', 'E-commerce', 'Institucional'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.baseDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Casos de Éxito'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.baseDark : AppColors.surfaceLight,
              border: Border(
                  bottom:
                      BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) =>
                      ref.read(storiesSearchProvider.notifier).state = value,
                  decoration: InputDecoration(
                    hintText: 'Buscar casos...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    prefixIcon: Icon(Icons.search,
                        color: isDark ? Colors.white70 : Colors.black54),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = filters[index];
                      final isSelected = filter == selectedFilter;

                      return PageTransitionSwitcher(
                        transitionBuilder:
                            (child, animation, secondaryAnimation) {
                          return FadeThroughTransition(
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            child: child,
                          );
                        },
                        child: FilterChip(
                          key: ValueKey(filter),
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(storiesFilterProvider.notifier).state =
                                filter;
                          },
                          backgroundColor:
                              isDark ? Colors.white10 : Colors.transparent,
                          selectedColor:
                              AppColors.primaryNavy.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primaryNavy
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryNavy
                                  : Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          checkmarkColor: AppColors.primaryNavy,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2. List
          Expanded(
            child: storiesAsync.when(
              data: (items) {
                // Filter Logic
                final filtered = items.where((item) {
                  final title = item['titulo']?.toString().toLowerCase() ?? '';
                  final desc =
                      item['descripcion']?.toString().toLowerCase() ?? '';
                  final fullText = '$title $desc';

                  // Search Check
                  if (searchQuery.isNotEmpty &&
                      !fullText.contains(searchQuery.toLowerCase())) {
                    return false;
                  }

                  // Tag Check (Simulation)
                  if (selectedFilter != 'Todos') {
                    // Simple heuristic matching since tags aren't in JSON
                    if (selectedFilter == 'App' &&
                        !fullText.contains('app') &&
                        !fullText.contains('móvil')) {
                      return false;
                    }
                    if (selectedFilter == 'Web' &&
                        !fullText.contains('web') &&
                        !fullText.contains('sitio')) {
                      return false;
                    }
                    if (selectedFilter == 'E-commerce' &&
                        !fullText.contains('tienda') &&
                        !fullText.contains('venta')) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const AppEmptyWidget(
                      message: 'No se encontraron casos de éxito.');
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return SuccessStoryListCard(item: filtered[index]);
                  },
                );
              },
              loading: () =>
                  const AppLoadingState(message: 'Cargando portafolio...'),
              error: (err, _) => AppErrorWidget(
                  message: 'Error: $err',
                  onRetry: () => ref.refresh(homeSuccessStoriesProvider)),
            ),
          ),
        ],
      ),
    );
  }
}
