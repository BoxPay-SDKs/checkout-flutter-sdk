import 'package:flutter/material.dart';
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

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Client buffer = Client(context);
            buffer.makePaymentRequest();
          },
          child: const Text('Open Checkout'),
        ),
      ),
    );
  }
}
