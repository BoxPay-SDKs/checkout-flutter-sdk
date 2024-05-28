import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
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
        "https://test-apis.boxpay.tech/v0/merchants/k14ut9k7gQ/sessions");
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization':
          'Bearer bXj9R23osaf70w00Rn2RXFVOUpis6sn1XNPWkDu8g9tpwjP4hZThKqS38iA6E931qbm3bXGLKQJ7scZaufrMvq',
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
      "billingAddress": {
        "address1": "first address line",
        "address2": "second address line",
        "city": "Faridabad",
        "state": "Haryana",
        "countryCode": "IN",
        "postalCode": "121004"
      },
      "shopper": {
        "firstName": "test",
        "lastName": "last",
        "email": "test123@gmail.com",
        "uniqueReference": "x123y",
        "phoneNumber": "911234567890",
        "deliveryAddress": {
          "address1": "first line",
          "address2": "second line",
          "city": "Mumbai",
          "state": "Maharashtra",
          "countryCode": "IN",
          "postalCode": "123456"
        }
      },
      "order": {
        "originalAmount": 3,
        "shippingAmount": 1,
        "voucherCode": "VOUCHER",
        "taxAmount": 1,
        "totalAmountWithoutTax": 4,
        "items": [
          {
            "id": "test",
            "itemName": "test_name",
            "description": "testProduct",
            "quantity": 1,
            "manufacturer": null,
            "brand": null,
            "color": null,
            "productUrl": null,
            "imageUrl":
                "https://www.kasandbox.org/programming-images/avatars/old-spice-man.png",
            "categories": null,
            "amountWithoutTax": 1,
            "taxAmount": 0,
            "taxPercentage": null,
            "discountedAmount": null,
            "amountWithoutTaxLocale": "10",
            "amountWithoutTaxLocaleFull": "10"
          },
          {
            "id": "test2",
            "itemName": "test_name",
            "description": "testProduct",
            "quantity": 1,
            "manufacturer": null,
            "brand": null,
            "color": null,
            "productUrl": null,
            "imageUrl": "https://picsum.photos/id/30/200",
            "categories": null,
            "amountWithoutTax": 1,
            "taxAmount": 0,
            "taxPercentage": null,
            "discountedAmount": null,
            "amountWithoutTaxLocale": "10",
            "amountWithoutTaxLocaleFull": "10"
          },
          {
            "id": "test3",
            "itemName": "test_name",
            "description": "testProduct",
            "quantity": 1,
            "manufacturer": null,
            "brand": null,
            "color": null,
            "productUrl": null,
            "imageUrl": "https://picsum.photos/id/20/200",
            "categories": null,
            "amountWithoutTax": 1,
            "taxAmount": 0,
            "taxPercentage": null,
            "discountedAmount": null,
            "amountWithoutTaxLocale": "10",
            "amountWithoutTaxLocaleFull": "10"
          }
        ]
      },
      "statusNotifyUrl": "https://www.boxpay.tech",
      "frontendReturnUrl": "https://www.boxpay.tech",
      "frontendBackUrl": "https://www.tajhotels.com/en-in/epicureprogram/"
    };
    try {
      if (enteredToken == null) {
        final response =
            await http.post(url, headers: headers, body: jsonEncode(jsonData));
        if (response.statusCode == 201) {
          var tokenFetched = jsonDecode(response.body)['token'];
          print("token : $tokenFetched");
          bool sandboxflag = false;
          if (envSelected == "sandbox") {
            sandboxflag = true;
          }
          BoxPayCheckout boxPayCheckout = BoxPayCheckout(
              context: context,
              token: tokenFetched,
              onPaymentResult: onPaymentResult,
              sandboxEnabled: sandboxflag,
              selectedEnv: envSelected);
          await boxPayCheckout.display();
        } else {
          print('Error occurred: ${response.statusCode}');
          print('Details: ${response.body}');
          // Handle error
        }
      } else {
        bool sandboxflag = false;
          if (envSelected == "sandbox") {
            sandboxflag = true;
          }
        BoxPayCheckout boxPayCheckout = BoxPayCheckout(
            context: context,
            token: enteredToken,
            onPaymentResult: onPaymentResult,
            sandboxEnabled: sandboxflag,
            selectedEnv: envSelected);
        await boxPayCheckout.display();
      }
    } catch (e) {
      print('Error occurred: $e');
      // Handle error
    }
  }

  void onPaymentResult(PaymentResultObject status) {
    if (status.result == "Success") {
      // Close BoxPayCheckout and navigate to thank you page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ThankYouPage()),
      );
    }
  }
}
