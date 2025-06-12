project 'CleverTapSDK'

use_frameworks!
abstract_target 'shared' do
  use_modular_headers!  

  target 'CleverTapSDKTests' do
      platform :ios, '10.0'
      pod 'OCMock', '~> 3.3.0'
      pod 'OHHTTPStubs'
  
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
