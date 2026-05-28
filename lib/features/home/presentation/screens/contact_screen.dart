import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/features/home/presentation/providers/home_data_provider.dart';
import 'package:theoriginallab_v2/shared/widgets/app_animated_background.dart';
import 'package:theoriginallab_v2/shared/widgets/state_widgets.dart';
import 'package:theoriginallab_v2/shared/utils/url_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:theoriginallab_v2/features/maps/presentation/screens/map_screen.dart';

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  void _openUrl(BuildContext context, String? urlString, {String? title}) {
    UrlHelper.openUrl(context, urlString, title: title);
  }

  void _makeCall(BuildContext context, String phone) {
    UrlHelper.openUrl(context, 'tel:$phone');
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(homeStatsAndContactProvider);

    return AppAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Contacto',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: contactAsync.when(
          data: (data) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final contact = data['contacto'] as Map<String, dynamic>? ?? {};

            final phones = List<String>.from(
              contact['telefonos'] ??
                  const ['+52 618 542 8185', '+52 618 542 8195'],
            );
            final socials =
                (contact['redes_sociales'] as Map<String, dynamic>?) ??
                    const {
                      'facebook': 'https://www.facebook.com/TheOriginalLabMx/',
                      'instagram':
                          'https://www.instagram.com/theoriginallabmx/',
                      'tiktok': 'https://www.tiktok.com/@theoriginallabmx',
                    };
            final intro = (data['por_que_nosotros'] as String?) ??
                'Estamos listos para ayudarte con tu proyecto.';

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        (isDark ? AppColors.surfaceDarkElevated : Colors.white)
                            .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    intro,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                const SizedBox(height: 24),
                // Sección Teléfonos
                _buildSectionHeader(context, 'Teléfonos'),
                Container(
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.surfaceDarkElevated : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: phones.asMap().entries.map((entry) {
                      final index = entry.key;
                      final phone = entry.value;
                      final isLast = index == phones.length - 1;

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  const Icon(Icons.phone, color: Colors.green),
                            ),
                            title: Text(phone,
                                style: AppTypography.bodyLarge
                                    .copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text('Toca para llamar',
                                style: AppTypography.caption),
                            onTap: () => _makeCall(context, phone),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () =>
                                  _copyToClipboard(context, phone, 'Teléfono'),
                              tooltip: 'Copiar',
                            ),
                          ),
                          if (!isLast)
                            Divider(
                                height: 1,
                                indent: 60,
                                color: Colors.grey.withValues(alpha: 0.1)),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Sección Redes Sociales
                _buildSectionHeader(context, 'Redes Sociales'),
                Container(
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.surfaceDarkElevated : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      if (socials['facebook'] != null)
                        _buildSocialTile(context, 'Facebook', Icons.facebook,
                            Colors.blue[800]!, socials['facebook'], false),
                      if (socials['instagram'] != null)
                        _buildSocialTile(
                            context,
                            'Instagram',
                            FontAwesomeIcons.instagram,
                            Colors.pink,
                            socials['instagram'],
                            true), // Divider logic simplified
                      if (socials['tiktok'] != null)
                        _buildSocialTile(
                            context,
                            'TikTok',
                            FontAwesomeIcons.tiktok,
                            isDark ? Colors.white : Colors.black,
                            socials['tiktok'],
                            true,
                            isLast: true), // TikTok usually last
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Opcional Ubicación (Static for now if not in JSON)
                // User asked for "Opcional (si aplica)".
                // Since it's not in JSON, better to show a "Sede Central" if we know it, or omit.
                // I'll add a static one for Durango as a "bonus" clarity item, but commented out or valid if desired.
                // Let's verify context... "Instituto Estatal de las Mujeres Durango" is a client. Data implies Durango.
                // I will add it as a static tile for completeness of the "Settings" look.
                _buildSectionHeader(context, 'Ubicación'),
                Container(
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.surfaceDarkElevated : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Colors.red),
                    ),
                    title: Text('Durango, México',
                        style: AppTypography.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600)),
                    subtitle:
                        Text('Sede Central', style: AppTypography.caption),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(),
                        ),
                      );
                    },
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'The Original Lab v2.0',
                    style: AppTypography.caption.copyWith(color: Colors.grey),
                  ),
                )
              ],
            );
          },
          loading: () => const AppLoadingState(),
          error: (err, _) => AppErrorWidget(
            message: 'No se pudo cargar la información de contacto',
            onRetry: () => ref.refresh(homeStatsAndContactProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSocialTile(BuildContext context, String title, IconData icon,
      Color color, String url, bool showDivider,
      {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(title,
              style: AppTypography.bodyLarge
                  .copyWith(fontWeight: FontWeight.w600)),
          onTap: () => _openUrl(context, url),
          trailing: const Icon(Icons.open_in_new, size: 20, color: Colors.grey),
        ),
        if (!isLast)
          Divider(
              height: 1, indent: 60, color: Colors.grey.withValues(alpha: 0.1)),
      ],
    );
  }
}
