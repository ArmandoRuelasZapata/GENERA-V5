import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/webview/presentation/screens/generic_webview_screen.dart';

/// Centralized URL opening utility.
/// Routes http/https links to in-app WebView,
/// and tel:/mailto: to native handlers.
class UrlHelper {
  /// Opens a map chooser so the user selects which app to use.
  /// Apple Maps is always offered on iOS as required by App Store Review.
  static Future<void> openMapChooser(
    BuildContext context, {
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final options = <_MapOption>[];

    final appleUri = _buildAppleMapsUri(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );

    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    if (isIOS || await canLaunchUrl(appleUri)) {
      options.add(const _MapOption('Apple Maps', _MapApp.apple));
    }

    final googleUri = _buildGoogleMapsUri(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );
    if (await canLaunchUrl(googleUri)) {
      options.add(const _MapOption('Google Maps', _MapApp.google));
    }

    if (!context.mounted) return;

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay apps de mapas disponibles')),
      );
      return;
    }

    final selected = await showModalBottomSheet<_MapOption>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Abrir ubicación'),
                subtitle: Text('Elige la app de mapas'),
              ),
              for (final option in options)
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(option.label),
                  onTap: () => Navigator.pop(sheetContext, option),
                ),
              ListTile(
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !context.mounted) return;

    final uri = selected.app == _MapApp.apple ? appleUri : googleUri;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el mapa: $e')),
        );
      }
    }
  }

  /// Opens a URL. HTTP/HTTPS opens in-app WebView; tel:/mailto: opens externally.
  static Future<void> openUrl(
    BuildContext context,
    String? urlString, {
    String? title,
  }) async {
    if (urlString == null || urlString.isEmpty) return;

    final uri = Uri.tryParse(urlString);
    if (uri == null) return;

    // Phone calls & email — always external
    if (uri.scheme == 'tel' || uri.scheme == 'mailto') {
      try {
        await launchUrl(uri);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo abrir: $e')),
          );
        }
      }
      return;
    }

    // HTTP/HTTPS — in-app WebView
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final secureUri =
          uri.scheme == 'http' ? uri.replace(scheme: 'https') : uri;
      // Force external app for social media links to avoid Webview issues
      if (secureUri.host.contains('facebook.com') ||
          secureUri.host.contains('instagram.com') ||
          secureUri.host.contains('tiktok.com') ||
          secureUri.host.contains('linkedin.com') ||
          secureUri.host.contains('twitter.com') ||
          secureUri.host.contains('x.com')) {
        try {
          await launchUrl(secureUri, mode: LaunchMode.externalApplication);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No se pudo abrir: $e')),
            );
          }
        }
        return;
      }

      final pageTitle = title ?? _titleFromUrl(secureUri);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GenericWebViewScreen(
              url: secureUri.toString(),
              title: pageTitle,
              showBetaLabel: false,
            ),
          ),
        );
      }
      return;
    }

    // Fallback: try external launch
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir: $e')),
        );
      }
    }
  }

  /// Derives a readable title from a URL's host.
  static String _titleFromUrl(Uri uri) {
    final host = uri.host.replaceFirst('www.', '');
    // Capitalize first letter
    if (host.isEmpty) return 'Página';
    return host[0].toUpperCase() + host.substring(1);
  }

  static Uri _buildAppleMapsUri({
    required double latitude,
    required double longitude,
    String? label,
  }) {
    final query = <String, String>{
      'daddr': '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
    };
    if (label != null && label.trim().isNotEmpty) {
      query['q'] = label.trim();
    }
    return Uri(scheme: 'maps', host: '', queryParameters: query);
  }

  static Uri _buildGoogleMapsUri({
    required double latitude,
    required double longitude,
    String? label,
  }) {
    final query = <String, String>{
      'daddr': '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
      'directionsmode': 'driving',
    };
    if (label != null && label.trim().isNotEmpty) {
      query['q'] = label.trim();
    }
    return Uri(scheme: 'comgooglemaps', host: '', queryParameters: query);
  }
}

enum _MapApp { apple, google }

class _MapOption {
  const _MapOption(this.label, this.app);
  final String label;
  final _MapApp app;
}
