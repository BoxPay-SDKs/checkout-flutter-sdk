package com.example.webview_app

import android.content.Context
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "app.channel.shared.data"
    }
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "isAppInstalled") {
                    val packageName = call.argument<String>("package_name")
                    if (packageName != null) {
                        result.success(isAppInstalled(packageName))
                    } else {
                        result.error("INVALID_PACKAGE_NAME", "Package name is null", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
    private fun isAppInstalled(packageName: String): Boolean {
        val context: Context = applicationContext
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true // App is installed
        } catch (e: PackageManager.NameNotFoundException) {
            false // App is not installed
        }
    }
}
