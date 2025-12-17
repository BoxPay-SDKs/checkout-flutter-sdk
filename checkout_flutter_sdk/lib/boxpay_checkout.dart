import 'dart:async';
import 'package:boxpay_checkout_flutter_sdk/payment_result_object.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boxpay_checkout_flutter_sdk/webview_page.dart';
import 'configuration_options.dart';
import 'UPIAppDetector.dart';
import 'swipe_to_pay.dart';
import 'boxpay_3ds_page.dart';
import 'dart:math'; // Make sure to import this at the top


class BoxPayCheckout {
  final BuildContext context;
  final String token;
  String shopperToken;
  final Function(PaymentResultObject) onPaymentResult;
  final Map<ConfigurationOptions, dynamic>? configurationOptions;
  late String env;
  late String domain;
  late bool isQREnabled;

  BoxPayCheckout({
    required this.context,
    required this.token,
    this.shopperToken = "",
    required this.onPaymentResult,
    this.configurationOptions,
  }) {
    env = _getConfigurationValue(ConfigurationOptions.enableSandboxEnv, false)
        ? "test-"
        : "";
    domain = _getConfigurationValue(ConfigurationOptions.enableSandboxEnv, false)
        ? "tech"
        : "in";
    isQREnabled =
        _getConfigurationValue(ConfigurationOptions.showUpiQrOnLoad, false);
  }

  Future<void> display() async {
    try {
      // 1. Fetch Session Data
      final responseData = await fetchSessionDataFromApi(token);
      final referrer = extractReferer(responseData);
      final merchantDetails = extractMerchantDetails(responseData);
      final backurl = extractBackURL(responseData);
      final shopperDetails = extractShopperDetails(responseData);
      
      // 2. Prepare UPI Data
      final upiApps = await UPIAppDetector.getInstalledUpiApps();
      List<String> foundApps = [];
      if (upiApps.contains("gpay")) foundApps.add("gp=1");
      if (upiApps.contains("paytm")) foundApps.add("pm=1");
      if (upiApps.contains("phonepe")) foundApps.add("pp=1");
      String upiAppsString = foundApps.join('&');

      await storeMerchantDetailsAndReturnUrlInSharedPreferences(merchantDetails, backurl);

      // 3. FETCH RECOMMENDED INSTRUMENTS
      // Only attempt if we have a shopperToken (usually required for saved cards)
      Map<String, dynamic>? recommendedInstrument;
      if (shopperToken.isNotEmpty) {
        try {
          String uniqueRef = extractUniqueRef(responseData);
          recommendedInstrument = await fetchRecommendedInstruments(uniqueRef);
        } catch (e) {
          // print("Failed to fetch recommended instruments: $e");
          // Fail silently and proceed to Webview
        }
      }

      // 4. LOGIC: Show Swipe UI OR Go to WebView
      if (recommendedInstrument != null && recommendedInstrument.isNotEmpty) {
        // Show the native Swipe to Pay UI
        final merchantSettingsButtonColor = merchantDetails['checkoutTheme']['primaryButtonColor'] ?? Color(0xFF000000);
        final buttonColor = Color(
              int.parse(merchantSettingsButtonColor.substring(1, 7), radix: 16) + 0xFF000000);
        _showSwipeToPayModal(
          instrument: recommendedInstrument,
          merchantColor: buttonColor,
          amount: extractAmount(responseData),
          upiApps: upiAppsString,
          referrer: referrer,
          shopperDetails: shopperDetails
        );
      } else {
        // No saved card? Go straight to WebView
        _navigateToWebView(upiAppsString, referrer);
      }
    } catch (e) {
      print("Critical error: $e");
      _showErrorDialog();
    }
  }

  // --- API CALLS ---

  Future<String> fetchSessionDataFromApi(String token) async {
    final apiUrl =
        'https://${env}apis.boxpay.$domain/v0/checkout/sessions/$token';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to load session data');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server');
    }
  }

  /// New API call to fetch saved/recommended instruments
  Future<Map<String, dynamic>?> fetchRecommendedInstruments(String uniqueRef) async {
    final apiUrl =
        'https://${env}apis.boxpay.$domain/v0/checkout/sessions/$token/shoppers/$uniqueRef/recommended-instruments'; 
        // Note: verify the actual endpoint for recommended instruments with BoxPay docs
    
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': "Session $shopperToken",
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
  final data = jsonDecode(response.body);

  // Check if data is a list and not empty
  if (data != null && data is List && data.isNotEmpty) {
    
    // Look for the first instrument where the type is 'Card'
    final cardInstrument = data.firstWhere(
      (instrument) => instrument['type'] == 'Card', 
      orElse: () => null,
    );

    if (cardInstrument != null) {
      print("Found Saved Card: $cardInstrument");
      return cardInstrument;
    }
  }
  // If no card is found (e.g., only UPI exists), return null
  return null;
      }
    } catch (e) {
      print("Error fetching recommended: $e");
    }
    return null;
  }

  /// Process payment for the Swipe Action
  Future<void> processSavedInstrumentPayment(String instrumentRef, Map<String, dynamic> shopperDetails) async {
    // 1. Define the Endpoint (Based on your CURL, it targets the session directly)
    final apiUrl = 'https://${env}apis.boxpay.$domain/v0/checkout/sessions/$token';
    
    // 2. Prepare Headers
    // Note: We generate a unique ID for the request and use the Session Token for auth
    final Map<String, String> headers = {
      'X-Request-Id': _generateRandomRequestId(),
      'Authorization': 'Session $shopperToken',
      'Content-Type': 'application/json'
    };


    final Map<String, dynamic> body = {
      "browserData": {
        "screenHeight": MediaQuery.of(context).size.height.toInt().toString(),
        "screenWidth": MediaQuery.of(context).size.width.toInt().toString(),
        "acceptHeader": "application/json",
        "userAgentHeader": "Flutter-SDK/1.0 (Android)", // You can fetch real UserAgent if needed
        "browserLanguage": "en_US",
        "ipAddress": null, // The server usually detects this automatically
        "colorDepth": 24,
        "javaEnabled": true,
        "timeZoneOffSet": DateTime.now().timeZoneOffset.inMinutes,
        "packageId": "com.boxpay.checkout.flutter" // Replace with actual package ID
      },
      "instrumentDetails": {
        "type": "card/token",
        "savedCard": {
          "instrumentRef": instrumentRef // <--- The token from the Swipe UI
        }
      },
      "shopper" : shopperDetails,
      "deviceDetails": {
        "browser": "Flutter App",
        "platformVersion": "13", // Use 'device_info_plus' to get real version
        "deviceType": "Mobile",
        "deviceName": "Android Device",
        "deviceBrandName": "Generic"
      }
    };

    try {
      // 4. Make the API Call
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint("Payment Response Status: ${response.statusCode}");
      debugPrint("Payment Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        
        String? htmlContent;
        String? redirectUrl;
        String? transactionRequest;

        // 1. Check for "RequiresAction" status
        final statusObj = result['status'];
        if (statusObj != null && statusObj['status'] == 'RequiresAction') {
            
            // 2. Check Actions Array
            if (result['actions'] != null && (result['actions'] as List).isNotEmpty) {
                final action = result['actions'][0];
                
                // Case A: Type is HTML (The JSON you provided)
                if (action['type'] == 'html') {
                    htmlContent = action['htmlPageString'];
                } 
                // Case B: Type is URL/Redirect (Just in case)
                else if (action['type'] == 'url') {
                    redirectUrl = action['url'];
                    if (action['data'] != null) {
                        transactionRequest = action['data']['txnreq'].toString();
                    }
                }
            }
        }

        // --- NAVIGATION LOGIC ---

        if (htmlContent != null || redirectUrl != null) {
          
          // Open 3DS Page and wait for result
          final navResult = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BoxPay3DSPage(
                htmlContent: htmlContent, // This contains your form
                redirectUrl: redirectUrl,
                transactionRequest: transactionRequest,
              ),
            ),
          );

          // Handle Polling Result
         if (navResult == "completed") {
            
             final statusData = await fetchTransactionStatus();
             final finalStatus = statusData['status'];
             final transactionId = statusData['transactionId']?.toString() ?? "";

             if (finalStatus == 'PAID' || finalStatus == 'SUCCESS' || finalStatus == 'APPROVED') {
                onPaymentResult(PaymentResultObject("Success", transactionId));
             } else {
                throw Exception("Payment Status: $finalStatus");
             }

          } else {
             // User pressed 'X' or Back
             throw Exception("Payment Cancelled by user");
          }
        } else {
          // No Action Required? Assume direct success (Frictionless)
          debugPrint("No 3DS Action required. Success.");
          Navigator.of(context).pop("success");
          onPaymentResult(PaymentResultObject("Success", result));
        }
      } else {
        // 6. Handle API Errors
        _showPaymentFailedDialog();
        throw Exception("Payment failed with status: ${response.statusCode}");
      }
    } catch (e) {
      _showPaymentFailedDialog();
      throw e;

      // Optionally show an error dialog here
    }
  }

  // --- NAVIGATION & UI ---

  void _navigateToWebView(String upiApps, String referrer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => WebViewPage(
          token: token,
          onPaymentResult: onPaymentResult,
          env: env,
          isQREnabled: isQREnabled,
          upiApps: upiApps,
          referrer: referrer,
          shopperToken: shopperToken,
        ),
      ),
    );
  }

  void _showSwipeToPayModal({
    required Map<String, dynamic> instrument,
    required Color merchantColor,
    required String amount,
    required String upiApps,
    required String referrer,
    required Map<String, dynamic> shopperDetails
  }) {

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SwipeToPaySheet(
          amount: amount,
          last4: instrument['displayValue'] ?? '****',
          logoUrl: instrument['logoUrl'] ?? "",
          merchantColor: merchantColor,
          onSwipeCompleted: () async {
            try {
              // Call the payment API
              await processSavedInstrumentPayment(instrument['instrumentRef'] ?? '', shopperDetails);
            } catch (e) {
              throw e;
            }
          },
          onMoreOptions: () {
            Navigator.of(context).pop(); // Close sheet
            _navigateToWebView(upiApps, referrer); // Fallback to WebView
          },
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('An error occurred. Please try again.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentFailedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Failed'),
          content: const Text('Please retry using other payment method or try again in sometime'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  // --- HELPERS ---

  String extractAmount(String responseData) {
    // Helper to get amount string for display
    final Map<String, dynamic> parsedData = jsonDecode(responseData);
    final amount = parsedData['paymentDetails']['money']['amountLocale'];
    final currency = parsedData['paymentDetails']['money']['currencySymbol'];
    return "$currency$amount";
  }

  String extractUniqueRef(String responseData) {
    // Helper to get amount string for display
    final Map<String, dynamic> parsedData = jsonDecode(responseData);
    final uniqueRef = parsedData['paymentDetails']['shopper']['uniqueReference'];
    return "$uniqueRef";
  }

  Map<String, dynamic> extractMerchantDetails(String responseData) {
    final Map<String, dynamic> parsedData = jsonDecode(responseData);
    final Map<String, dynamic> merchantDetails = parsedData['merchantDetails'];
    bool merchantLogoVisible = false;

    if (parsedData['configs'] != null &&
        parsedData['configs']['enabledFields'] != null &&
        parsedData['configs']['enabledFields'] is List) {
      final List<dynamic> enabledFields = parsedData['configs']['enabledFields'];
      merchantLogoVisible = enabledFields.any(
        (field) => field['field'] == 'MERCHANT_LOGO',
      );
    }
    merchantDetails['merchantLogoVisible'] = merchantLogoVisible;
    return merchantDetails;
  }

  Map<String, dynamic> extractShopperDetails(String responseData) {
    final Map<String, dynamic> parsedData = jsonDecode(responseData);
    final Map<String, dynamic> shopperDetails = parsedData['paymentDetails']['shopper'];

    return shopperDetails;
  }

  String extractBackURL(String responseData) {
    final Map<String, dynamic> parsedData = jsonDecode(responseData);
    return parsedData['paymentDetails']['frontendBackUrl'];
  }

  Future<void> storeMerchantDetailsAndReturnUrlInSharedPreferences(
    Map<String, dynamic> merchantDetails,
    String backurl,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final merchantDetailsJson = jsonEncode(merchantDetails);
    await prefs.setString('merchant_details', merchantDetailsJson);
    await prefs.setString('backurl', backurl);
  }

  String extractReferer(String responseData) {
    final Map<String, dynamic> parsedData = jsonDecode(responseData);
    final List<dynamic> referers = parsedData['configs']['referrers'];
    if (referers.isNotEmpty) {
      return referers[0];
    }
    return '';
  }

  T _getConfigurationValue<T>(ConfigurationOptions key, T defaultValue) {
    return configurationOptions?[key] as T? ?? defaultValue;
  }

  String _generateRandomRequestId({int length = 10}) {
  const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random rnd = Random();
  
  return String.fromCharCodes(Iterable.generate(
    length, 
    (_) => chars.codeUnitAt(rnd.nextInt(chars.length))
  ));
}

Future<Map<String, dynamic>> fetchTransactionStatus() async {
    final apiUrl = 'https://${env}apis.boxpay.$domain/v0/checkout/sessions/$token/status';
    
    debugPrint("Fetching final status from: $apiUrl");
    
    final response = await http.get(Uri.parse(apiUrl));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch status: ${response.statusCode}");
    }
  }
}