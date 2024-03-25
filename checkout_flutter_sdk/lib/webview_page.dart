import 'package:checkout_flutter_sdk/payment_result_object.dart';
import 'package:flutter/material.dart';
import 'package:checkout_flutter_sdk/custom_appbar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

Timer? job;
bool isFlagSet = false;

class WebViewPage extends StatefulWidget {
  final String token;
  final Function(PaymentResultObject) onPaymentResult;

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
    isFlagSet = false;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (!currentUrl.contains('hmh') || !currentUrl.contains('hui')) {
          currentUrl =
              'https://test-checkout.boxpay.tech/?token=${widget.token}&hui=1&hmh=1';
          _controller.loadUrl(
              'https://test-checkout.boxpay.tech/?token=${widget.token}&hui=1&hmh=1');
          return false;
        } else {
          Navigator.of(context).pop();
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: const CustomAppBar(title: 'Checkout'),
        body: SafeArea(
          child: WebView(
            initialUrl:
                'https://test-checkout.boxpay.tech/?token=${widget.token}&hui=1&hmh=1',
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
              currentUrl =
                  'https://test-checkout.boxpay.tech/?token=${widget.token}&hui=1&hmh=1';
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
    job = Timer.periodic(const Duration(milliseconds: 500), (Timer timer) async {
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

  void handlePaymentFailure(BuildContext context) {

  if (!isFlagSet && currentUrl.contains("pns")) {
    isFlagSet = true;
    stopFunctionCalls();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Stack(
          children: <Widget>[
            Container(
              color: Colors.white, 
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CustomAppBar(title: 'Checkout'),
            ),
            AlertDialog(
              title: const Text("Payment Failed"),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Do you want to retry?"),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _controller.loadUrl(
                        'https://test-checkout.boxpay.tech/?token=${widget.token}&hui=1&hmh=1');
                    currentUrl =
                        'https://test-checkout.boxpay.tech/?token=${widget.token}&hui=1&hmh=1';
                    startFunctionCalls();
                    isFlagSet = false;
                  },
                  child: const Text("Retry"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text("Exit"),
                ),
              ],
            ),
          ],
        );
      },
    );
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
          widget.onPaymentResult(PaymentResultObject("SUCCESS"));
          job?.cancel();
        } else if (status.toUpperCase().contains("PENDING")) {
        } else if (status.toUpperCase().contains("EXPIRED")) {
        } else if (status.toUpperCase().contains("PROCESSING")) {
        } else if (status.toUpperCase().contains("FAILED") && !isFlagSet) {
          handlePaymentFailure(context);
        }
      } else {}
    } catch (e) {
      print("Error occurred: $e");
    }
  }
}
