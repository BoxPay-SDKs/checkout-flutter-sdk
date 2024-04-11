import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoaderSheet extends StatelessWidget {
  const LoaderSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/BoxPayLogo.json'),
            const Text("Powered by Boxpay",
                style: TextStyle(
                  fontFamily: "poppins",
                  fontWeight: FontWeight.bold
                ))
          ],
        ),
      ),
    );
  }
}
