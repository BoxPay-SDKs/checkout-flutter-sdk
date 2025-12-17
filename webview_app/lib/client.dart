import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:boxpay_checkout_flutter_sdk/boxpay_checkout.dart';
import 'package:boxpay_checkout_flutter_sdk/payment_result_object.dart';
import 'dart:convert';
import 'package:webview_app/thank_you_page.dart';
import 'package:boxpay_checkout_flutter_sdk/configuration_options.dart';

class Client {
  BuildContext context;
  final bool qrLoadVisible;

  Client(this.context, this.qrLoadVisible);

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
        "legalEntity": {"code": "payu"},
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
        "uniqueReference": "x123",
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
      "frontendBackUrl": "https://www.boxp.tech",
      "createShopperToken": "true"
    };
    try {
      final response =
          await http.post(url, headers: headers, body: jsonEncode(jsonData));
      if (response.statusCode == 201) {
        var tokenFetched = jsonDecode(response.body)['token'];
        var shopperToken =
            jsonDecode(response.body)['payload']?['shopper_token'] ?? "";
        if (enteredToken != null) {
          tokenFetched = enteredToken;
        }

        print("tokenn : $tokenFetched");
        BoxPayCheckout boxPayCheckout = BoxPayCheckout(
          context: context,
          token: tokenFetched,
          onPaymentResult: onPaymentResult,
          shopperToken: shopperToken,
          configurationOptions: {
            ConfigurationOptions.enableSandboxEnv: envSelected == "test",
            ConfigurationOptions.showUpiQrOnLoad: qrLoadVisible,
          },
        );
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

  void onPaymentResult(PaymentResultObject object) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Status is ${object.status} & transaction id ${object.transactionId}"),
      ),
    );
    if (object.status == "Success") {
      // Close BoxPayCheckout and navigate to thank you page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ThankYouPage()),
      );
    }
  }
}
