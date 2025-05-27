Pod::Spec.new do |s|
s.name                      = "CleverTap-iOS-SDK"
s.version                   = `cat sdk-version.txt`
s.summary                   = "The CleverTap iOS SDK for App Analytics and Engagement."
s.homepage                  = "https://github.com/CleverTap/clevertap-ios-sdk"
s.license                   = { :type => "MIT" }
s.author                    = { "CleverTap" => "http://www.clevertap.com" }
s.source                    = { :git => "https://github.com/CleverTap/clevertap-ios-sdk.git", :tag => s.version.to_s }
s.requires_arc              = true
s.module_name               = 'CleverTapSDK'
s.resources                 = 'CleverTapSDK/*.{cer}'
s.resource_bundles          = {'CleverTapSDK' => ['CleverTapSDK/*.{xcprivacy}']}
s.swift_version             = '5.0'
s.ios.dependency             'SDWebImage', '~> 5.11'
s.ios.resource_bundle       = {'CleverTapSDK' => ['CleverTapSDK/**/*.{png,xib,html}', 'CleverTapSDK/**/*.xcdatamodeld']}
s.ios.deployment_target     = '9.0'
s.ios.source_files          = 'CleverTapSDK/**/*.{h,m,swift}'
s.ios.exclude_files         = 'CleverTapSDK/include/**/*.h'
s.ios.public_header_files   = 'CleverTapSDK/CleverTap.h', 'CleverTapSDK/CleverTap+SSLPinning.h','CleverTapSDK/CleverTap+Inbox.h', 'CleverTapSDK/CleverTapInstanceConfig.h', 'CleverTapSDK/CleverTapBuildInfo.h', 'CleverTapSDK/CleverTapEventDetail.h', 'CleverTapSDK/CleverTapInAppNotificationDelegate.h', 'CleverTapSDK/CleverTapSyncDelegate.h', 'CleverTapSDK/CleverTapTrackedViewController.h', 'CleverTapSDK/CleverTapUTMDetail.h', 'CleverTapSDK/CleverTapJSInterface.h', 'CleverTapSDK/CleverTap+DisplayUnit.h', 'CleverTapSDK/CleverTap+FeatureFlags.h', 'CleverTapSDK/CleverTap+ProductConfig.h', 'CleverTapSDK/CleverTapPushNotificationDelegate.h', 'CleverTapSDK/CleverTapURLDelegate.h', 'CleverTapSDK/CleverTap+InAppNotifications.h', 'CleverTapSDK/CleverTap+SCDomain.h', 'CleverTapSDK/CleverTap+PushPermission.h', 'CleverTapSDK/InApps/CTLocalInApp.h', 'CleverTapSDK/CleverTap+CTVar.h', 'CleverTapSDK/ProductExperiences/CTVar.h', 'CleverTapSDK/LeanplumCT.h', 'CleverTapSDK/InApps/CustomTemplates/CTInAppTemplateBuilder.h', 'CleverTapSDK/InApps/CustomTemplates/CTAppFunctionBuilder.h', 'CleverTapSDK/InApps/CustomTemplates/CTTemplatePresenter.h', 'CleverTapSDK/InApps/CustomTemplates/CTTemplateProducer.h', 'CleverTapSDK/InApps/CustomTemplates/CTCustomTemplateBuilder.h', 'CleverTapSDK/InApps/CustomTemplates/CTCustomTemplate.h', 'CleverTapSDK/InApps/CustomTemplates/CTTemplateContext.h', 'CleverTapSDK/InApps/CustomTemplates/CTCustomTemplatesManager.h', 'CleverTapSDK/InApps/CustomTemplates/CTJsonTemplateProducer.h'
s.tvos.deployment_target    = '9.0'
s.tvos.source_files         = 'CleverTapSDK/*.{h,m,swift}', 'CleverTapSDK/Encryption/*.{h,m,swift}', 'CleverTapSDK/FileDownload/*.{h,m}', 'CleverTapSDK/ProductConfig/**/*.{h,m}', 'CleverTapSDK/FeatureFlags/**/*.{h,m}', 'CleverTapSDK/ProductExperiences/*.{h,m}', 'CleverTapSDK/Swizzling/*.{h,m}', 'CleverTapSDK/Session/*.{h,m}', 'CleverTapSDK/EventDatabase/*.{h,m}'
s.tvos.exclude_files        = 'CleverTapSDK/include/**/*.h', 'CleverTapSDK/CleverTapJSInterface.{h,m}', 'CleverTapSDK/CTInAppNotification.{h,m}', 'CleverTapSDK/CTNotificationButton.{h,m}', 'CleverTapSDK/CTNotificationAction.{h,m}', 'CleverTapSDK/CTPushPrimerManager.{h,m}', 'CleverTapSDK/InApps/*.{h,m}', 'CleverTapSDK/InApps/**/*.{h,m}', 'CleverTapSDK/CTInAppFCManager.{h,m}', 'CleverTapSDK/CTInAppDisplayViewController.{h,m}'
s.tvos.public_header_files  = 'CleverTapSDK/CleverTap.h', 'CleverTapSDK/CleverTap+SSLPinning.h', 'CleverTapSDK/CleverTapInstanceConfig.h', 'CleverTapSDK/CleverTapBuildInfo.h', 'CleverTapSDK/CleverTapEventDetail.h', 'CleverTapSDK/CleverTapSyncDelegate.h', 'CleverTapSDK/CleverTapTrackedViewController.h', 'CleverTapSDK/CleverTapUTMDetail.h', 'CleverTapSDK/CleverTap+FeatureFlags.h', 'CleverTapSDK/CleverTap+ProductConfig.h', 'CleverTapSDK/CleverTap+CTVar.h', 'CleverTapSDK/ProductExperiences/CTVar.h'
end
