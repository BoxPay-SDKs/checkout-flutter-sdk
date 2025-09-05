# checkout-flutter-sdk

Welcome to your Boxpay Checkout Flutter SDK 👋

## Installation

```sh
boxpay_checkout_flutter_sdk: ^1.0.16
```

## Usage

```js
import 'package:boxpay_checkout_flutter_sdk/boxpay_checkout.dart';
import 'package:boxpay_checkout_flutter_sdk/payment_result_object.dart';
import 'package:boxpay_checkout_flutter_sdk/configuration_options.dart';


// ...
void onPaymentResult(PaymentResultObject object) {
    console.log(`Status is ${object.status} & transaction id ${object.transactionId}`);
}

BoxPayCheckout boxPayCheckout = BoxPayCheckout(
                  context: context,
                  token: token,
                  onPaymentResult: onPaymentResult,
                  shopperToken: _shopperTokenController.text,
                  configurationOptions: {
                    ConfigurationOptions.enableSandboxEnv:
                        _selectedEnv == "test",
                    ConfigurationOptions.showUpiQrOnLoad: false,
                  },
);

boxPayCheckout.display();
```
