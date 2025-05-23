import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> redirectModal(
  BuildContext context, {
  required String title,
  required String content,
  required String noButtonText,
  required String yesButtonText,
  required Function(Completer<bool>) onYesPressed,
  required Function(Completer<bool>) onNoPressed,
}) async {
  Completer<bool> completer = Completer<bool>();

  showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder<String>(
        future: _getMerchantDetailsFromSharedPreferences(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              backgroundColor: Colors.white,
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              actions: <Widget>[
                if (noButtonText.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      onNoPressed(completer);
                      Navigator.of(context).pop(false);
                    },
                    child: Text(noButtonText,
                        style: const TextStyle(color: Colors.black)),
                  ),
                TextButton(
                  onPressed: () {
                    onYesPressed(completer);
                    Navigator.of(context).pop(true);
                  },
                  child: Text(yesButtonText),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              backgroundColor: Colors.white,
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              actions: <Widget>[
                if (noButtonText.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      onNoPressed(completer);
                      Navigator.of(context).pop(false);
                    },
                    child: Text(noButtonText,
                        style: const TextStyle(color: Colors.black)),
                  ),
                TextButton(
                  onPressed: () {
                    onYesPressed(completer);
                    Navigator.of(context).pop(true);
                  },
                  child: Text(yesButtonText),
                ),
              ],
            );
          } else {
            final merchantDetails = jsonDecode(snapshot.data!);
            final font = merchantDetails['checkoutTheme']['font'] ?? "Poppins";
            final primaryButtonColoraValue =
                merchantDetails['checkoutTheme']['primaryButtonColor'];
            final buttonTextColorValue =
                merchantDetails['checkoutTheme']['buttonTextColor'];

            final primaryButtonColor = primaryButtonColoraValue != null
                ? Color(int.parse(primaryButtonColoraValue.substring(1),
                        radix: 16) +
                    0xFF000000)
                : const Color.fromARGB(255, 121, 157, 240);
            const secondaryButtonColor = Color.fromARGB(255, 249, 249, 249);
            final buttonTextColor = buttonTextColorValue != null
                ? Color(
                    int.parse(buttonTextColorValue.substring(1), radix: 16) +
                        0xFF000000)
                : Colors.black;

            final titlecolor = title == "Payment Failed"
                ? const Color.fromARGB(255, 199, 33, 21)
                : Colors.black;
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: titlecolor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          color: titlecolor,
                          fontFamily: font,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      content,
                      style: TextStyle(fontFamily: font, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
              backgroundColor: Colors.white,
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              actions: <Widget>[
                if (noButtonText.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.zero,
                    child: FilledButton(
                      onPressed: () {
                        onNoPressed(completer);
                        Navigator.of(context).pop(false);
                      },
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(6)))),
                        backgroundColor: WidgetStateProperty.all<Color>(
                          secondaryButtonColor,
                        ),
                        elevation: WidgetStateProperty.all<double>(2),
                        shadowColor: WidgetStateProperty.all<Color>(
                            Colors.black.withOpacity(0.04)),
                      ),
                      child: Text(
                        noButtonText,
                        style: TextStyle(fontFamily: font, color: Colors.black),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.zero,
                  child: ElevatedButton(
                    onPressed: () {
                      onYesPressed(completer);
                      Navigator.of(context).pop(true);
                    },
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6)))),
                      backgroundColor: WidgetStateProperty.all<Color>(
                        primaryButtonColor,
                      ),
                      elevation: WidgetStateProperty.all<double>(2),
                      shadowColor: WidgetStateProperty.all<Color>(
                          Colors.black.withOpacity(0.04)),
                    ),
                    child: Text(
                      yesButtonText,
                      style:
                          TextStyle(fontFamily: font, color: buttonTextColor),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      );
    },
  );

  return completer.future;
}

Future<String> _getMerchantDetailsFromSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('merchant_details') ?? '';
}
