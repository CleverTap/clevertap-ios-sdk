Pod::Spec.new do |s|
  s.name             = "CleverTapWatchOS"
  s.version          = "3.2.0"
  s.summary          = "The CleverTap iOS SDK for App Analytics and Engagement, watchOS Framework."
  s.homepage         = "https://github.com/CleverTap/clevertap-ios-sdk"
  s.license          = { :type => 'MIT' }
  s.author           = { "CleverTap" => "http://www.clevertap.com" }
  s.source           = { :git => "https://github.com/CleverTap/clevertap-ios-sdk.git", :tag => s.version.to_s }
  s.documentation_url = 'http://support.clevertap.com/'
  s.requires_arc = true
  s.source_files = 'CleverTapWatchOS/*.{h,m}'
  s.ios.public_header_files   = 'CleverTapWatchOS/CleverTapWatchOS.h'
  s.frameworks = 'WatchConnectivity', 'Foundation'
  s.watchos.deployment_target = '2.0'
end
