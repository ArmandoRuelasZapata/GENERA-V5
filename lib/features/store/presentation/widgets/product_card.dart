import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/utils/url_helper.dart';
import '../../domain/entities/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  void _openProduct(BuildContext context) {
    UrlHelper.openUrl(context, product.productUrl, title: product.title);
  }

  String _cleanTitle(String title) {
    // 1. Remove URLs
    title = title.replaceAll(RegExp(r'https?://\S+|www\.\S+'), '');
    // 2. Remove domain extensions like .com, .net inside parenthesis or standalone
    title = title.replaceAll(RegExp(r'\(\S+\.\S+\)'), '');
    // 3. Remove excess whitespace
    return title.trim();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFree = product.price == 0;

    // Logic for Badges
    final isAnnual = product.title.toLowerCase().contains('anual');
    final isMonthly = product.title.toLowerCase().contains('mensual');
    final isEnterprise = product.title.toLowerCase().contains('enterprise');

    final cleanedTitle = _cleanTitle(product.title);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      margin: const EdgeInsets.only(bottom: AppSpacing.mediumGap),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => _openProduct(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Image + Title + Category Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image or Fallback Avatar
                  Hero(
                    tag: product.id,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ),
                      child: product.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: product.imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 160,
                                memCacheHeight: 160,
                                errorWidget: (context, url, error) =>
                                    _CategoryAvatar(category: product.category),
                              ),
                            )
                          : _CategoryAvatar(category: product.category),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.mediumGap),

                  // Title & Category/Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cleanedTitle,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // "Chips para cosas que no sean el precio, como la categoría"
                            _Badge(
                                label: product.category.toUpperCase(),
                                color: colorScheme.primary),
                            if (isAnnual)
                              const _Badge(label: 'ANUAL', color: Colors.blue),
                            if (isMonthly)
                              const _Badge(
                                  label: 'MENSUAL', color: Colors.purple),
                            if (isEnterprise)
                              const _Badge(
                                  label: 'EMPRESAS', color: Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12), // Compact spacing

              // 2. Description Text (Improved Typography)
              Text(
                product.description,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface
                      .withValues(alpha: 0.8), // Brighter/More contrast
                  fontSize: 14,
                  height: 1.5, // Improved line height
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16), // Separation for Footer

              // 3. Footer: Price & Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.end, // Align to bottom
                children: [
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFree
                            ? 'SIN COSTO'
                            : '\$${product.price.toStringAsFixed(0)}',
                        style: AppTypography.headlineSmall.copyWith(
                          color: isFree ? Colors.green : colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          height: 1.0, // Tighter line height for large text
                        ),
                      ),
                      if (!isFree) ...[
                        const SizedBox(height: 2),
                        Text(
                          (isAnnual || isMonthly)
                              ? 'USD / mes' // Explicit per month
                              : '${product.currency} / periodo',
                          style: AppTypography.labelSmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const Spacer(),

                  // Action
                  FilledButton(
                    onPressed: () => _openProduct(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24), // More breathing room
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isFree ? 'Obtener' : 'Ver Oferta',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryAvatar extends StatelessWidget {
  final String category;

  const _CategoryAvatar({required this.category});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    // Mapping
    if (category.contains('Comercio')) {
      icon = Icons.shopping_bag_outlined;
      color = Colors.blue;
    } else if (category.contains('Soluciones')) {
      icon = Icons.business_center_outlined;
      color = Colors.orange;
    } else if (category.contains('Educación') ||
        category.contains('Knowledge')) {
      icon = Icons.school_outlined;
      color = Colors.purple;
    } else {
      icon = Icons.layers_outlined;
      color = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4), // Increased padding
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6), // Slightly more rounded
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11, // Increased size
          fontWeight: FontWeight.w700, // Bold
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
