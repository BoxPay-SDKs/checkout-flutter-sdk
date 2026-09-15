import Flutter
import UIKit
import cross_platform_sdk


private let aliasToAcceptedSchemes: [String: [String]] = [
    "gpay":     ["tez", "gpay"],
    "paytm":    ["paytmmp", "paytm"],
    "phonepe":  ["phonepe", "ppe"],
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
            let rawApps = DeviceSpecific_iosKt.getInstalledUpiApps(context: nil)

            let apps: [String] = (rawApps as? [KotlinPair<NSString, NSString>])?
                .compactMap { $0.first as String? } ?? []

            print("🔵 [DEBUG] getInstalledUpiApps -> \(apps)")
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
        print("🔵 [DEBUG] handleLaunch called, raw arguments: \(String(describing: call.arguments))")

        guard let args = call.arguments as? [String: Any],
            let urlString = args["url"] as? String,
            let url = URL(string: urlString) else {
            print("🔴 [DEBUG] Failed to parse URL from arguments")
            result(FlutterError(code: "INVALID_URL", message: "URL missing or invalid", details: nil))
            return
        }

        print("🔵 [DEBUG] Parsed URL: \(url.absoluteString)")
        print("🔵 [DEBUG] URL scheme: \(url.scheme ?? "nil")")
        print("🔵 [DEBUG] URL host: \(url.host ?? "nil")")
        print("🔵 [DEBUG] URL query items: \(url.query ?? "nil")")

        guard let scheme = url.scheme?.lowercased() else {
            print("🔴 [DEBUG] URL has no scheme at all")
            result(FlutterError(code: "UNSUPPORTED_SCHEME", message: "URL has no scheme", details: nil))
            return
        }

        let rawAliases = DeviceSpecific_iosKt.getInstalledUpiApps(context: nil)
        let installedAliases: [String] = (rawAliases as? [KotlinPair<NSString, NSString>])?
            .compactMap { $0.first as String? } ?? []

        print("🔵 [DEBUG] installedAliases -> \(installedAliases)")        
        print("🔵 [DEBUG] Raw installedAliases from getInstalledUpiApps(): \(installedAliases)")

        // Expand each installed alias into all of its accepted scheme variants,
        // so e.g. installed "gpay" also trusts a "tez://" URL.
        let installedSchemes: Set<String> = Set(
            installedAliases
                .map { $0.lowercased() }
                .flatMap { alias in aliasToAcceptedSchemes[alias] ?? [alias] }
        )
        print("🔵 [DEBUG] Expanded installedSchemes set: \(installedSchemes)")
        print("🔵 [DEBUG] Checking if scheme '\(scheme)' is in installedSchemes: \(installedSchemes.contains(scheme))")

        guard installedSchemes.contains(scheme) else {
            print("🔴 [DEBUG] REJECTED — scheme '\(scheme)' not found in installedSchemes")
            result(FlutterError(
                code: "UNSUPPORTED_SCHEME",
                message: "Refusing to open URL — scheme '\(scheme)' not in getInstalledUpiApps() result",
                details: nil
            ))
            return
        }

        let canOpen = UIApplication.shared.canOpenURL(url)
        print("🔵 [DEBUG] canOpenURL(\(url.absoluteString)) = \(canOpen)")

        if canOpen {
            UIApplication.shared.open(url, options: [:]) { success in
                print("🔵 [DEBUG] UIApplication.open completion — success: \(success)")
                result(success)
            }
        } else {
            print("🔴 [DEBUG] canOpenURL returned false — app not registered to handle this scheme via LSApplicationQueriesSchemes, or app not actually installed")
            result(false)
        }
    }
}