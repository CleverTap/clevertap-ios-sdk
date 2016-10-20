Pod::Spec.new do |s|
  s.name             = "CleverTap-iOS-SDK"
  s.version          = "3.1.0"
  s.summary          = "The CleverTap iOS SDK for App Personalization and Engagement."

  s.description      = <<-DESC
                    CleverTap is the next generation app engagement platform. It enables marketers to identify, engage and retain users and provides developers with unprecedented code-level access to build dynamic app experiences for multiple user groups. CleverTap includes out-of-the-box prescriptive campaigns, omni-channel messaging, uninstall data and the industry’s largest FREE messaging tier.
                       DESC

  s.homepage         = "https://github.com/CleverTap/clevertap-ios-sdk"
  s.license          = { :type => 'Commercial', :text => 'Please refer to https://github.com/CleverTap/clevertap-ios-sdk/blob/master/LICENSE'}
  s.author           = { "CleverTap" => "http://www.clevertap.com" }
  s.source           = { :git => "https://github.com/CleverTap/clevertap-ios-sdk.git", :tag => s.version.to_s }
  s.documentation_url = 'http://support.clevertap.com/'

  s.requires_arc = true

  s.platform = :ios, '8.0'

  s.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '$(inherited)' }

  s.default_subspec = 'Main'  

  s.subspec 'Main' do |ss|
      ss.source_files = 'CleverTapSDK.framework/Versions/A/Headers/*.h'
      ss.frameworks = 'SystemConfiguration', 'CoreTelephony', 'UIKit', 'CoreLocation'
      ss.ios.vendored_frameworks = 'CleverTapSDK.framework'
  end

  s.subspec 'AppExtension' do |ss|
      ss.source_files = 'CleverTapSDK.appex.framework/Versions/A/Headers/*.h'
      ss.frameworks = 'SystemConfiguration', 'UIKit', 'CoreLocation'
      ss.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' =>  '$(inherited) CLEVERTAP_APP_EXTENSION' }
      ss.ios.vendored_frameworks = 'CleverTapSDK.appex.framework'
  end

  s.subspec 'HostWatchOS' do |ss|
      ss.source_files = 'CleverTapSDK.hostwatchos.framework/Versions/A/Headers/*.h'
      ss.frameworks = 'WatchConnectivity', 'WatchKit', 'SystemConfiguration', 'CoreTelephony', 'UIKit', 'CoreLocation'
      ss.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' =>  '$(inherited) CLEVERTAP_HOST_WATCHOS' }
      ss.ios.vendored_frameworks = 'CleverTapSDK.hostwatchos.framework'
  end

end
