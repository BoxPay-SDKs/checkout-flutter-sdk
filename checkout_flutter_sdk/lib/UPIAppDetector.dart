import 'package:flutter/services.dart';

class UPIAppDetector {
  static const MethodChannel _channel = MethodChannel('cross_platform_sdk');

  static Future<List<String>> getInstalledUpiApps() async {
    final List<dynamic> result = await _channel.invokeMethod('getInstalledUpiApps');
    return result.cast<String>();
  }

  static Future<bool> launchMandate(String mandateUrl) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'launchMandate',
        {'url': mandateUrl},
      );
      print("launchMandate result: $result");
      return result ?? false; // true = launched, false = unsupported
    } on PlatformException catch (e) {
      print('Mandate launch failed: $e');
      return false;
    }
  }
}
