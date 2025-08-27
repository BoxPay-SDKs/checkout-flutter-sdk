package com.crossplatform.flutter_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.crossplatform.android.UPIAppDetectorAndroid
import com.crossplatform.sdk.UPIService
import android.content.Context

class FlutterPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context // ✅ Declare context


  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext // ✅ Initialize it here
    channel = MethodChannel(binding.binaryMessenger, "cross_platform_sdk")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
        "getInstalledUpiApps" -> {
            val detector = UPIAppDetectorAndroid(context)
            val apps = detector.getInstalledUPIApps()
            result.success(apps)
        }
        else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}

