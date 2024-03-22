import 'package:flutter/material.dart';
import 'package:webview_app/custom_appbar.dart';
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
  late WebViewController _controller;
  String currentUrl = '';

  @override
  void initState() {
    super.initState();
    startFunctionCalls();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (currentUrl !=
            'https://test-checkout.boxpay.tech/?token=${widget.token}&hui=fmani&hmh=yes') {
          currentUrl =
              'https://test-checkout.boxpay.tech/?token=${widget.token}&hui=fmani&hmh=yes';
          _controller.loadUrl(
              'https://test-checkout.boxpay.tech/?token=${widget.token}&hui=fmani&hmh=yes');
          return false;
        } else {
          Navigator.of(context).pop();
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: const CustomAppBar(title: 'Checkout'),
        body: SafeArea(
          child: WebView(
            initialUrl:
                'https://test-checkout.boxpay.tech/?token=${widget.token}&hui=fmani&hmh=yes',
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
              currentUrl =
                  'https://test-checkout.boxpay.tech/?token=${widget.token}&hui=fmani&hmh=yes';
            },
            javascriptMode: JavascriptMode.unrestricted,
            navigationDelegate: (NavigationRequest request) {
              currentUrl = request.url;
              return NavigationDecision.navigate;
            },
          ),
        ),
      ),
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
      job = null;
    }
  }

  void fetchStatusAndReason(String url) async {
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        var status = jsonResponse["status"];
        var statusReason = jsonResponse["statusReason"];
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
      } else {}
    } catch (e) {
      print("Error occurred: $e");
    }
  }
}
