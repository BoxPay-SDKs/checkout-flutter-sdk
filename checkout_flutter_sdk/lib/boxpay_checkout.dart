import 'dart:async';
import 'package:boxpay_checkout_flutter_sdk/payment_result_object.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boxpay_checkout_flutter_sdk/webview_page.dart';
import 'package:appcheck/appcheck.dart';
import 'configuration_options.dart';

class BoxPayCheckout {
  final BuildContext context;
  final String token;
  String shopperToken;
  final Function(PaymentResultObject) onPaymentResult;
  final Map<ConfigurationOptions, dynamic>? configurationOptions;
  late String env;
  bool test = false;

  BoxPayCheckout({
    required this.context,
    required this.token,
    this.shopperToken = "",
    required this.onPaymentResult,
    this.configurationOptions,
  }) {
    // Determine the environment based on configuration options
    env = _getConfigurationValue(ConfigurationOptions.enableSandboxEnv, false)
        ? "sandbox-"
        : "";
  }

  Future<void> display() async {
    try {
      final responseData = await fetchSessionDataFromApi(token);
      final referrer = extractReferer(responseData);
      final merchantDetails = extractMerchantDetails(responseData);
      final backurl = extractBackURL(responseData);

      List<String> foundApps = [];

      bool isGpayInstalled = false;
      bool isPaytmInstalled = false;
      bool isPhonepeInstalled = false;

      if (Theme.of(context).platform == TargetPlatform.iOS) {
        // Check iOS URL schemes
        isGpayInstalled = await isAppInstalled('gpay');
        isPaytmInstalled = await isAppInstalled('paytmmp');
        isPhonepeInstalled = await isAppInstalled('phonepe');
      } else {
        // Check Android package names
        isGpayInstalled = await isAppInstalled('com.google.android.apps.nbu.paisa.user');
        isPaytmInstalled = await isAppInstalled('net.one97.paytm');
        isPhonepeInstalled = await isAppInstalled('com.phonepe.app');
      }

      if (isGpayInstalled) {
        foundApps.add("gp=1");
      }
      if (isPaytmInstalled) {
        foundApps.add("pm=1");
      }
      if (isPhonepeInstalled) {
        foundApps.add("pp=1");
      }

      // Check for `showUpiQrOnLoad` configuration
      if (_getConfigurationValue(ConfigurationOptions.showUpiQrOnLoad, false)) {
        foundApps.add("uq=1");
      }

      String upiApps = "";
      if (foundApps.isNotEmpty) {
        upiApps = foundApps.join('&');
      }

      await storeMerchantDetailsAndReturnUrlInSharedPreferences(
          merchantDetails, backurl);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => WebViewPage(
            token: token,
            onPaymentResult: onPaymentResult,
            env: env,
            upiApps: upiApps,
            referrer: referrer,
            shopperToken: shopperToken,
          ),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Invalid token or environment selected'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<bool> isAppInstalled(String packageName) async {
     final appCheck = AppCheck();
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // For iOS, we check if we can open the URL scheme
       final appInfo = await appCheck.checkAvailability("$packageName://") != null;
     return appInfo;
    } else {
      // For Android, we use AppChec
      return await appCheck.isAppInstalled(packageName);
    }
  }

  Future<String> fetchSessionDataFromApi(String token) async {
    env = test
        ? "test-"
        : (_getConfigurationValue(ConfigurationOptions.enableSandboxEnv, false)
            ? "sandbox-"
            : "");
    String domain = test
        ? "tech"
        : (_getConfigurationValue(ConfigurationOptions.enableSandboxEnv, false)
            ? "tech"
            : "in");
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

  Map<String, dynamic> extractMerchantDetails(String responseData) {
    final Map<String, dynamic> parsedData = jsonDecode(responseData);
    return parsedData['merchantDetails'];
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

  /// Helper method to retrieve configuration values with a default fallback
  T _getConfigurationValue<T>(ConfigurationOptions key, T defaultValue) {
    return configurationOptions?[key] as T? ?? defaultValue;
  }
}
