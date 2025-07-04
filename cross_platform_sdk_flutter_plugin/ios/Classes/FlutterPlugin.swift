import Flutter
import UIKit
import CrossPlatformSDK

public class CrossPlatformSdkFlutterPlugin: NSObject, FlutterPlugin {
    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cross_platform_sdk", binaryMessenger: registrar.messenger())
        let instance = CrossPlatformSdkFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    @objc public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getInstalledUpiApps":
            let detector = UPIAppDetectorIOS()
            let upiService = UPIService(detector: detector)
            let installedApps = upiService.getAvailableApps()
            result(installedApps)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

