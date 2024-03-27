import 'dart:async';
import 'package:checkout_flutter_sdk/payment_result_object.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkout_flutter_sdk/webview_page.dart';

class BoxPayCheckout {
  final BuildContext context;
  final String token;
  final Function(PaymentResultObject) onPaymentResult;
  String env;

  BoxPayCheckout(
      {required this.context,
      required this.token,
      required this.onPaymentResult,
      String? env})
      : env = env ?? "test";

Future<void> display() async {
  final responseData = await fetchSessionDataFromApi(token);
  final merchantDetails = extractMerchantDetails(responseData);
  await storeMerchantDetailsInSharedPreferences(merchantDetails);

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
    final apiUrl =
        'https://${env}-apis.boxpay.tech/v0/checkout/sessions/$token';
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

  Future<void> storeMerchantDetailsInSharedPreferences(
      Map<String, dynamic> merchantDetails) async {
    final prefs = await SharedPreferences.getInstance();
    final merchantDetailsJson = jsonEncode(merchantDetails);
    await prefs.setString('merchant_details', merchantDetailsJson);
    print("merchantDetailsJson $merchantDetailsJson");
  }
}
