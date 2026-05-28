import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Pantalla de cotización que carga una URL fija de theoriginallab.com.
/// URL: https://theoriginallab.com/comercio-electronico-apps#precios
class CotizacionWebScreen extends StatefulWidget {
  const CotizacionWebScreen({super.key});

  @override
  State<CotizacionWebScreen> createState() => _CotizacionWebScreenState();
}

class _CotizacionWebScreenState extends State<CotizacionWebScreen> {
  late final WebViewController _controller;
  bool isLoading = true;

  // OWASP M5/D3: URL fija permitida para esta pantalla.
  static const _allowedUrl =
      'https://theoriginallab.com/comercio-electronico-apps#precios';

  static const _allowedHost = 'theoriginallab.com';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) setState(() => isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Solo permite navegar dentro de theoriginallab.com
            try {
              final uri = Uri.parse(request.url);
              if (uri.scheme == 'https' &&
                  (uri.host == _allowedHost ||
                      uri.host.endsWith('.$_allowedHost'))) {
                return NavigationDecision.navigate;
              }
            } catch (_) {}
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_allowedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotización Web (Beta)'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
