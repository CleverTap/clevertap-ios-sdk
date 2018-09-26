Pod::Spec.new do |s|
s.name                      = "CleverTap-iOS-SDK"
s.version                   = "3.2.1"
s.summary                   = "The CleverTap iOS SDK for App Analytics and Engagement."
s.homepage                  = "https://github.com/CleverTap/clevertap-ios-sdk"
s.license                   = { :type => "MIT" }
s.author                    = { "CleverTap" => "http://www.clevertap.com" }
s.source                    = { :git => "https://github.com/CleverTap/clevertap-ios-sdk.git", :tag => s.version.to_s }
s.requires_arc              = true
s.module_name               = 'CleverTapSDK' 
s.resources                 = 'CleverTapSDK/*.crt'
s.ios.deployment_target     = '8.0'
s.ios.source_files          = 'CleverTapSDK/*.{h,m}'
s.ios.public_header_files   = 'CleverTapSDK/CleverTap.h', 'CleverTapSDK/CleverTap+SSLPinning.h', 'CleverTapSDK/CleverTapInstanceConfig.h', 'CleverTapSDK/CleverTapBuildInfo.h', 'CleverTapSDK/CleverTapEventDetail.h', 'CleverTapSDK/CleverTapInAppNotificationDelegate.h', 'CleverTapSDK/CleverTapSyncDelegate.h', 'CleverTapSDK/CleverTapTrackedViewController.h', 'CleverTapSDK/CleverTapUTMDetail.h'
s.tvos.deployment_target    = '9.0'
s.tvos.source_files         = 'CleverTapSDK/*.{h,m}'
s.tvos.exclude_files        = 'CleverTapSDK/CTInAppHTMLViewController.{h,m}'
s.tvos.public_header_files  = 'CleverTapSDK/CleverTap.h', 'CleverTapSDK/CleverTap+SSLPinning.h', 'CleverTapSDK/CleverTapInstanceConfig.h', 'CleverTapSDK/CleverTapBuildInfo.h', 'CleverTapSDK/CleverTapEventDetail.h', 'CleverTapSDK/CleverTapSyncDelegate.h', 'CleverTapSDK/CleverTapTrackedViewController.h', 'CleverTapSDK/CleverTapUTMDetail.h'
end
