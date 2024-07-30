import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_app/boxpay_checkout.dart';
import 'package:webview_app/payment_result_object.dart';
import 'dart:convert';

import 'package:webview_app/thank_you_page.dart';

class Client {
  BuildContext context;

  Client(this.context);

  Future<void> makePaymentRequest(enteredToken, envSelected) async {
    final url = Uri.parse(
        "https://test-apis.boxpay.tech/v0/merchants/lGfqzNSKKA/sessions");
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization':
          'Bearer 3z3G6PT8vDhxQCKRQzmRsujsO5xtsQAYLUR3zcKrPwVrphfAqfyS20bvvCg2X95APJsT5UeeS5YdD41aHbz6mg',
    };
    final Map<String, dynamic> jsonData = {
      "context": {
    "countryCode": "IN",
    "legalEntity": {"code": "boxpay"},
    "orderId": "test12"
  },
  "paymentType": "S",
  "money": {"amount": "1", "currencyCode": "INR"},
  "descriptor": {"line1": "Some descriptor"},
  "shopper": {
    "firstName": "Ishika",
    "lastName": "Bansal",
    "email":"ishika.bansal@boxpay.tech",
    "uniqueReference": "x123y",
    "phoneNumber": "919876543210",
    "deliveryAddress": {
      "address1": "first line",
      "address2": "second line",
      "city": "New Delhi",
      "state": "Delhi",
      "countryCode": "IN",
      "postalCode": "147147"
    }
  },
  "order": {
    "originalAmount": 423.73,
    "shippingAmount": 50,
    "voucherCode": "VOUCHER",
    "taxAmount": 76.27,
    "totalAmountWithoutTax": 423.73,
    "items": [
      {
        "id": "test",
        "itemName": "Sample Item",
        "description": "testProduct",
        "quantity": 1,
        "manufacturer": null,
        "brand": null,
        "color": null,
        "productUrl": null,
        "imageUrl":
            "https://www.kasandbox.org/programming-images/avatars/old-spice-man.png",
        "categories": null,
        "amountWithoutTax": 423.73,
        "taxAmount": 76.27,
        "taxPercentage": null,
        "discountedAmount": null,
        "amountWithoutTaxLocale": "10",
        "amountWithoutTaxLocaleFull": "10"
      }
    ]
  },
  "statusNotifyUrl": "https://www.boxpay.tech",
  "frontendReturnUrl": "https://www.boxpay.tech",
  "frontendBackUrl": "https://www.boxpay.tech"
    };
    try {
      final response =
          await http.post(url, headers: headers, body: jsonEncode(jsonData));
      if (response.statusCode == 201) {
        var tokenFetched = jsonDecode(response.body)['token'];
        if (enteredToken != null) {
          tokenFetched = enteredToken;
        }
        bool sandboxflag = false;
        if (envSelected == "sandbox") {
          sandboxflag = true;
        }
        print("tokenn : $tokenFetched");
        print("sandboxflag $sandboxflag");
        BoxPayCheckout boxPayCheckout = BoxPayCheckout(
            context: context,
            token: tokenFetched,
            onPaymentResult: onPaymentResult,
            sandboxEnabled: sandboxflag);
        await boxPayCheckout.display();
      } else {
        print('Error occurred: ${response.statusCode}');
        print('Details: ${response.body}');
        // Handle error
      }
    } catch (e) {
      print('Error occurred: $e');
      // Handle error
    }
  }

  void onPaymentResult(PaymentResultObject status) {
    print("========status received ${status.result}");
    if (status.result == "Success") {
      // Close BoxPayCheckout and navigate to thank you page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ThankYouPage()),
      );
    }
  }
}