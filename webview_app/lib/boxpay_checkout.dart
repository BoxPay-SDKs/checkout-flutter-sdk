import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_app/payment_result_object.dart';
import 'package:webview_app/webview_page.dart';

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
    final merchantDetails = extractMerchantDetails(responseData);
    final backurl = extractBackURL(responseData);
    await storeMerchantDetailsAndReturnUrlInSharedPreferences(
        merchantDetails, backurl);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => WebViewPage(
          token: token,
          onPaymentResult: onPaymentResult,
          env: env,
        ),
      ),
    );
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
    String beckurl,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final merchantDetailsJson = jsonEncode(merchantDetails);
    await prefs.setString('merchant_details', merchantDetailsJson);
    await prefs.setString('backurl', beckurl);
  }
}
