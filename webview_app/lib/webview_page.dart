import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

Timer? job;

class WebViewPage extends StatefulWidget {
  final String token;
  final Function(String) onPaymentResult;

  const WebViewPage(
      {super.key, required this.token, required this.onPaymentResult});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  WebViewController controller = WebViewController();

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) => {},
        onPageStarted: (url) => {},
        onPageFinished: (url) => {},
      ))
      ..loadRequest(Uri.parse(
          'https://test-checkout.boxpay.tech/?token=${widget.token}'));
    startFunctionCalls();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: WebViewWidget(controller: controller)),
    );
  }

  void startFunctionCalls() {
    job = Timer.periodic(Duration(seconds: 5), (Timer timer) async {
      fetchStatusAndReason(
          "https://test-apis.boxpay.tech/v0/checkout/sessions/${widget.token}/status");
    });
  }

  void stopFunctionCalls() {
    if (job != null) {
      job!.cancel();
      job = null; // Set it to null to indicate it's not running
    }
  }

  void fetchStatusAndReason(String url) async {
    print("fetching function called correctly"); // Equivalent to Log.d
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        var status = jsonResponse["status"];
        var statusReason = jsonResponse["statusReason"];
        print("WebView Status: $status");
        print("Status Reason: $statusReason");
        if (status.toUpperCase().contains("APPROVED") ||
            statusReason
                .toUpperCase()
                .contains("RECEIVED BY BOXPAY FOR PROCESSING") ||
            statusReason.toUpperCase().contains("APPROVED BY PSP") ||
            status.toUpperCase().contains("PAID")) {
          widget.onPaymentResult("SUCCESS");
        } else if (status.toUpperCase().contains("PENDING")) {
        } else if (status.toUpperCase().contains("EXPIRED")) {
        } else if (status.toUpperCase().contains("PROCESSING")) {
        } else if (status.toUpperCase().contains("FAILED")) {
          job?.cancel(); // Dart does not have a direct equivalent of this line
        }
      } else {
        print("Request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error occurred: $e");
    }
  }
}
