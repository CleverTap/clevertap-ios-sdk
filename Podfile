project 'CleverTapSDK'

abstract_target 'shared' do
  
  pod 'OCMock', '~> 3.2.1'
  pod 'OHHTTPStubs'
  
  target 'CleverTapSDKTests' do
      platform :ios, '10.0'
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts target.name
  end
end
