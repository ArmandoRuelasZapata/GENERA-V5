import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/features/home/presentation/screens/product_detail_screen.dart';

class ProductCatalogCard extends StatelessWidget {
  final dynamic item;

  const ProductCatalogCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = item['nombre'] ?? 'Producto';
    final imageUrl = item['imagen'] as String?;

    // Determine visuals
    final isHardware = title.toLowerCase().contains('equipo');

    final cardBgColor = isDark ? AppColors.surfaceDarkElevated : Colors.white;

    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      openBuilder: (context, _) => ProductDetailScreen(item: item),
      closedElevation: 0,
      closedColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: openContainer,
          child: Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image/Icon Area with Overlay and Gradient
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Base Image
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppColors.primaryNavy.withValues(alpha: 0.05),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSpacing.cardRadius),
                          ),
                        ),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top:
                                        Radius.circular(AppSpacing.cardRadius)),
                                child: Image.asset(
                                  imageUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        isHardware
                                            ? Icons.computer
                                            : Icons.layers_outlined,
                                        size: 40,
                                        color: isDark
                                            ? Colors.white70
                                            : AppColors.primaryNavy,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Icon(
                                  isHardware
                                      ? Icons.computer
                                      : Icons.layers_outlined,
                                  size: 40,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.primaryNavy,
                                ),
                              ),
                      ),
                      // Gradiente inferior super-suave (limpio arriba)
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  cardBgColor,
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Text Area with refined Padding
                Expanded(
                  flex: 2,
                  child: Padding(
                    // Tighter padding to remove dead space
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.accentCyan,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
