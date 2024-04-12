Pod::Spec.new do |s|
s.name                      = "CleverTapLocation"
s.version                   = `cat sdk-version.txt`
s.summary                   = "The CleverTap Location iOS SDK."
s.homepage                  = "https://github.com/CleverTap/clevertap-ios-sdk"
s.license                   = { :type => "MIT" }
s.author                    = { "CleverTap" => "http://www.clevertap.com" }
s.source                    = { :git => "https://github.com/CleverTap/clevertap-ios-sdk.git", :tag => s.version.to_s }
s.requires_arc              = true
s.module_name               = 'CleverTapLocation'
s.resource_bundles          = {'CleverTapLocation' => ['CleverTapLocation/**/*.xcprivacy']}
s.ios.deployment_target     = '9.0'
s.ios.source_files          = 'CleverTapLocation/**/**/*.{h,m}'
s.ios.public_header_files   = 'CleverTapLocation/CleverTapLocation/Classes/CTLocationManager.h'
s.tvos.deployment_target    = '9.0'
s.tvos.source_files         = 'CleverTapLocation/**/**/*.{h,m}'
s.tvos.public_header_files  = 'CleverTapLocation/CleverTapLocation/Classes/CTLocationManager.h'
end
