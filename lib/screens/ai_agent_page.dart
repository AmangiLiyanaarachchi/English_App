import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AIAgentPage extends StatefulWidget {
  const AIAgentPage({super.key});

  @override
  State<AIAgentPage> createState() => _AIAgentPageState();
}

class _AIAgentPageState extends State<AIAgentPage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
          "https://agent.jotform.com/019ae53c76397cdd876e717ab286d62b9a36/voice?embedMode=iframe&background=1&shadow=1"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("English AI Agent"),
        backgroundColor: const Color(0xFF00B4D8),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
