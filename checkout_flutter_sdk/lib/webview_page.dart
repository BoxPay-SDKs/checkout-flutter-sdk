import 'package:checkout_flutter_sdk/dialogs/redirect_modal.dart';
import 'package:checkout_flutter_sdk/loader_sheet.dart';
import 'package:flutter/services.dart';
import 'package:checkout_flutter_sdk/payment_result_object.dart';
import 'package:flutter/material.dart';
import 'package:checkout_flutter_sdk/custom_appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:alt_sms_autofill/alt_sms_autofill.dart';
import 'dart:core';
import 'package:url_launcher/url_launcher.dart';

Timer? job;
Timer? otpTimer;
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
  String otp = '';
  bool _isFirstRender = true;
  bool _isIntentLaunch = false;
  late Map<String, String> headers;
  String baseUrl = "";
  bool _upiTimerModal = false;

  _WebViewPageState({required String referrer}) {
    headers = {
      // 'referrer': referrer,
      'Referer': referrer,
      'Origin': referrer
    };
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
    otp = '';
  }

  @override
  void dispose() {
    stopFunctionCalls();
    AltSmsAutofill().unregisterListener();
    otpTimer?.cancel();
    modalCheckTimer?.cancel();
    super.dispose();
  }

  void createBaseUrl() {
    if (widget.upiApps.isNotEmpty) {
      baseUrl =
          'https://${widget.env}checkout.boxpay.tech/?token=${widget.token}&hmh=1&${widget.upiApps}';
    } else {
      baseUrl =
          'https://${widget.env}checkout.boxpay.tech/?token=${widget.token}&hmh=1';
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
          }, onNoPressed: (Completer<bool> completer) {
            currentUrl = baseUrl;
            _controller.loadUrl(currentUrl, headers: headers);
            completer.complete(false);
          });
        } else if (_upiTimerModal && currentUrl.contains('hmh')) {
          currentUrl = baseUrl;
          _controller.loadUrl(currentUrl, headers: headers);
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
          }, onYesPressed: (Completer<bool> completer) {
            currentUrl = baseUrl;
            _controller.loadUrl(currentUrl, headers: headers);
            completer.complete(false);
            otpTimer?.cancel();
            initSmsListener();
          });
        } else {
          Navigator.of(context).pop();
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: const CustomAppBar(title: 'Checkout'),
        body: SafeArea(
          child: Stack(
            children: [
              WebView(
                onWebViewCreated: (WebViewController webViewController) {
                  webViewController.loadUrl(baseUrl, headers: headers);
                  _controller = webViewController;
                  currentUrl = baseUrl;
                  initSmsListener();
                },
                javascriptChannels: <JavascriptChannel>{
                  JavascriptChannel(
                      name: 'otpMessage',
                      onMessageReceived: (JavascriptMessage message) {
                        if (message.message == "Success") {
                          otpTimer!.cancel();
                        }
                      }),
                  JavascriptChannel(
                      name: 'upiTimerModal',
                      onMessageReceived: (JavascriptMessage message) {
                        if (message.message == "true") {
                          setState(() {
                            _upiTimerModal = true;
                          });
                        } else {
                          setState(() {
                            _upiTimerModal = false;
                          });
                        }
                      }),
                },
                onPageStarted: (String url) {
                  setState(() {
                    currentUrl = url;
                  });
                },
                onPageFinished: (String url) async {
                  setState(() {
                    currentUrl = url;
                  });
                  await Future.delayed(const Duration(milliseconds: 200));
                  setState(() {
                    _isFirstRender = false;
                  });
                },
                javascriptMode: JavascriptMode.unrestricted,
                navigationDelegate: (NavigationRequest request) async {
                  currentUrl = request.url;
                  if (currentUrl.contains("pns")) {
                    handlePaymentFailure(context);
                  } else if (currentUrl.contains("pay?") &&
                      currentUrl.contains("pa")) {
                    launchUPIIntentURL(currentUrl);
                    return NavigationDecision.prevent;
                  } else if (currentUrl == 'https://www.boxpay.tech/') {
                    currentUrl = baseUrl;
                    await _controller.loadUrl(currentUrl, headers: headers);
                    return NavigationDecision.prevent;
                  } else if (currentUrl.contains(backUrl)) {
                    Navigator.of(context).pop();
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ),
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
    // ignore: deprecated_member_use
    if (await canLaunch(upiURL)) {
      // ignore: deprecated_member_use
      await launch(upiURL);
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
      if (currentUrl.contains("hmh"))
      {
        // ignore: deprecated_member_use
        await _controller.evaluateJavascript('''
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

  void initSmsListener() async {
    String? comingSms;
    try {
      comingSms = await AltSmsAutofill().listenForSms;
    } on PlatformException {
      comingSms = 'Failed to get Sms.';
    }
    if (!mounted || comingSms == null) return;

    if (comingSms.isNotEmpty) {
      RegExp regex = RegExp(r'\b\d{6}\b');
      Iterable<Match> matches = regex.allMatches(comingSms);

      if (matches.isNotEmpty) {
        otp = matches.first.group(0)!;
        _injectOtp();
      }
    }
  }

  void _injectOtp() {
    otpTimer = Timer.periodic(const Duration(seconds: 2), (Timer timer) async {
      if (otp.isNotEmpty) {
        // ignore: deprecated_member_use
        await _controller.evaluateJavascript('''
            var inputField = document.querySelector('input');
            var submitButton = document.querySelector('button[type="submit"]');

            if (inputField) {
                inputField.value = '$otp';

                if (submitButton) {
                    if (submitButton.disabled) {
                        submitButton.disabled = false;
                    }
                    submitButton.click();
                  setTimeout(function() {
                    window.otpMessage.postMessage('Success');
                  }, 1700); 
                }
            } else {
            }
        ''');
      }
    });
  }

  void startFunctionCalls() {
    job = Timer.periodic(const Duration(seconds: 2), (Timer timer) async {
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
        (currentUrl.contains("pns") || !currentUrl.contains("hmh"))) {
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
          currentUrl = baseUrl;
          await _controller.loadUrl(currentUrl, headers: headers);
          startFunctionCalls();
          Future.delayed(const Duration(seconds: 1), () {
            isFlagSet = false;
            Navigator.of(context).pop();
          });
          completer.complete(true);
          otpTimer?.cancel();
          initSmsListener();
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
