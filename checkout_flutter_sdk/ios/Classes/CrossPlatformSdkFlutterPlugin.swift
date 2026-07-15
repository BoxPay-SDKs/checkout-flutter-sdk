import Flutter
import UIKit
import cross_platform_sdk

public class CrossPlatformSdkFlutterPlugin: NSObject, FlutterPlugin {
    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cross_platform_sdk", binaryMessenger: registrar.messenger())
        let instance = CrossPlatformSdkFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    @objc public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getInstalledUpiApps":
            let apps = DeviceSpecific_iosKt.getInstalledUpiApps(context: nil)
            result(apps)
            
        case "launchMandate":
            guard let args = call.arguments as? [String: Any],
                  let mandateUrlString = args["url"] as? String,
                  let url = URL(string: mandateUrlString) else {
                result(FlutterError(code: "INVALID_URL", message: "Mandate URL missing or invalid", details: nil))
                return
            }
            
            // Attempt to open the UPI mandate URL
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:]) { success in
                    result(success) // true if opened, false if failed
                }
            } else {
                // No app supports this URL
                result(false)
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
