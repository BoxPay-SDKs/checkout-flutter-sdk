import Flutter
import UIKit
import cross_platform_sdk

private let TAG = "UpiPluginDebug"

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
            print("\(TAG): launchMandate call")
            handleLaunch(call: call, result: result)

        case "launchPayment":
            print("\(TAG): launchPayment call")
            handleLaunch(call: call, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleLaunch(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let urlString = args["url"] as? String,
              let url = URL(string: urlString) else {
            print("\(TAG): handleLaunch: INVALID_URL, args=\(String(describing: call.arguments))")
            result(FlutterError(code: "INVALID_URL", message: "URL missing or invalid", details: nil))
            return
        }
        print("\(TAG): handleLaunch: parsed url=\(url)")

        guard let scheme = url.scheme?.lowercased() else {
            print("\(TAG): handleLaunch: UNSUPPORTED_SCHEME — no scheme in url=\(url)")
            result(FlutterError(code: "UNSUPPORTED_SCHEME", message: "URL has no scheme", details: nil))
            return
        }
        print("\(TAG): handleLaunch: scheme=\(scheme)")

        let installedAliases = DeviceSpecific_iosKt.getInstalledUpiApps(context: nil) as? [String] ?? []
        print("\(TAG): handleLaunch: installedAliases (raw cast)=\(installedAliases)")

        // Expand each installed alias into all of its accepted scheme variants,
        // so e.g. installed "gpay" also trusts a "tez://" URL.
        let installedSchemes: Set<String> = Set(
            installedAliases
                .map { $0.lowercased() }
                .flatMap { alias in aliasToAcceptedSchemes[alias] ?? [alias] }
        )
        print("\(TAG): handleLaunch: installedSchemes (expanded)=\(installedSchemes)")

        guard installedSchemes.contains(scheme) else {
            print("\(TAG): handleLaunch: scheme '\(scheme)' NOT in installedSchemes=\(installedSchemes) -> refusing")
            result(FlutterError(
                code: "UNSUPPORTED_SCHEME",
                message: "Refusing to open URL — scheme '\(scheme)' not in getInstalledUpiApps() result",
                details: nil
            ))
            return
        }

        let canOpen = UIApplication.shared.canOpenURL(url)
        print("\(TAG): handleLaunch: canOpenURL(\(url))=\(canOpen)")

        if canOpen {
            UIApplication.shared.open(url, options: [:]) { success in
                print("\(TAG): handleLaunch: open(\(url)) completion success=\(success)")
                result(success)
            }
        } else {
            print("\(TAG): handleLaunch: canOpenURL returned false -> result(false)")
            result(false)
        }
    }
}