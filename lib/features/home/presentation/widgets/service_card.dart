import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/widgets/glass_card.dart';

class ServiceCard extends StatefulWidget {
  final dynamic item;
  final int index;
  final VoidCallback? onCtaTap;

  const ServiceCard({
    super.key,
    required this.item,
    required this.index,
    this.onCtaTap,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Definir ícono basado en el título (simple lógica de mapeoc podría ser más robusta)
    IconData getIcon(String title) {
      final t = title.toLowerCase();
      if (t.contains('incubación')) return Icons.rocket_launch_outlined;
      if (t.contains('alianzas')) return Icons.handshake_outlined;
      if (t.contains('consultoría')) return Icons.lightbulb_outline;
      if (t.contains('desarrollo')) return Icons.code_outlined;
      if (t.contains('outsourcing')) return Icons.groups_outlined;
      if (t.contains('capacitación')) return Icons.school_outlined;
      return Icons.design_services_outlined;
    }

    final title = widget.item['titulo'] ?? 'Servicio';
    final description = widget.item['descripcion'] ?? '';
    final icon = getIcon(title);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.mediumGap),
      child: GlassCard(
        enableBlur: false,
        padding: EdgeInsets.zero,
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Column(
          children: [
            // Header Row (Always Visible)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.accentCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.mediumGap),
                  // Title and Short Desc
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isExpanded)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              description,
                              style: AppTypography.bodySmall.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Expand Icon
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.supportMedium,
                  ),
                ],
              ),
            ),

            // Expanded Content (Animated)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.cardPadding,
                        0,
                        AppSpacing.cardPadding,
                        AppSpacing.cardPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: AppSpacing.smallGap),
                          Text(
                            description,
                            style: AppTypography.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.mediumGap),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: widget.onCtaTap,
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('Cotizar'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
