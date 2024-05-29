import 'package:flutter/material.dart';

class LoaderSheet extends StatelessWidget {
  const LoaderSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(), // Loading circle
            SizedBox(height: 20),
            Text("Powered by Boxpay",
                style: TextStyle(
                    fontFamily: "poppins", fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}
