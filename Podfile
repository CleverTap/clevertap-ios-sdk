project 'CleverTapSDK'

use_frameworks!
abstract_target 'shared' do
  use_modular_headers!  

  target 'CleverTapSDKTests' do
      platform :ios, '10.0'
      pod 'OCMock', '~> 3.2.1'
      pod 'OHHTTPStubs'
  
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts target.name
  end
end
