import 'package:flutter/material.dart';
import 'package:theoriginallab_v2/core/theme/app_spacing.dart';
import 'package:theoriginallab_v2/core/theme/app_typography.dart';
import 'package:theoriginallab_v2/shared/utils/url_helper.dart';

class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({super.key});

  static const String _termsUrl = 'https://theoriginallab.com';
  static const String _privacyUrl = 'https://theoriginallab.com';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Privacidad'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(
            'Información Legal',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.smallGap),
          Text(
            'Última actualización: 25 de febrero de 2026',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.mediumGap),
          Text(
            'En esta sección puedes revisar nuestras políticas de uso, protección de datos y responsabilidades sobre los servicios ofrecidos en la app.',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.mediumGap),
          Card(
            child: ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('Términos y Condiciones'),
              subtitle: const Text('Condiciones de uso de la plataforma'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => UrlHelper.openUrl(
                context,
                _termsUrl,
                title: 'Términos y Condiciones',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Política de Privacidad'),
              subtitle: const Text('Tratamiento y protección de datos'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => UrlHelper.openUrl(
                context,
                _privacyUrl,
                title: 'Política de Privacidad',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.largeGap),
          FilledButton.icon(
            onPressed: () => UrlHelper.openUrl(
              context,
              _privacyUrl,
              title: 'Política de Privacidad',
            ),
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Abrir Política de Privacidad'),
          ),
        ],
      ),
    );
  }
}
