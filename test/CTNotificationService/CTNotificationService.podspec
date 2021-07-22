Pod::Spec.new do |s|
  s.name             = "CTNotificationService"
  s.version          = "0.1.1"
  s.summary          = "A simple Notification Service Extension class to add media attachments to iOS 10 rich push notifications."
  s.homepage         = "https://github.com/CleverTap/CTNotificationService"
  s.license          = "MIT" 
  s.author           = { "CleverTap" => "http://www.clevertap.com" }
  s.source           = { :git => "https://github.com/CleverTap/CTNotificationService.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.platform = :ios, '10.0'
  s.weak_frameworks = 'UserNotifications'
  s.source_files = 'CTNotificationService/*.{m,h}' 
end
