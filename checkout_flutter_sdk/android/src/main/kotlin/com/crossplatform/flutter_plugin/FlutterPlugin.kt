package com.crossplatform.flutter_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.crossplatform.sdk.presentation.getInstalledUpiApps
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
        val apps: List<Pair<String, String>> = getInstalledUpiApps(context)
        result.success(apps.map { it.first }) 
      }

      "launchMandate" -> {
          val url = call.argument<String>("url") ?: ""
          launchUpiIntent(url, result)
      }

      "launchPayment" -> {
          val url = call.argument<String>("url") ?: ""
          launchUpiIntent(url, result)
      }

      else -> result.notImplemented()
    }
  }

  private fun launchUpiIntent(upiUrl: String, result: Result) {
    if (upiUrl.isBlank()) {
      result.error("INVALID_URL", "UPI URL was empty", null)
      return
    }

    try {
      val uri = Uri.parse(upiUrl)
      val pm = context.packageManager

      // Source of truth: whatever getInstalledUpiApps() already treats as
      // a legitimate, installed UPI app.
      val installedTrustedPackages: List<Pair<String, String>> = getInstalledUpiApps(context)

      if (installedTrustedPackages.isEmpty()) {
      result.success(false)
      return
      }

      // Of those, keep only the ones that can actually resolve THIS uri
      // (e.g. a mandate-capable app vs a pay-only app, if that distinction
      // matters for your supported set).
      val probeIntent = Intent(Intent.ACTION_VIEW, uri)
      val resolvableCandidates = pm.queryIntentActivities(probeIntent, PackageManager.MATCH_DEFAULT_ONLY)
        .map { it.activityInfo.packageName }
        .toSet()


      // Filter pairs by package name being resolvable, keep the pair (need alias later? then don't map yet)
      val trustedTargets: List<String> = installedTrustedPackages
        .filter { (_, packageName) -> packageName in resolvableCandidates }
        .map { (_, packageName) -> packageName }


      when {
        trustedTargets.isEmpty() -> {
          // Either no trusted app is installed, or none of the trusted
          // apps declare a handler for this specific URI. Fail closed —
          // never fall back to an unpinned implicit intent.
          result.success(false)
        }

        trustedTargets.size == 1 -> {
          val launched = launchExplicit(uri, trustedTargets.first())
          result.success(launched)
        }

        else -> {
          // Multiple trusted, resolvable apps — show a chooser built ONLY
          // from this filtered list, not the raw OS chooser.
          val launched = launchTrustedChooser(uri, trustedTargets)
          result.success(launched)
        }
      }
    } catch (e: Exception) {
      result.error("UPI_LAUNCH_FAILED", e.localizedMessage, null)
    }
  }

  /**
   * Launches an explicit intent pinned to a single verified package.
   */
  private fun launchExplicit(uri: Uri, packageName: String): Boolean {
    return try {
      val intent = Intent(Intent.ACTION_VIEW, uri).apply {
        setPackage(packageName)
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      }

      val resolveInfo = context.packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)

      if (resolveInfo != null) {
        context.startActivity(intent)
        true
      } else {
        false
      }
    } catch (e: Exception) {
      false
    }
  }

  /**
   * Builds and launches a chooser restricted to the trusted candidate
   * packages only.
   */
  private fun launchTrustedChooser(uri: Uri, trustedPackages: List<String>): Boolean {
    return try {
      val intents = trustedPackages.map { pkg ->
        Intent(Intent.ACTION_VIEW, uri).apply {
          setPackage(pkg)
        }
      }

      if (intents.isEmpty()){ 
        return false
      }

      val chooser = Intent.createChooser(intents.first(), "Pay with").apply {
        putExtra(Intent.EXTRA_INITIAL_INTENTS, intents.drop(1).toTypedArray())
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      }
      context.startActivity(chooser)
      true
    } catch (e: Exception) {
      false
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}

