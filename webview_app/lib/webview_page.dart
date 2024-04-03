import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_app/custom_appbar.dart';
import 'package:webview_app/dialogs/redirect_modal.dart';
import 'package:webview_app/payment_result_object.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

Timer? job;
bool isFlagSet = false;

class WebViewPage extends StatefulWidget {
  final String token;
  final Function(PaymentResultObject) onPaymentResult;
  final String env;

  const WebViewPage(
      {super.key,
      required this.token,
      required this.onPaymentResult,
      required this.env});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _controller;
  String currentUrl = '';
  late String backUrl = '';

  @override
  void initState() {
    super.initState();
    startFunctionCalls();
    isFlagSet = false;
    fetchReturnUrl();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (currentUrl.contains(backUrl) ||
            currentUrl.contains('privacy') || currentUrl.contains('terms-conditions')) {
          return redirectModal(context,
              title: "Confirmation",
              content: "Are you sure you want to go back?",
              noButtonText: "Exit Anyway",
              yesButtonText: "Stay", onYesPressed: (Completer<bool> completer) {
            completer.complete(false);
          }, onNoPressed: (Completer<bool> completer) {
            currentUrl =
                'https://${widget.env}checkout.boxpay.tech/?token=${widget.token}&hui=1&hmh=1';
            _controller.loadUrl(currentUrl);
            completer.complete(false);
          });
        } else if (!currentUrl.contains('hmh') || !currentUrl.contains('hui')) {
          return redirectModal(context,
              title: "Cancel Payment",
              content:
                  "Your payment is ongoing. Are you sure you want to cancel the payment in between?",
              noButtonText: "No",
              yesButtonText: "Yes, cancel",
              onNoPressed: (Completer<bool> completer) {
            completer.complete(false);
            stopFunctionCalls();
          }, onYesPressed: (Completer<bool> completer) {
            currentUrl =
                'https://${widget.env}checkout.boxpay.tech/?token=${widget.token}&hui=1&hmh=1';
            _controller.loadUrl(currentUrl);
            completer.complete(false);
          });
        } else {
          Navigator.of(context).pop();
          stopFunctionCalls();
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: const CustomAppBar(title: 'Checkout'),
        body: SafeArea(
          child: WebView(
            initialUrl:
                'https://${widget.env}checkout.boxpay.tech/?token=${widget.token}&hui=1&hmh=1',
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
              currentUrl =
                  'https://${widget.env}checkout.boxpay.tech/?token=${widget.token}&hui=1&hmh=1';
            },
            onPageStarted: (String url) {
              setState(() {
                currentUrl = url;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                currentUrl = url;
              });
            },
            javascriptMode: JavascriptMode.unrestricted,
            navigationDelegate: (NavigationRequest request) async {
              currentUrl = request.url;
              if (currentUrl.contains("pns")) {
                handlePaymentFailure(context);
              } else if (currentUrl == 'https://www.boxpay.tech/') {
                currentUrl =
                    'https://${widget.env}checkout.boxpay.tech/?token=${widget.token}&hui=1&hmh=1';
                await _controller.loadUrl(currentUrl);
                return NavigationDecision.prevent;
              } else if (currentUrl.contains(backUrl)) {
                Navigator.of(context).pop();
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        ),
      ),
    );
  }

  void startFunctionCalls() {
    job = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      fetchStatusAndReason(
          "https://${widget.env}apis.boxpay.tech/v0/checkout/sessions/${widget.token}/status");
    });
  }

  void stopFunctionCalls() {
    if (job != null) {
      job!.cancel();
      job = null;
    }
  }

  void handlePaymentFailure(BuildContext context) {
    if (!isFlagSet &&
        (currentUrl.contains("pns") || !currentUrl.contains("hui"))) {
      isFlagSet = true;
      stopFunctionCalls();
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Stack(
            children: <Widget>[
              // Blank white overlay
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
            ],
          );
        },
      );
      redirectModal(
        context,
        title: "Payment Failed",
        content: "Do you want to retry?",
        noButtonText: "Exit",
        yesButtonText: "Retry",
        onYesPressed: (Completer<bool> completer) async {
          stopFunctionCalls();
          currentUrl =
              'https://${widget.env}checkout.boxpay.tech/?token=${widget.token}&hui=1&hmh=1';
          await _controller.loadUrl(currentUrl);
          startFunctionCalls();
          Future.delayed(const Duration(seconds: 1), () {
            isFlagSet = false;
            Navigator.of(context).pop();
          });
          completer.complete(true);
        },
        onNoPressed: (Completer<bool> completer) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          completer.complete(false);
        },
      );
    }
  }

  Future<void> fetchReturnUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      backUrl = prefs.getString('backurl') ?? '';
    });
  }

  void fetchStatusAndReason(String url) async {
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        var status = jsonResponse["status"];
        var statusReason = jsonResponse["statusReason"];
        print("status: $status");
        if (status?.toUpperCase().contains("APPROVED") ||
            statusReason
                ?.toUpperCase()
                ?.contains("RECEIVED BY BOXPAY FOR PROCESSING") ||
            statusReason?.toUpperCase()?.contains("APPROVED BY PSP") ||
            status?.toUpperCase()?.contains("PAID")) {
          widget.onPaymentResult(PaymentResultObject("Success"));
          job?.cancel();
          stopFunctionCalls();
        } else if (status?.toUpperCase().contains("PENDING")) {
        } else if (status?.toUpperCase().contains("EXPIRED")) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    // Blank white overlay
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
                      title: const Text("Payment Session Expired"),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Please Click on EXIT to restart"),
                        ],
                      ),
                      actions: <Widget>[
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
              });
        } else if (status?.toUpperCase().contains("PROCESSING")) {
        } else if (status?.toUpperCase().contains("FAILED")) {
          // handlePaymentFailure(context);
        }
      } else {}
    } catch (e) {
      print("Error occurred: $e");
    }
  }
}
