import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:theoriginallab_v2/core/theme/app_colors.dart';
import 'package:theoriginallab_v2/core/config/env.dart';

/// Generic WebView screen that can be used for any URL
/// This reduces code duplication and memory usage
class GenericWebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool showBetaLabel;

  const GenericWebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.showBetaLabel = true,
  });

  @override
  State<GenericWebViewScreen> createState() => _GenericWebViewScreenState();
}

class _GenericWebViewScreenState extends State<GenericWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // OWASP M5/D3: Solo se permite navegar a dominios autorizados.
            if (_isAllowedUrl(request.url)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  /// Lista dinámica de dominios permitidos originados por nuestro Env
  /// Se inicializa la primera vez que se consulta
  static Set<String>? _dynamicAllowedHosts;

  /// Devuelve true si la URL pertenece a un host autorizado o uno subyacente de nuestro Env.
  bool _isAllowedUrl(String url) {
    try {
      if (_dynamicAllowedHosts == null) {
        _dynamicAllowedHosts = {
          'theoriginallab.com',
          'www.theoriginallab.com',
          'originallabstore.com',
          'www.originallabstore.com',
        };

        final envUrls = [
          Env.authApiBaseUrl,
          Env.contentApiBaseUrl,
          Env.ticketsApiBaseUrl,
          Env.aiProxyUrl,
        ];

        for (final envUrl in envUrls) {
          if (envUrl.isNotEmpty) {
            final uri = Uri.tryParse(envUrl);
            if (uri != null && uri.host.isNotEmpty) {
              _dynamicAllowedHosts!.add(uri.host.toLowerCase());
            }
          }
        }
      }

      final uri = Uri.parse(url);
      // Solo acepta HTTPS — las URLs con esquema no-https son rechazadas
      if (uri.scheme != 'https') return false;
      final host = uri.host.toLowerCase();

      return _dynamicAllowedHosts!.any(
        (allowed) => host == allowed || host.endsWith('.$allowed'),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    // Proper cleanup to free memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          widget.showBetaLabel ? '${widget.title} (Beta)' : widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.baseDark,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // Reload button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Cargando...',
                      style: TextStyle(color: Colors.black54),
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
