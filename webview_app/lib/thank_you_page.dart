import 'package:flutter/material.dart';
import 'package:boxpay_checkout_flutter_sdk/custom_appbar.dart';

class ThankYouPage extends StatelessWidget {
  const ThankYouPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(title: "Payment Completed"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Color.fromARGB(255, 1, 95, 4),
              size: 100,
            ),
            SizedBox(height: 20),
            Text(
              'Payment Completed',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
