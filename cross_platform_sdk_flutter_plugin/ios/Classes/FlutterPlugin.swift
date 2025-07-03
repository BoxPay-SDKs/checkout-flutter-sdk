import Flutter
import UIKit
import CrossPlatformSDK // ✅ This should match your XCFramework module name

public class FlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cross_platform_sdk", binaryMessenger: registrar.messenger())
        let instance = FlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getInstalledUpiApps":
            let detector = UPIAppDetectorIOS() // ✅ This should be your KMM/iOS class from BoxPayBridge
            let upiService = UPIService(detector: detector)
            installedApps = upiService.getAvailableApps()
            result(installedApps)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
