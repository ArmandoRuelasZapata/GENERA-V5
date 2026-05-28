import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/utils/url_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic item;

  const ProductDetailScreen({super.key, required this.item});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final title = widget.item['nombre'] ?? 'Producto';
    final description = widget.item['descripcion'] ?? '';
    final url = widget.item['url'] as String?;
    final imageUrl = widget.item['imagen'] as String?;

    // Determine icon/image placeholder logic
    final isHardware = title.toLowerCase().contains('equipo');

    return Scaffold(
      backgroundColor: isDark ? AppColors.baseDark : AppColors.surfaceLight,
      body: Stack(
        children: [
          // 1. Animated Background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -100 + (_bgController.value * 50),
                    right: -50 - (_bgController.value * 20),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentCyan.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentCyan.withValues(alpha: 0.2),
                            blurRadius: 100,
                            spreadRadius: 50,
                          )
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50 - (_bgController.value * 30),
                    left: -100 + (_bgController.value * 40),
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryNavy.withValues(alpha: 0.1),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryNavy.withValues(alpha: 0.15),
                            blurRadius: 120,
                            spreadRadius: 60,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // 2. Main Content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: theme.colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.black54 : Colors.white54,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Image
                      Hero(
                        tag: 'product-$title',
                        child: Container(
                          width: double.infinity,
                          height: 250,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDarkElevated
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.cardRadius),
                                    child: Image.asset(
                                      imageUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return isHardware
                                            ? const Icon(
                                                Icons.computer_rounded,
                                                size: 100,
                                                color: AppColors.accentCyan,
                                              )
                                            : const Icon(
                                                Icons.devices_other_rounded,
                                                size: 100,
                                                color: AppColors.primaryNavy,
                                              );
                                      },
                                    ),
                                  )
                                : (isHardware
                                    ? const Icon(Icons.computer_rounded,
                                        size: 100, color: AppColors.accentCyan)
                                    : const Icon(Icons.devices_other_rounded,
                                        size: 100,
                                        color: AppColors.primaryNavy)),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.largeGap),

                      // Title
                      Text(
                        title,
                        style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.smallGap),

                      // Category/Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : AppColors.white,
                          border: Border.all(
                            color: isDark
                                ? AppColors.accentCyan
                                : AppColors.primaryNavy,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isHardware ? 'Hardware' : 'Digital',
                          style: AppTypography.caption.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.primaryNavy,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.mediumGap),

                      // Description
                      Text(
                        description,
                        style: AppTypography.bodyLarge.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.largeGap),

                      // Key Features Bullets
                      Text(
                        'Beneficios Principales',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.smallGap),
                      _buildBulletPoint(
                          theme, 'Solución adaptada a tus necesidades'),
                      _buildBulletPoint(
                          theme, 'Soporte técnico y actualización continua'),
                      _buildBulletPoint(
                          theme, 'Mejora la experiencia de tus clientes'),
                      _buildBulletPoint(
                          theme, 'Alta escalabilidad para tu negocio'),

                      const SizedBox(
                          height: 120), // Bottom padding for anchored CTA
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      // Anchored CTA
      bottomSheet: url != null && url.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              decoration: BoxDecoration(
                color: isDark ? AppColors.baseDark : AppColors.surfaceLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => UrlHelper.openUrl(context, url),
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    label: const Text(
                      'Ver más detalles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentCyan, // Vibrant CTA
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.accentCyan, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
