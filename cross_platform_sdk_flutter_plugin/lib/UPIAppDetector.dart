import 'package:flutter/services.dart';

class UPIAppDetector {
  static const MethodChannel _channel = MethodChannel('cross_platform_sdk');

  static Future<List<String>> getInstalledUpiApps() async {
    final List<dynamic> result = await _channel.invokeMethod('getInstalledUpiApps');
    return result.cast<String>();
  }
}
