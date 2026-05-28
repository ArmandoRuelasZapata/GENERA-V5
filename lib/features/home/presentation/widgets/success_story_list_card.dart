import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:animations/animations.dart';
import 'package:theoriginallab_v2/features/home/presentation/screens/success_story_detail_screen.dart';
import 'package:theoriginallab_v2/shared/widgets/glass_card.dart';
import 'package:theoriginallab_v2/shared/utils/url_helper.dart';

class SuccessStoryListCard extends StatelessWidget {
  final dynamic item;

  const SuccessStoryListCard({super.key, required this.item});

  String _getImageForSuccessStory(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('&', '')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    if (normalized.contains('agsoporte')) {
      return 'assets/images/casosexito/AGsoporte.jpg';
    }
    if (normalized.contains('aulaiem')) {
      return 'assets/images/casosexito/aulaiem.jpg';
    }
    if (normalized.contains('ferratelle')) {
      return 'assets/images/casosexito/ferratelle.jpg';
    }
    if (normalized.contains('heelcro')) {
      return 'assets/images/casosexito/heelcro.png';
    }
    if (normalized.contains('insignia')) {
      return 'assets/images/casosexito/insignia.png';
    }
    if (normalized.contains('karla') || normalized.contains('postreria')) {
      return 'assets/images/casosexito/karlapostreria.jpg';
    }
    if (normalized.contains('logistica') || normalized.contains('rodval')) {
      return 'assets/images/casosexito/logisticrodval.jpg';
    }
    if (normalized.contains('pastorsocial') || normalized.contains('pastor')) {
      return 'assets/images/casosexito/pastorsocial.png';
    }
    if (normalized.contains('valle')) {
      return 'assets/images/casosexito/valledelamor.png';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Extract info
    final title = item['titulo'] ?? 'Caso de Éxito';
    final subtitle = item['subtitulo'] ?? '';
    final description = item['descripcion'] ?? '';
    // Infer tag from description if not present (simple logic for now)
    final tags = <String>[];
    if (description.toLowerCase().contains('web')) tags.add('Web');
    if (description.toLowerCase().contains('app') ||
        title.toLowerCase().contains('app')) {
      tags.add('App');
    }
    if (description.toLowerCase().contains('ecommerce') ||
        description.toLowerCase().contains('tienda')) {
      tags.add('E-commerce');
    }
    if (tags.isEmpty) tags.add('Proyecto');

    final url = item['url'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.mediumGap),
      child: OpenContainer(
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (context, _) => SuccessStoryDetailScreen(item: item),
        closedElevation: 0,
        closedColor: Colors.transparent,
        closedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        closedBuilder: (context, openContainer) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.transparent),
          ),
          child: GlassCard(
            padding: const EdgeInsets.all(0),
            onTap: openContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Thumbnail Area
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : AppColors.primaryNavy.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.cardRadius)),
                    image: _getImageForSuccessStory(title).isNotEmpty
                        ? DecorationImage(
                            image: ResizeImage(
                              AssetImage(_getImageForSuccessStory(title)),
                              height: 300, // Optimize memory for lists
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _getImageForSuccessStory(title).isEmpty
                      ? Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: isDark
                                ? Colors.white30
                                : AppColors.primaryNavy.withValues(alpha: 0.3),
                          ),
                        )
                      : null,
                ),

                // 2. Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.accentCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // 3. Footer: Tags + Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ...tags.map((tag) => Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNavy
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.primaryNavy
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  tag,
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFF64FFDA)
                                        : AppColors
                                            .primaryNavy, // Brighter cyan for dark mode
                                  ),
                                ),
                              )),
                          const Spacer(),
                          if (url != null)
                            TextButton.icon(
                              onPressed: () => UrlHelper.openUrl(context, url),
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 18),
                              label: const Text('Ver sitio',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              iconAlignment: IconAlignment.end,
                              style: TextButton.styleFrom(
                                foregroundColor: isDark
                                    ? const Color(0xFF64FFDA)
                                    : AppColors.primaryNavy,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
