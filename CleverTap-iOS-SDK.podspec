Pod::Spec.new do |s|
  s.name             = "CleverTap-iOS-SDK"
  s.version          = "3.1.3"
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

  s.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '$(inherited)' }

  s.default_subspec = 'Main'  

  s.subspec 'Main' do |ss|
      ss.platform = :ios, '8.0'
      ss.frameworks = 'SystemConfiguration', 'CoreTelephony', 'UIKit', 'CoreLocation'
      ss.ios.vendored_frameworks = 'CleverTapSDK.framework'
  end

  s.subspec 'HostWatchOS' do |ss|
      ss.platform = :ios, '8.0'
      ss.frameworks = 'WatchConnectivity', 'WatchKit'
      ss.dependency "CleverTap-iOS-SDK/Main"
  end

  s.subspec 'AppEx' do |ss|
      ss.platform = :ios, '10.0'
      ss.frameworks = 'SystemConfiguration', 'UIKit', 'CoreLocation'
      ss.ios.vendored_frameworks = 'CleverTapAppEx.framework'
  end

  s.subspec 'tvOS' do |ss|
      ss.platform = :tvos, '9.0'
      ss.frameworks = 'SystemConfiguration', 'UIKit', 'Foundation'
      ss.vendored_frameworks = 'CleverTapTVOS.framework'
  end

end
