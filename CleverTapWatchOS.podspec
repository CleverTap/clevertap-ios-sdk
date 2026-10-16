Pod::Spec.new do |s|
  s.name             = "CleverTapWatchOS"
  s.version          = "3.2.0"
  s.summary          = "The CleverTap iOS SDK for App Analytics and Engagement, watchOS Framework."
  s.description      = <<-DESC
                       The CleverTap iOS SDK for App Analytics and Engagement, watchOS Framework.

                       NOTICE: CocoaPods trunk becomes read-only on December 2, 2026. To keep
                       receiving CleverTap updates through CocoaPods, add these lines to your Podfile:
                         source 'https://github.com/CleverTap/podspecs.git'
                         source 'https://cdn.cocoapods.org/'
                       Existing installs are unaffected. See the README.
                       DESC
  s.homepage         = "https://github.com/CleverTap/clevertap-ios-sdk"
  s.license          = { :type => 'MIT' }
  s.author           = { "CleverTap" => "http://www.clevertap.com" }
  s.source           = { :git => "https://github.com/CleverTap/clevertap-ios-sdk.git", :tag => s.version.to_s }
  s.documentation_url = 'https://developer.clevertap.com'
  s.requires_arc = true
  s.source_files = 'CleverTapWatchOS/*.{h,m}'
  s.ios.public_header_files   = 'CleverTapWatchOS/CleverTapWatchOS.h'
  s.frameworks = 'WatchConnectivity', 'Foundation'
  s.watchos.deployment_target = '2.0'
end
