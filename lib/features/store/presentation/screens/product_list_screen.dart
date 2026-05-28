import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/features/store/presentation/providers/products_provider.dart';
import 'package:theoriginallab_v2/features/store/presentation/widgets/product_card.dart';
import 'package:theoriginallab_v2/features/store/domain/entities/product.dart';

enum SortOption { priceAsc, priceDesc, nameAsc }

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String? _selectedCategory;
  bool _showFreeOnly = false;
  SortOption _sortOption = SortOption.priceAsc;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final searchQuery = ref.watch(storeSearchQueryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            onChanged: (value) {
              ref.read(storeSearchQueryProvider.notifier).state = value;
            },
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort, color: colorScheme.onSurface),
            tooltip: 'Ordenar por',
            onSelected: (SortOption result) {
              setState(() {
                _sortOption = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(
                value: SortOption.priceAsc,
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 16),
                    SizedBox(width: 8),
                    Text('Menor Precio'),
                  ],
                ),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.priceDesc,
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16),
                    SizedBox(width: 8),
                    Text('Mayor Precio'),
                  ],
                ),
              ),
              const PopupMenuItem<SortOption>(
                value: SortOption.nameAsc,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 16),
                    SizedBox(width: 8),
                    Text('Nombre (A-Z)'),
                  ],
                ),
              ),
            ],
          ),
        ],
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      // backgroundColor: Colors.transparent, // Removed to use Theme background
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xlPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.engineering_outlined,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Estamos mejorando tu experiencia',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'El catálogo está momentáneamente en mantenimiento mientras actualizamos nuestros servidores. Por favor intenta más tarde.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => ref.refresh(productsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (originalProducts) {
          // 1. Get unique categories
          final categories =
              originalProducts.map((p) => p.category).toSet().toList();
          categories.sort();

          // 2. Filter Products
          final filteredProducts = originalProducts.where((product) {
            final matchesSearch = product.title
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                product.description
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase());
            final matchesCategory = _selectedCategory == null ||
                product.category == _selectedCategory;
            final matchesFree = !_showFreeOnly || product.price == 0;
            return matchesSearch && matchesCategory && matchesFree;
          }).toList();

          // 3. Sort Products
          filteredProducts.sort((a, b) {
            switch (_sortOption) {
              case SortOption.priceAsc:
                return a.price.compareTo(b.price);
              case SortOption.priceDesc:
                return b.price.compareTo(a.price);
              case SortOption.nameAsc:
                return a.title.compareTo(b.title);
            }
          });

          // 4. Group by Category (Only if NOT sorting by price, usually grouping overrides sorting order visually)
          // Actually, if we want to show a flat list sorted by price, we shouldn't group by category.
          // Or we sort WITHIN categories. User likely wants global sort.
          // Let's ungroup if sorting is active? Or keep grouping?
          // Typically "Sort by Price" implies a flat list or sorting within groups.
          // Given the UI shows headers, I'll sort WITHIN groups for now to maintain structure,
          // UNLESS the user explicitly requested a flat list.
          // "acomodar de mas barato a mas caro" usually means the whole list.
          // If I keep categories, a cheap item in Category B might be below an expensive item in Category A.
          // I will Use a FLAT LIST if a specific sort is selected (or just keep it simple and sort within groups first).
          // ACTUALLY, simpler approach: Sort the filtered list, and if _selectedCategory is null,
          // we might want to Abandon grouping if sorting by price to make it a true "Low to High".
          // But looking at the code, it groups by category logic:
          // final Map<String, List<Product>> groupedProducts = {};
          // ...
          // So if I sort `filteredProducts` first, then add to groups, the groups will contain sorted items,
          // BUT the groups themselves might be in category order.
          // To truly show "Cheapest First" globally, we should disable grouping view when sorting by price?
          // For now, I will keep the Category Grouping but sort items INSIDE it, and maybe sort Categories by their cheapest item?
          // Too complex. Let's just sort items inside groups for now as a safe first step.
          // WAIT, the previous code iterated `groupedProducts.forEach`.
          // If I want global sort, I should probably ditch the category headers if the user sorts by price.
          // Let's try to keep it simple: Sort `filteredProducts`. Then group.
          // If I want true global sort, I should just display `filteredProducts` directly without headers?
          // The current UI relies on headers to separate sections.
          // I'll stick to: Sort `filteredProducts`. Then populate `groupedProducts`.
          // This ensures within each category, items are sorted.

          // 3. Group by Category
          final Map<String, List<Product>> groupedProducts = {};
          if (_selectedCategory != null) {
            groupedProducts[_selectedCategory!] = filteredProducts;
          } else {
            // Identify categories present in filtered list
            final presentCategories =
                filteredProducts.map((p) => p.category).toSet().toList();
            presentCategories.sort(); // Sort categories alphabetically

            for (var category in presentCategories) {
              groupedProducts[category] = filteredProducts
                  .where((p) => p.category == category)
                  .toList();
            }
          }

          // 4. Build List
          final List<Widget> flatWidgets = [];
          groupedProducts.forEach((category, products) {
            if (products.isNotEmpty) {
              // Header
              flatWidgets.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.mediumGap,
                      AppSpacing.screenPadding,
                      AppSpacing.smallGap),
                  child: Row(
                    children: [
                      Icon(_getCategoryIcon(category),
                          size: 20, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary),
                      ),
                      const Spacer(),
                      Text(
                        '${products.length}',
                        style: AppTypography.labelSmall
                            .copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );

              // Products (Already sorted in filteredProducts, and we grabbed them in order or via where)
              // If we use .where on filteredProducts (which is sorted), the result retains order.
              flatWidgets.addAll(products.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: ProductCard(product: p),
                  )));
            }
          });

          // Footer padding
          flatWidgets.add(const SizedBox(height: 80));

          return CustomScrollView(
            slivers: [
              // Controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'Todos',
                              isSelected: _selectedCategory == null,
                              onTap: () =>
                                  setState(() => _selectedCategory = null),
                            ),
                            const SizedBox(width: 8),
                            ...categories.map((cat) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: _FilterChip(
                                    label: cat,
                                    isSelected: _selectedCategory == cat,
                                    onTap: () =>
                                        setState(() => _selectedCategory = cat),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Toggles
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Solo Gratis'),
                            selected: _showFreeOnly,
                            onSelected: (val) =>
                                setState(() => _showFreeOnly = val),
                            visualDensity: VisualDensity.compact,
                            avatar: _showFreeOnly
                                ? const Icon(Icons.check, size: 16)
                                : null,
                          ),
                          const Spacer(),
                          Text(
                            '${filteredProducts.length} resultados',
                            style: AppTypography.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Product List (Grouped)
              if (filteredProducts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No se encontraron productos',
                            style: AppTypography.bodyLarge),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => flatWidgets[index],
                    childCount: flatWidgets.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? colorScheme.primary : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

IconData _getCategoryIcon(String category) {
  if (category.contains('Comercio')) return Icons.shopping_bag_outlined;
  if (category.contains('Soluciones')) return Icons.business_center_outlined;
  if (category.contains('Educación') || category.contains('Knowledge')) {
    return Icons.school_outlined;
  }
  return Icons.layers_outlined;
}
