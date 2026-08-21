import Flutter
import UIKit
import cross_platform_sdk


private let aliasToAcceptedSchemes: [String: [String]] = [
    "gpay":     ["tez", "gpay"],
    "paytm":    ["paytmmp", "paytm"],
    "phonepe":  ["phonepe"],
    "bhim":     ["bhim"],
    "amazon_pay": ["amazonpay"],
    "mobikwik": ["mobikwik"],
    "bharatpe": ["postpe"],
    "jupiter":  ["jupiter"],
    "pop":      ["popclubapp"],
]

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
            handleLaunch(call: call, result: result)

        case "launchPayment":
            handleLaunch(call: call, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleLaunch(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let urlString = args["url"] as? String,
              let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_URL", message: "URL missing or invalid", details: nil))
            return
        }

        guard let scheme = url.scheme?.lowercased() else {
            result(FlutterError(code: "UNSUPPORTED_SCHEME", message: "URL has no scheme", details: nil))
            return
        }

        let installedAliases = DeviceSpecific_iosKt.getInstalledUpiApps(context: nil) as? [String] ?? []

        // Expand each installed alias into all of its accepted scheme variants,
        // so e.g. installed "gpay" also trusts a "tez://" URL.
        let installedSchemes: Set<String> = Set(
            installedAliases
                .map { $0.lowercased() }
                .flatMap { alias in aliasToAcceptedSchemes[alias] ?? [alias] }
        )

        guard installedSchemes.contains(scheme) else {
            result(FlutterError(
                code: "UNSUPPORTED_SCHEME",
                message: "Refusing to open URL — scheme '\(scheme)' not in getInstalledUpiApps() result",
                details: nil
            ))
            return
        }

        let canOpen = UIApplication.shared.canOpenURL(url)

        if canOpen {
            UIApplication.shared.open(url, options: [:]) { success in
                result(success)
            }
        } else {
            result(false)
        }
    }
}