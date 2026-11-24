# [CocoaPods](https://cocoapods.org) for CleverTap

> **NOTICE: CocoaPods trunk becomes read-only on December 2, 2026.** After that date new
> CleverTap versions are published to our own specs repo, not to trunk. Add both source lines
> below to the top of your Podfile to keep receiving updates. The `cdn.cocoapods.org` line is
> still needed so other pods (for example SDWebImage) resolve. Existing installs are unaffected.

For your iOS, App Extension target(s) and tvOS app, add the following to the top of your Podfile:

  ```
  source 'https://github.com/CleverTap/podspecs.git'
  source 'https://cdn.cocoapods.org/'

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
