import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CotizacionAppScreen extends StatefulWidget {
  const CotizacionAppScreen({super.key});

  @override
  State<CotizacionAppScreen> createState() => _CotizacionAppScreenState();
}

class _CotizacionAppScreenState extends State<CotizacionAppScreen> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://theoriginallab.com/aula-virtual-apps#precios'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotización Apps (Beta)'),
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
