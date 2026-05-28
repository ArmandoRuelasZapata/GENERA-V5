import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:theoriginallab_v2/core/config/env.dart';

class LogosGeneratorScreen extends StatefulWidget {
  const LogosGeneratorScreen({super.key});

  @override
  State<LogosGeneratorScreen> createState() => _LogosGeneratorScreenState();
}

class _LogosGeneratorScreenState extends State<LogosGeneratorScreen> {
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
        Uri.parse(Env.aiProxyUrl),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador de Logos (Beta)'),
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
