import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/providers/providers.dart';

import '../../../webview/presentation/screens/generic_webview_screen.dart';
import '../../../webview/config/webview_urls.dart';
import '../../../chatbot/presentation/screens/chatbot_screen.dart';
import '../screens/services_screen.dart';
import '../screens/products_catalog_screen.dart';
import '../screens/contact_screen.dart';
import 'package:theoriginallab_v2/features/maps/presentation/screens/map_screen.dart';
import 'package:theoriginallab_v2/features/home/presentation/providers/navigation_provider.dart';
import 'package:theoriginallab_v2/features/store/presentation/screens/product_list_screen.dart';

import 'package:theoriginallab_v2/features/home/presentation/screens/about_us_screen.dart';
import 'package:theoriginallab_v2/features/home/presentation/screens/success_stories_screen.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _navigateToTab(BuildContext context, WidgetRef ref, int index) {
    Navigator.pop(context);
    ref.read(navigationIndexProvider.notifier).state = index;
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardPadding,
        AppSpacing.smallGap,
        AppSpacing.cardPadding,
        AppSpacing.tinyGap,
      ),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Drawer(
      child: authState.maybeWhen(
        authenticated: (user) => ListView(
          padding: EdgeInsets.zero,
          children: [
            // Compact Premium Header
            _buildPremiumHeader(context, user),

            const SizedBox(height: AppSpacing.smallGap),

            // Sección: COMERCIAL
            _buildSectionHeader(context, 'COMERCIAL'),
            _DrawerTile(
              icon: Icons.shopping_bag_outlined,
              selectedIcon: Icons.shopping_bag,
              label: 'Productos',
              badge: 'Nuevo',
              onTap: () => _navigateTo(context, const ProductsCatalogScreen()),
            ),
            _DrawerTile(
              icon: Icons.design_services_outlined,
              selectedIcon: Icons.design_services,
              label: 'Servicios',
              badge: 'Nuevo',
              onTap: () => _navigateTo(context, const ServicesScreen()),
            ),
            _DrawerTile(
              icon: Icons.store_outlined,
              selectedIcon: Icons.store,
              label: 'Tienda',
              badge: 'Nuevo',
              onTap: () => _navigateTo(context, const ProductListScreen()),
            ),

            const Divider(height: AppSpacing.mediumGap),

            // Sección: COTIZACIONES
            _buildSectionHeader(context, 'COTIZACIONES'),
            _DrawerTile(
              icon: Icons.web_outlined,
              selectedIcon: Icons.web,
              label: 'Sitios Web',
              onTap: () => _navigateTo(
                context,
                const GenericWebViewScreen(
                    url: WebViewUrls.cotizacionWeb, title: 'Cotización Web'),
              ),
            ),
            _DrawerTile(
              icon: Icons.school_outlined,
              selectedIcon: Icons.school,
              label: 'Aula Virtual',
              onTap: () => _navigateTo(
                context,
                const GenericWebViewScreen(
                    url: WebViewUrls.cotizacionApp, title: 'Cotización Apps'),
              ),
            ),

            const Divider(height: AppSpacing.mediumGap),

            // Sección: SERVICIOS TOL
            _buildSectionHeader(context, 'SERVICIOS TOL'),
            _DrawerTile(
              icon: Icons.event_seat_outlined,
              selectedIcon: Icons.event_seat,
              label: 'Reservas Cowork',
              onTap: () => _navigateTo(
                context,
                const GenericWebViewScreen(
                    url: WebViewUrls.reservasCowork, title: 'Reservas Cowork'),
              ),
            ),
            _DrawerTile(
              icon: Icons.smart_toy_outlined,
              selectedIcon: Icons.smart_toy,
              label: 'Asistente Virtual',
              badge: 'Nuevo',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                );
              },
            ),
            _DrawerTile(
              icon: Icons.support_agent_outlined,
              selectedIcon: Icons.support_agent,
              label: 'Soporte',
              badge: 'Nuevo',
              onTap: () => _navigateToTab(context, ref, 2),
            ),
            _DrawerTile(
              icon: Icons.map_outlined,
              selectedIcon: Icons.map,
              label: 'Mapa de Sucursales',
              badge: 'Nuevo',
              onTap: () => _navigateTo(context, const MapScreen()),
            ),
            // Added Tools here as mostly they are generic services
            _DrawerTile(
              icon: Icons.auto_awesome_outlined,
              selectedIcon: Icons.auto_awesome,
              label: 'Generador Logos',
              onTap: () => _navigateTo(
                context,
                const GenericWebViewScreen(
                    url: WebViewUrls.logoGenerator,
                    title: 'Generador de Logos'),
              ),
            ),
            _DrawerTile(
              icon: Icons.cast_for_education_outlined,
              selectedIcon: Icons.cast_for_education,
              label: 'Academia ToL',
              onTap: () => _navigateTo(
                context,
                const GenericWebViewScreen(
                    url: WebViewUrls.academiaMoodle, title: 'Academia ToL'),
              ),
            ),

            const Divider(height: AppSpacing.mediumGap),

            // Sección: EMPRESA
            _buildSectionHeader(context, 'EMPRESA'),
            _DrawerTile(
              icon: Icons.business_outlined,
              selectedIcon: Icons.business,
              label: 'Sobre Nosotros',
              badge: 'Nuevo',
              onTap: () => _navigateTo(context, const AboutUsScreen()),
            ),
            _DrawerTile(
              icon: Icons.star_outline,
              selectedIcon: Icons.star,
              label: 'Casos de Éxito',
              badge: 'Nuevo',
              onTap: () => _navigateTo(context, const SuccessStoriesScreen()),
            ),
            _DrawerTile(
              icon: Icons.contact_page_outlined,
              selectedIcon: Icons.contact_page,
              label: 'Contacto',
              badge: 'Nuevo',
              onTap: () => _navigateTo(context, const ContactScreen()),
            ),

            const Divider(height: AppSpacing.mediumGap),

            // Sección: CONFIGURACIÓN
            _buildSectionHeader(context, 'CONFIGURACIÓN'),
            _DrawerTile(
              icon: Icons.manage_accounts_outlined,
              selectedIcon: Icons.manage_accounts,
              label: 'Panel de Usuario',
              onTap: () => _navigateToTab(context, ref, 3),
            ),

            const SizedBox(height: AppSpacing.mediumGap),
          ],
        ),
        unauthenticated: () => const Center(child: Text('No autenticado')),
        loading: () => const Center(child: CircularProgressIndicator()),
        orElse: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  /// Premium compact header
  Widget _buildPremiumHeader(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardPadding,
        AppSpacing.xlPadding + 24, // Add status bar height
        AppSpacing.cardPadding,
        AppSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.baseDark,
            AppColors.primaryNavy.withValues(alpha: 0.3)
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.white.withValues(alpha: 0.2),
            child: user.profileImage != null && user.profileImage!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user.profileImage!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      memCacheWidth: 128,
                      memCacheHeight: 128,
                      errorWidget: (context, url, error) => Text(
                        user.name[0].toUpperCase(),
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  )
                : Text(
                    user.name[0].toUpperCase(),
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.gap),

          // Name
          Text(
            user.name,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Email
          Text(
            user.email,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Custom drawer tile widget for consistent styling
class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(label, style: AppTypography.bodyMedium),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.accentCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
    );
  }
}
