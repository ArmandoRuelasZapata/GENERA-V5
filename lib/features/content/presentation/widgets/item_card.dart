import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:theoriginallab_v2/shared/utils/url_helper.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../data/models/item_model.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;

  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => UrlHelper.openUrl(context, item.url, title: item.title),
      child: Card(
        elevation: AppSpacing.lowElevation,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with scrim gradient
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  CachedNetworkImage(
                    imageUrl: item.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const ShimmerImagePlaceholder(),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.supportLight.withValues(alpha: 0.3),
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: AppColors.supportMedium,
                      ),
                    ),
                  ),
                  // Scrim gradient for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tonal label bar with navy tint
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.smallGap,
                vertical: AppSpacing.smallGap,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceDarkElevated
                    : AppColors.primaryNavy.withValues(alpha: 0.08),
              ),
              child: Text(
                item.title,
                style: AppTypography.labelMedium.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.white
                      : AppColors.primaryNavy,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
