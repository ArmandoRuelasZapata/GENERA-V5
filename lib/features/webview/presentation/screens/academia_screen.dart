import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AcademiaScreen extends StatefulWidget {
  const AcademiaScreen({super.key});

  @override
  State<AcademiaScreen> createState() => _AcademiaScreenState();
}

class _AcademiaScreenState extends State<AcademiaScreen> {
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
        Uri.parse('https://academia.theoriginallab.com/login/index.php'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academia ToL (Beta)'),
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
