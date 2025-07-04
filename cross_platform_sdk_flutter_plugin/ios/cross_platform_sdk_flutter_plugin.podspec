#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cross_platform_sdk_flutter_plugin'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for cross-platform SDK integration.'
  s.description      = <<-DESC
A Flutter plugin that bridges platform-specific native SDKs with Dart via MethodChannels.
Includes support for UPI detection and native service bridging using an XCFramework.
  DESC

  s.homepage         = 'https://github.com/your-org/cross-platform-sdk_flutter_plugin'
  s.license = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'BoxPay' => 'developers@boxpay.tech' }
  s.source           = { :path => '.' }

  s.swift_version    = '5.0'

  s.source_files     = 'Classes/**/*'

  # s.dependency 'CrossPlatformSDK', :path => '../../cross-platform-sdk'
  s.dependency 'Flutter'

  s.vendored_frameworks = 'Framework/CrossPlatformSDK.xcframework'
  s.module_name = 'cross_platform_sdk_flutter_plugin'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  # If needed:
  # s.resource_bundles = {
  #   'cross_platform_sdk_flutter_plugin_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  # }
end
