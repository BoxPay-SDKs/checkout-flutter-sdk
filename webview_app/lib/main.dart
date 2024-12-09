import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:webview_app/boxpay_checkout.dart';
import 'package:webview_app/thank_you_page.dart';
import 'package:webview_app/payment_result_object.dart';
import 'package:webview_app/client.dart'; // Import the BoxPayCheckout class

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Checkout View',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const MyHomePage(), // Set MyHomePage as the home page
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedEnv = 'test';

  @override
  void dispose() {
    // Dispose the controller when the widget is disposed to avoid memory leaks
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller:
                    _amountController, // Assign the controller to the TextField
                decoration: const InputDecoration(
                  hintText:
                      'Enter token', // Placeholder text for the input field
                  border: OutlineInputBorder(), // Add border to the input field
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Radio<String>(
                  value: '',
                  groupValue: _selectedEnv,
                  onChanged: (value) {
                    setState(() {
                      _selectedEnv = value!;
                    });
                  },
                ),
                const Text('Prod'),
                Radio<String>(
                  value: 'sandbox',
                  groupValue: _selectedEnv,
                  onChanged: (value) {
                    setState(() {
                      _selectedEnv = value!;
                    });
                  },
                ),
                const Text('Sandbox'),
                Radio<String>(
                  value: 'test',
                  groupValue: _selectedEnv,
                  onChanged: (value) {
                    setState(() {
                      _selectedEnv = value!;
                    });
                  },
                ),
                const Text('Test'),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                BoxPayCheckout boxPayCheckout = BoxPayCheckout(
            context: context,
            token: _amountController.text,
            onPaymentResult: onPaymentResult,
            sandboxEnabled: _selectedEnv == "sandbox");
            boxPayCheckout.test = _selectedEnv == "test";
            boxPayCheckout.display();
              },
              child: const Text('Open Checkout by entering token'),
            ),
            ElevatedButton(
              onPressed: () {
                Client buffer = Client(context);
                _selectedEnv = "test";
                buffer.makePaymentRequest(null , "test");
              },
              child: const Text('Open Checkout by default token'),
            ),
          ],
        ),
      ),
    );
  }
  void onPaymentResult(PaymentResultObject object) {
    log("reuslt $object");
    if (object.status == "Success") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ThankYouPage()),
      );
    }
  }
}
