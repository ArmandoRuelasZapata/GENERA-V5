import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:theoriginallab_v2/features/home/presentation/screens/products_catalog_screen.dart';
import 'package:theoriginallab_v2/shared/utils/url_helper.dart';

import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/widgets/glass_card.dart';

class HomeFeaturedSection extends StatelessWidget {
  final List<dynamic> items;

  const HomeFeaturedSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Limit to 4 items
    final displayItems = items.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Destacados',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  return TextButton(
                    onPressed: () {
                      // Navigate to Products Catalog Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductsCatalogScreen(),
                        ),
                      );
                    },
                    child: const Text('Ver todos'),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionTitleGap),
        GridView.builder(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75, // Taller cards to prevent overflow
            crossAxisSpacing: AppSpacing.mediumGap,
            mainAxisSpacing: AppSpacing.mediumGap,
          ),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final item = displayItems[index];
            return _buildFeaturedCard(context, item, index);
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(BuildContext context, dynamic item, int index) {
    // Map index to available featured images (1-4)
    // Files: featured_1.png, featured_2.jpg, featured_3.png, featured_4.png
    final imageNumber = (index % 4) + 1;
    String extension = 'png';
    if (imageNumber == 2) {
      extension = 'jpg';
    }

    final assetPath = 'assets/images/home/featured_$imageNumber.$extension';
    final imageUrl = (item['image_url'] ?? '').toString();
    final ImageProvider imageProvider;
    if (imageUrl.isNotEmpty) {
      imageProvider = CachedNetworkImageProvider(
        imageUrl,
        maxWidth: 900,
      );
    } else {
      imageProvider = ResizeImage(
        AssetImage(assetPath),
        width: 900,
      );
    }

    return GlassCard(
      enableBlur: false,
      padding: EdgeInsets.zero,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1), // Subtle white border
        width: 1,
      ),
      onTap: () {
        final url = item['url'];
        if (url != null && url.isNotEmpty) {
          UrlHelper.openUrl(context, url, title: item['nombre'] ?? 'Producto');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.cardRadius),
                ),
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  // Neutral Scrim (Darken) instead of Blue Tint
                  // blending black with darken mode to lower brightness without shifting hue
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.2),
                    BlendMode.darken,
                  ),
                ),
              ),
              // Neutral Gradient Overlay
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.cardRadius),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black
                          .withValues(alpha: 0.7), // Strong black at bottom
                    ],
                    stops: const [0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center text vertically
                children: [
                  Text(
                    item['nombre'] ?? 'Producto',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['descripcion'] ?? '',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.8),
                    ),
                    maxLines: 2, // Allow 2 lines for better description context
                    overflow: TextOverflow.ellipsis,
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
