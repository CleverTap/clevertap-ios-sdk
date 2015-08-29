Pod::Spec.new do |s|
  s.name             = "CleverTap-iOS-SDK"
  s.version          = "1.83.34"
  s.summary          = "The CleverTap iOS SDK for Mobile App Engagement."

  s.description      = <<-DESC
                    CleverTap iOS SDK. CleverTap is the next generation mobile engagement platform. It enables marketers to identify, engage and retain users and provides developers with unprecedented code-level access to build dynamic app experiences for multiple user groups. CleverTap includes out-of-the-box prescriptive campaigns, omni-channel messaging, uninstall data and the industry’s largest FREE messaging tier.
                       DESC

  s.homepage         = "https://github.com/CleverTap/clevertap-ios-sdk"
  s.license          = { :type => 'Commercial', :text => 'Please refer to https://github.com/CleverTap/clevertap-ios-sdk/blob/master/LICENSE'}
  s.author           = { "CleverTap" => "http://www.clevertap.com" }
  s.source           = { :git => "https://github.com/CleverTap/clevertap-ios-sdk.git", :tag => s.version.to_s }
  s.documentation_url = 'http://support.wizrocket.com/'

  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.frameworks = 'SystemConfiguration', 'CoreTelephony', 'UIKit', 'CoreLocation'

  s.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '$(inherited)' }  
  s.source_files = 'WizRocketSDK.framework/Versions/A/Headers/*.h'
  s.ios.vendored_frameworks = 'WizRocketSDK.framework'
  s.preserve_paths = 'WizRocketSDK.framework'  

end
