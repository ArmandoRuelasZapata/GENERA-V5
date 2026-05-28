import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReservasCoworkScreen extends StatefulWidget {
  const ReservasCoworkScreen({super.key});

  @override
  State<ReservasCoworkScreen> createState() => _ReservasCoworkScreenState();
}

class _ReservasCoworkScreenState extends State<ReservasCoworkScreen> {
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
        Uri.parse('https://cowork.theoriginallab.com/reservas-tolcowork'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas Cowork (Beta)'),
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
