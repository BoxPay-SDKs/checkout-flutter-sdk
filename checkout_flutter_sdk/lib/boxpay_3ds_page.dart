import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BoxPay3DSPage extends StatefulWidget {
  final String? redirectUrl;
  final String? htmlContent;
  final String? transactionRequest;

  const BoxPay3DSPage({
    Key? key,
    this.redirectUrl,
    this.htmlContent,
    this.transactionRequest,
  }) : super(key: key);

  @override
  State<BoxPay3DSPage> createState() => _BoxPay3DSPageState();
}

class _BoxPay3DSPageState extends State<BoxPay3DSPage> {
  late WebViewController _controller;

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
          // 1. INTERCEPT THE URL
          onPageStarted: (String url) {
            if (url.contains("boxpay")) { 
              
              // 2. STOP & CLOSE IMMEDIATELY
              _controller.loadRequest(Uri.parse("about:blank")); // Stop executing scripts
              Navigator.of(context).pop("completed"); // Return control to main screen
            }
          },
          onWebResourceError: (error) {
          },
        ),
      );

    // Load Content
    if (widget.htmlContent != null && widget.htmlContent!.isNotEmpty) {
      _controller.loadHtmlString(widget.htmlContent!);
    } else if (widget.redirectUrl != null && widget.redirectUrl!.isNotEmpty) {
      if (widget.transactionRequest != null && widget.transactionRequest!.isNotEmpty) {
        final bodyString = "txnreq=${Uri.encodeComponent(widget.transactionRequest!)}";
        _controller.loadRequest(
          Uri.parse(widget.redirectUrl!),
          method: LoadRequestMethod.post,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: Uint8List.fromList(utf8.encode(bodyString)),
        );
      } else {
        _controller.loadRequest(Uri.parse(widget.redirectUrl!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Authenticating..."),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            // User cancelled manually
            _controller.loadRequest(Uri.parse("about:blank")); // Stop executing scripts
              Navigator.of(context).pop("cancelled");
          },
        ),
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}