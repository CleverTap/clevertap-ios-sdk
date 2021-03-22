# [CocoaPods](https://cocoapods.org) for CleverTap

For your iOS, App Extension target(s) and tvOS app, add the following to your Podfile:

  ```
  target 'YOUR_TARGET_NAME' do  
      pod 'CleverTap-iOS-SDK'  
  end     
  ```

  If your main app is also a watchOS Host, and you wish to capture custom events from your watchOS app, add this:

  ```
  target 'YOUR_WATCH_EXTENSION_TARGET_NAME' do  
      pod 'CleverTapWatchOS'  
  end
  ```

  Also, you will need to enable the preprocessor macro via your Podfile by adding this post install hook:

  ```
  post_install do |installer_representation|
      installer_representation.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
              config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 
              'CLEVERTAP_HOST_WATCHOS=1']
          end
     end
  end
  ```

Then run `pod install`.
