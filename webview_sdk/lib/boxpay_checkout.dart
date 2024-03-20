import 'package:flutter/material.dart';
import 'package:webview_sdk/webview_page.dart';

class BoxPayCheckout {
  BuildContext context;
  String token;
  final Function(String) onPaymentResult;

  BoxPayCheckout(this.context, this.token, this.onPaymentResult);

  void display() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewPage(token: token, onPaymentResult: onPaymentResult ),
      ),
    );
  }

}
