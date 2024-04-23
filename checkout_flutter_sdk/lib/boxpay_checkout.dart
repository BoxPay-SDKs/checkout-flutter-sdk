import 'dart:async';
import 'package:checkout_flutter_sdk/payment_result_object.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkout_flutter_sdk/webview_page.dart';

class BoxPayCheckout {
  final BuildContext context;
  final String token;
  final Function(PaymentResultObject) onPaymentResult;
  bool sandboxEnabled;
  String env;

  BoxPayCheckout(
      {required this.context,
      required this.token,
      required this.onPaymentResult,
      bool? sandboxEnabled})
      : sandboxEnabled = sandboxEnabled ?? false,
        env = sandboxEnabled == true ? "sandbox-" : "test-";

  Future<void> display() async {
    final responseData = await fetchSessionDataFromApi(token);
    final referrer = extractReferer(responseData);
    final merchantDetails = extractMerchantDetails(responseData);
    final backurl = extractBackURL(responseData);

    List<String> foundApps = [];

    final isGpayInstalled =
        await isAppInstalled('com.google.android.apps.nbu.paisa.user');
    final isPaytmInstalled = await isAppInstalled('net.one97.paytm');
    final isPhonepeInstalled = await isAppInstalled('com.phonepe.app');

    if (isGpayInstalled) {
      foundApps.add("gp=1");
    }
    if (isPaytmInstalled) {
      foundApps.add("pm=1");
    }
    if (isPhonepeInstalled) {
      foundApps.add("pp=1");
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
            referrer: referrer),
      ),
    );
  }

  Future<bool> isAppInstalled(String packageName) async {
    final bool isInstalled = await DeviceApps.isAppInstalled(packageName);
    return isInstalled;
  }

  Future<String> fetchSessionDataFromApi(String token) async {
    String apienv;
    if (sandboxEnabled) {
      apienv = "sandbox";
    } else {
      apienv = "test";
    }
    final apiUrl =
        'https://$apienv-apis.boxpay.tech/v0/checkout/sessions/$token';
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

}
