import 'package:flutter/material.dart';
import 'package:webview_app/webview_page.dart';

class BoxPayCheckout {
  BuildContext context;
  String token;

  BoxPayCheckout(this.context, this.token);

  void display() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewPage(token: token),
      ),
    );
  }
}
