import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_app/custom_appbar.dart';
import 'package:webview_app/dialogs/redirect_modal.dart';
import 'package:webview_app/loader_sheet.dart';
import 'package:webview_app/payment_result_object.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:core';
import 'package:url_launcher/url_launcher_string.dart';

Timer? job;
Timer? modalCheckTimer;
bool isFlagSet = false;

class WebViewPage extends StatefulWidget {
  final String token;
  final Function(PaymentResultObject) onPaymentResult;
  final String env;
  final String upiApps;
  final String referrer;

  const WebViewPage(
      {super.key,
      required this.token,
      required this.onPaymentResult,
      required this.env,
      required this.upiApps,
      required this.referrer});

  @override
  State<WebViewPage> createState() => _WebViewPageState(referrer: referrer);
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _controller;
  String currentUrl = '';
  late String backUrl = '';
  bool _isFirstRender = true;
  bool _isIntentLaunch = false;
  late Map<String, String> headers;
  String baseUrl = "";
  bool _upiTimerModal = false;

  _WebViewPageState({required String referrer}) {
    headers = {'Referer': referrer, 'Origin': referrer};
  }

  @override
  void initState() {
    super.initState();
    createBaseUrl();
    startFunctionCalls();
    isFlagSet = false;
    _isFirstRender = true;
    fetchReturnUrl();
    timerModalListener();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (String url) {
          setState(() {
            currentUrl = url;
          });
        },
        onPageFinished: (String url) {
          setState(() {
            currentUrl = url;
          });
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() {
              _isFirstRender = false;
            });
          });
        },
        onNavigationRequest: (NavigationRequest request) async {
          currentUrl = request.url;
          if (currentUrl.contains("pns")) {
            // handlePaymentFailure(context);
          } else if (currentUrl.contains("pay?") && currentUrl.contains("pa")) {
            launchUPIIntentURL(currentUrl);
            return NavigationDecision.prevent;
          } else if (currentUrl == 'https://www.boxpay.tech/') {
            currentUrl = baseUrl;
            await _controller.loadRequest(
              Uri.parse(currentUrl),
              headers: headers,
            );
            return NavigationDecision.prevent;
          } else if (currentUrl.contains(backUrl)) {
            Navigator.of(context).pop();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
    _controller.loadRequest(Uri.parse(baseUrl), headers: headers);
  }

  @override
  void dispose() {
    stopFunctionCalls();
    modalCheckTimer?.cancel();
    super.dispose();
  }

  void createBaseUrl() {
    String domain;
    if (widget.env == "sandbox-" || widget.env == "test-") {
      domain = "tech";
    } else {
      domain = "in";
    }

    if (widget.upiApps.isNotEmpty) {
      baseUrl =
          'https://${widget.env}checkout.boxpay.${domain}/?token=${widget.token}&hmh=1&${widget.upiApps}';
    } else {
      baseUrl =
          'https://${widget.env}checkout.boxpay.${domain}/?token=${widget.token}&hmh=1';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
               if (currentUrl.contains(backUrl) ||
            currentUrl.contains('privacy') ||
            currentUrl.contains('terms-conditions')) {
          return redirectModal(context,
              title: "Confirmation",
              content: "Are you sure you want to go back?",
              noButtonText: "Exit Anyway",
              yesButtonText: "Stay", onYesPressed: (Completer<bool> completer) {
            completer.complete(false);
          }, onNoPressed: (Completer<bool> completer) async {
            currentUrl = baseUrl;
            if (await _controller.canGoBack()) {
              _controller.goBack();
            }
            completer.complete(false);
          });
        } else if (_upiTimerModal && currentUrl.contains('hmh')) {
          currentUrl = baseUrl;
          _controller.loadRequest(
                  Uri.parse(currentUrl),
                  headers: headers,
                );
          setState(() {
            _upiTimerModal = false;
          });
          return false;
        } else if (!currentUrl.contains('hmh')) {
          return redirectModal(context,
              title: "Cancel Payment",
              content:
                  "Your payment is ongoing. Are you sure you want to cancel the payment in between?",
              noButtonText: "No",
              yesButtonText: "Yes, cancel",
              onNoPressed: (Completer<bool> completer) {
            completer.complete(false);
          }, onYesPressed: (Completer<bool> completer) async {
            currentUrl = baseUrl;
            if (await _controller.canGoBack()) {
              _controller.goBack();
            }
            completer.complete(false);
          });
        } else {
          Navigator.of(context).pop();
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: const CustomAppBar(title: 'Checkout'),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isFirstRender || _isIntentLaunch)
                const Center(
                  child: LoaderSheet(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void launchUPIIntentURL(String upiURL) async {
    if (await canLaunchUrlString(upiURL)) {
      await launchUrlString(upiURL);
      setState(() {
        _isIntentLaunch = true;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      while (
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      currentUrl = baseUrl;
      setState(() {
        _isIntentLaunch = false;
      });
    } else {
      throw 'Could not launch $upiURL';
    }
  }

  void timerModalListener() {
    modalCheckTimer =
        Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      if (currentUrl.contains("hmh")) {
        // ignore: deprecated_member_use
        await _controller.runJavaScript('''
              var modal = document.querySelector('.upiModal');

              if(modal){
                setTimeout(function() {
                    window.upiTimerModal.postMessage('true');
                  }, 500);
              }else{
                setTimeout(function() {
                    window.upiTimerModal.postMessage('false');
                  }, 500);
              }
        ''');
      }
    });
  }

  void startFunctionCalls() {
    String domain = "tech";
    if (widget.env == "") {
      domain = "in";
    }
    job = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      fetchStatusAndReason(
          "https://${widget.env}apis.boxpay.$domain/v0/checkout/sessions/${widget.token}/status");
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
        (currentUrl.contains("pns") || !currentUrl.contains("hmh"))) {
      isFlagSet = true;
      stopFunctionCalls();
      showDialog(
        context: context,
        barrierDismissible: true,
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
          currentUrl = baseUrl;
          await _controller.loadRequest(
                  Uri.parse(currentUrl),
                  headers: headers,
                );
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
        }
      } else {}
    } catch (e) {
      print("Error occurred: $e");
    }
  }
}
