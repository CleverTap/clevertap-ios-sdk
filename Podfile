project 'CleverTapSDK'
use_frameworks!
abstract_target 'shared' do
  
  target 'CleverTapSDKTests' do
      platform :ios, '10.0'
      pod 'OCMock', '~> 3.2.1'
      pod 'OHHTTPStubs'
  
  end

  target 'CleverTapSDKTestsApp' do
      platform :ios, '10.0'
      pod 'OHHTTPStubs'
      pod 'CleverTap-iOS-SDK', :path =>'./'
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts target.name
    target.build_configurations.each do |config|
        config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"
      end
  end

end

