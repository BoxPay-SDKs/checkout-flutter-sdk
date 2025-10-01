import 'dart:math';

import 'package:boxpay_checkout_flutter_sdk/dialogs/redirect_modal.dart';
import 'package:boxpay_checkout_flutter_sdk/loader_sheet.dart';
import 'package:boxpay_checkout_flutter_sdk/payment_result_object.dart';
import 'package:flutter/material.dart';
import 'package:boxpay_checkout_flutter_sdk/custom_appbar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:core';
import 'package:url_launcher/url_launcher_string.dart';
import 'UPIAppDetector.dart';

Timer? job;
Timer? modalCheckTimer;
bool isFlagSet = false;

class WebViewPage extends StatefulWidget {
  final String token;
  final String shopperToken;
  final Function(PaymentResultObject) onPaymentResult;
  final String env;
  final bool isQREnabled;
  final String upiApps;
  final String referrer;

  const WebViewPage(
      {super.key,
      required this.token,
      this.shopperToken = "",
      required this.onPaymentResult,
      required this.env,
      required this.upiApps,
      required this.referrer,
      required this.isQREnabled});

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
  String statusFetched = "";
  String tokenFetched = "";
  bool shopperTokenFetched = false;

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

          // Inject and submit form if shopperToken is available
          if (widget.shopperToken.isNotEmpty && !shopperTokenFetched) {
            String formSubmissionScript = '''
            (function() {
              var form = document.createElement('form');
              form.action = '$baseUrl';
              form.method = 'POST';
              var input = document.createElement('input');
              input.type = 'hidden';
              input.name = 'shopper_token';
              input.value = '${widget.shopperToken}';
              form.appendChild(input);
              document.body.appendChild(form);
              form.submit();
            })();
          ''';
            shopperTokenFetched = true;
            _controller.runJavaScript(formSubmissionScript);
          }
        },
        onNavigationRequest: (NavigationRequest request) async {
          currentUrl = request.url;
          print("currentUrl : ${currentUrl}");
          if (currentUrl.contains("pns")) {
            // handlePaymentFailure(context);
          } else if (currentUrl.contains("pay?") && currentUrl.contains("pa")) {
            launchUPIIntentURL(currentUrl);
            return NavigationDecision.prevent;
          } else if (currentUrl.contains("mandate?")) {
            UPIAppDetector.launchMandate(currentUrl);
            return NavigationDecision.prevent;
          }else if (currentUrl == 'https://www.boxpay.tech/') {
            currentUrl = baseUrl;
            await _controller.loadRequest(
              Uri.parse(currentUrl),
              headers: headers,
            );
            return NavigationDecision.prevent;
          } else if (currentUrl.contains(backUrl)) {
            widget.onPaymentResult(
                PaymentResultObject(statusFetched, tokenFetched));
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

    if (widget.isQREnabled == true) {
        baseUrl += '&uq=1';
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
        } else if (currentUrl.contains('hmh')) {
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
            widget.onPaymentResult(
                PaymentResultObject(statusFetched, tokenFetched));
            completer.complete(true);
            Navigator.of(context).pop();
            return true;
          });
        } else {
          currentUrl = baseUrl;
          if (await _controller.canGoBack()) {
            _controller.goBack();
            return false;
          } else {
            widget.onPaymentResult(PaymentResultObject("NOACTION", ""));
            job?.cancel();
            stopFunctionCalls();
            Navigator.of(context).pop();
            return true;
          }
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
    job = Timer.periodic(const Duration(seconds: 3), (Timer timer) async {
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

  String generateRandomAlphanumericString(int length) {
    const String charPool =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final Random random = Random();
    return List.generate(
        length, (index) => charPool[random.nextInt(charPool.length)]).join();
  }

  void fetchStatusAndReason(String url) async {
    try {
      var response = await http.get(Uri.parse(url), headers: {
        'X-Trace-Id': generateRandomAlphanumericString(10),
      });
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        var status = jsonResponse["status"];
        var statusReason = jsonResponse["statusReason"];
        statusFetched = status;
        if (status?.toUpperCase() == "APPROVED" ||
            statusReason?.toUpperCase() ==
                "RECEIVED BY BOXPAY FOR PROCESSING" ||
            statusReason?.toUpperCase() == "APPROVED BY PSP" ||
            status?.toUpperCase() == "PAID") {
          tokenFetched = jsonResponse["transactionId"];
          widget.onPaymentResult(PaymentResultObject("Success", tokenFetched));
          job?.cancel();
          stopFunctionCalls();
        } else if (status?.toUpperCase() == "PENDING") {
        } else if (status?.toUpperCase() == "EXPIRED") {
          job?.cancel();
          stopFunctionCalls();
          redirectModal(
            context,
            title: "Payment Session Expired",
            content: "Please exit checkout",
            yesButtonText: "Exit",
            noButtonText: "",
            onYesPressed: (Completer<bool> completer) async {
              Navigator.of(context).pop();
              completer.complete(false);
              widget.onPaymentResult(
                  PaymentResultObject("Expired", tokenFetched));
            },
            onNoPressed: (Completer<bool> completer) {
              // no op
            },
          );
          tokenFetched = jsonResponse["transactionId"];
        } else if (status?.toUpperCase() == "FAILED") {
          tokenFetched = jsonResponse["transactionId"];
        }
      } else {
        // print("inside else");
      }
    } catch (e) {
      // print(e);
      // no op
    }
  }
}
