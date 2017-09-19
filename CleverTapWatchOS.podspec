Pod::Spec.new do |s|
  s.name             = "CleverTapWatchOS"
  s.version          = "3.1.5"
  s.summary          = "The CleverTap iOS SDK for App Personalization and Engagement, watchOS Framework."

  s.description      = <<-DESC
                    CleverTap is the next generation app engagement platform. It enables marketers to identify, engage and retain users and provides developers with unprecedented code-level access to build dynamic app experiences for multiple user groups. CleverTap includes out-of-the-box prescriptive campaigns, omni-channel messaging, uninstall data and the industry’s largest FREE messaging tier.
                       DESC

  s.homepage         = "https://github.com/CleverTap/clevertap-ios-sdk"
  s.license          = { :type => 'Commercial', :text => 'Please refer to https://github.com/CleverTap/clevertap-ios-sdk/blob/master/LICENSE'}
  s.author           = { "CleverTap" => "http://www.clevertap.com" }
  s.source           = { :git => "https://github.com/CleverTap/clevertap-ios-sdk.git", :tag => s.version.to_s }
  s.documentation_url = 'http://support.clevertap.com/'
  s.requires_arc = true
  s.source_files = 'CleverTapWatchOS/*.swift'
  s.frameworks = 'WatchConnectivity', 'Foundation'
  s.watchos.deployment_target = '2.0'
end
