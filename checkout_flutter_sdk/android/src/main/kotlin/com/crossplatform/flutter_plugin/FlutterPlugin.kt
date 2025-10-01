package com.crossplatform.flutter_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.crossplatform.android.UPIAppDetectorAndroid
import com.crossplatform.sdk.UPIService
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri

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

      "launchMandate" -> {
          val mandateUrl = call.argument<String>("url") ?: ""
          launchUpiMandate(mandateUrl, result)
      }

      else -> result.notImplemented()
    }
  }

  private fun launchUpiMandate(mandateUrl: String, result: Result) {
    try {
      val intent = Intent(Intent.ACTION_VIEW, Uri.parse(mandateUrl))

      // Check if any app can handle this intent
      val resolveInfo = context.packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
      if (resolveInfo != null) {
        // Launch the UPI app
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        result.success(true) // Launched successfully
      } else {
        // No app supports mandate
        result.success(false)
      }
    } catch (e: Exception) {
      result.error("MANDATE_LAUNCH_FAILED", e.localizedMessage, null)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}

