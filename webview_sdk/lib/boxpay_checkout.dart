import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_sdk/webview_page.dart';

class BoxPayCheckout {
  BuildContext context;
  String token;
  final Function(String) onPaymentResult;

  BoxPayCheckout(this.context, this.token, this.onPaymentResult);

  Future<void> display() async {
    final responseData = await fetchSessionDataFromApi(token);
    final merchantDetails = extractMerchantDetails(responseData);
    await storeMerchantDetailsInSharedPreferences(merchantDetails);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async {
            return (await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel Payment'),
                    content: const Text(
                        'Your paymnet is ongoing. Are you sure you want to cancel the payment in between?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes, Cancel'),
                      ),
                    ],
                  ),
                )) ??
                false;
          },
          child: WebViewPage(token: token, onPaymentResult: onPaymentResult),
        );
      },
    );
  }

  Future<String> fetchSessionDataFromApi(String token) async {
    final apiUrl = 'https://test-apis.boxpay.tech/v0/checkout/sessions/$token';

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
