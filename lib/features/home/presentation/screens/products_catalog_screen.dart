import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/features/home/presentation/providers/home_data_provider.dart';
import 'package:theoriginallab_v2/features/home/presentation/widgets/product_catalog_card.dart';
import 'package:theoriginallab_v2/shared/widgets/state_widgets.dart';
import 'package:theoriginallab_v2/shared/widgets/app_animated_background.dart';

// Helper provider for selected category
final selectedCategoryProvider =
    StateProvider.autoDispose<String>((ref) => 'Todos');

class ProductsCatalogScreen extends ConsumerWidget {
  const ProductsCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsDataAsync = ref.watch(homeProductsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppAnimatedBackground(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.transparent,
      body: productsDataAsync.when(
        data: (data) {
          final categories = List<String>.from(data['categorias'] ?? []);
          // Ensure "Todos" is present and first
          if (!categories.contains('Todos')) {
            categories.insert(0, 'Todos');
          }

          final allProducts = List<dynamic>.from(data['catalogo'] ?? []);

          // Filter Products
          final displayedProducts = selectedCategory == 'Todos'
              ? allProducts
              : allProducts.where((p) {
                  final name = p['nombre'].toString().toLowerCase();
                  final desc = p['descripcion'].toString().toLowerCase();
                  final text = '$name $desc';
                  final cat = selectedCategory.toLowerCase();

                  if (cat.contains('sitios web') &&
                      (text.contains('sitio') ||
                          text.contains('landing') ||
                          text.contains('página'))) {
                    return true;
                  }
                  if (cat.contains('comercio') &&
                      (text.contains('tienda') ||
                          text.contains('ecommerce') ||
                          text.contains('marketplace') ||
                          text.contains('cotizador') ||
                          text.contains('catálogo'))) {
                    return true;
                  }
                  if (cat.contains('educación') &&
                      (text.contains('aula') ||
                          text.contains('educ') ||
                          text.contains('curso') ||
                          text.contains('escuela'))) {
                    return true;
                  }
                  if (cat.contains('soluciones') &&
                      (text.contains('gestor') ||
                          text.contains('sistema') ||
                          text.contains('mantenedor') ||
                          text.contains('inventario') ||
                          text.contains('mailing') ||
                          text.contains('videollamada') ||
                          text.contains('administración'))) {
                    return true;
                  }
                  if (cat.contains('inteligencia') &&
                      (text.contains('bot') ||
                          text.contains('ia ') ||
                          text.contains('artificial') ||
                          text.contains('logo'))) {
                    return true;
                  }
                  if (cat.contains('aplicaciones') &&
                      (text.contains('app') ||
                          text.contains('aplicación') ||
                          text.contains('móvil') ||
                          text.contains('movil'))) {
                    return true;
                  }
                  if (cat.contains('hardware') &&
                      (text.contains('equipo') ||
                          text.contains('cómputo') ||
                          text.contains('hardware') ||
                          text.contains('computadora'))) {
                    return true;
                  }

                  // Strict mode: if it doesn't match, return false
                  return false;
                }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding),
                child: Text(
                  data['introduccion'] ?? 'Explora nuestra selección.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.mediumGap),

              // Categories Chips
              SizedBox(
                height: 50,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none, // Prevent clipping shadows
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == selectedCategory;
                    return ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(selectedCategoryProvider.notifier).state =
                            category;
                      },
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? Colors.white70
                                : theme.colorScheme.onSurface),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      selectedColor: AppColors.primaryNavy,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.accentCyan
                            : Colors.transparent,
                        width: 1,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.mediumGap),

              // Product Grid
              Expanded(
                child: displayedProducts.isEmpty
                    ? const AppEmptyWidget(
                        message: 'No se encontraron productos.')
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = width >= 1200
                              ? 4
                              : width >= 900
                                  ? 3
                                  : 2;
                          final aspectRatio = width < 360 ? 0.6 : 0.68;

                          return GridView.builder(
                            padding:
                                const EdgeInsets.all(AppSpacing.screenPadding),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: aspectRatio,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: displayedProducts.length,
                            itemBuilder: (context, index) {
                              return ProductCatalogCard(
                                  item: displayedProducts[index]);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const AppLoadingState(message: 'Cargando catálogo...'),
        error: (err, stack) => AppErrorWidget(
          message: 'Error: $err',
          onRetry: () => ref.refresh(homeProductsProvider),
        ),
      ),
    ));
  }
}
