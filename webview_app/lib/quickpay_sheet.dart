import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickpayBottomSheet extends StatefulWidget {
  final VoidCallback onClose;

  const QuickpayBottomSheet({Key? key, required this.onClose})
      : super(key: key);

  @override
  _QuickpayBottomSheetState createState() => _QuickpayBottomSheetState();
}

class _QuickpayBottomSheetState extends State<QuickpayBottomSheet> {
  late Future<String> _merchantDetailsFuture;
  late Map<String, dynamic> _merchantDetails;

  @override
  void initState() {
    super.initState();
    _merchantDetailsFuture = _getMerchantDetailsFromSharedPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _merchantDetailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while fetching data
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // Handle error case
          return Text('Error: ${snapshot.error}');
        } else {
          // Data has been successfully fetched
          _merchantDetails = jsonDecode(snapshot.data!);
          final buttonColorValue =
              _merchantDetails['checkoutTheme']['primaryButtonColor'];
          final buttonColor = Color(
              int.parse(buttonColorValue.substring(1, 7), radix: 16) + 0xFF000000);
          final headerTextColorValue =
              _merchantDetails['checkoutTheme']['headerTextColor'];
              final headerTextColor = Color(
              int.parse(headerTextColorValue.substring(1, 7), radix: 16) + 0xFF000000);
          final font = _merchantDetails['checkoutTheme']['font'] ?? "Poppins";
          return Padding(
            padding: const EdgeInsets.all(16.0), // Adjust padding as needed
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.only(
                  topLeft:
                      Radius.circular(20.0), // Adjust border radius as needed
                  topRight:
                      Radius.circular(20.0), // Adjust border radius as needed
                ),
              ),
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      "Pay Using",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.18,
                        color: Colors.black, // Set text color here
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text("Payment Method"),
                        TextButton(
                            onPressed: widget.onClose,
                            child: const Text("change")),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double
                          .infinity, // Make the button take the full width
                      child: ElevatedButton(
                        onPressed: widget.onClose,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                          // padding: EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: buttonColor,
                        ),
                        child: Text('Proceed payment', style: TextStyle(
      color: headerTextColor, // Set the text color
      fontFamily: font,
    ),),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Future<String> _getMerchantDetailsFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('merchant_details') ?? '';
  }
}
