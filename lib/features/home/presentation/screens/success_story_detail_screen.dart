import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/utils/url_helper.dart';
import 'package:theoriginallab_v2/shared/widgets/app_animated_background.dart';

class SuccessStoryDetailScreen extends StatelessWidget {
  final dynamic item;

  const SuccessStoryDetailScreen({super.key, required this.item});

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

  void _share(BuildContext context, String? url, String title) {
    // Simulated share functionality
    final textToShare =
        "Mira este caso de éxito de The Original Lab: $title ${url ?? ''}";
    Clipboard.setData(ClipboardData(text: textToShare));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Enlace copiado al portapapeles (Simulación de Compartir)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = item['titulo'] ?? 'Caso de Éxito';
    final subtitle = item['subtitulo'] ?? '';
    final description = item['descripcion'] ?? '';
    final url = item['url'] as String?;
    final entity = item['entidad'] as String?;

    return Scaffold(
      backgroundColor: isDark ? AppColors.baseDark : AppColors.surfaceLight,
      body: AppAnimatedBackground(
        child: CustomScrollView(
          slivers: [
            // 1. Hero Image Header
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor:
                  Colors.transparent, // Let animated background show through
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(32)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image Placeholder or Asset
                      if (_getImageForSuccessStory(title).isNotEmpty)
                        Image(
                          image: ResizeImage(
                            AssetImage(_getImageForSuccessStory(title)),
                            width: 800, // Optimize memory for full width hero
                          ),
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          color: AppColors.primaryNavy,
                          child: Center(
                            child: Icon(
                              Icons.rocket_launch_rounded,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      // Gradient Overlay
                      Container(
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
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTypography.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.accentCyan,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entity != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primaryNavy.withValues(alpha: 0.2)
                              : AppColors.primaryNavy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  AppColors.primaryNavy.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.business_center_rounded,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF64FFDA)
                                    : AppColors.primaryNavy),
                            const SizedBox(width: 8),
                            Text(
                              'Cliente: $entity',
                              style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFF64FFDA)
                                      : AppColors.primaryNavy),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Sobre el proyecto',
                      style: AppTypography.titleLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      description,
                      style: AppTypography.bodyMedium.copyWith(
                        height: 1.8,
                        fontSize: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 3. Actions
                    Row(
                      children: [
                        if (url != null)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => UrlHelper.openUrl(context, url),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Abrir sitio',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryNavy,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                        if (url != null) const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => _share(context, url, title),
                            icon: const Icon(Icons.share_rounded),
                            color: theme.colorScheme.onSurface,
                            tooltip: 'Compartir',
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
