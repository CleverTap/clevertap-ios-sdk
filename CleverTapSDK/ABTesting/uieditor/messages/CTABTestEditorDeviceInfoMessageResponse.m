#import "CTABTestEditorDeviceInfoMessageResponse.h"

NSString *const CTABTestEditorDeviceInfoMessageResponseType = @"device_info_response";

@implementation CTABTestEditorDeviceInfoMessageResponse

+ (instancetype)message {
    return [[[self class] alloc] initWithType:CTABTestEditorDeviceInfoMessageResponseType];
}

- (NSString *)systemName {
    return [self dataObjectForKey:@"system_name"];
}

- (void)setSystemName:(NSString *)systemName {
    [self setDataObject:systemName forKey:@"system_name"];
}

- (NSString *)systemVersion {
    return [self dataObjectForKey:@"system_version"];
}

- (void)setSystemVersion:(NSString *)systemVersion {
    [self setDataObject:systemVersion forKey:@"system_version"];
}

- (NSString *)appVersion {
    return [self dataObjectForKey:@"app_version"];
}

- (void)setAppVersion:(NSString *)appVersion {
    [self setDataObject:appVersion forKey:@"app_version"];
}

- (NSString *)appBuild {
    return [self dataObjectForKey:@"app_build"];
}

- (void)setAppBuild:(NSString *)appBuild {
    [self setDataObject:appBuild forKey:@"app_build"];
}

- (NSString *)deviceName {
    return [self dataObjectForKey:@"device_name"];
}

- (void)setDeviceName:(NSString *)deviceName {
    [self setDataObject:deviceName forKey:@"device_name"];
}

- (NSString *)deviceModel {
    return [self dataObjectForKey:@"device_model"];
}

- (void)setDeviceModel:(NSString *)deviceModel {
    [self setDataObject:deviceModel forKey:@"device_model"];
}

- (NSString *)deviceHeight {
    return [self dataObjectForKey:@"device_height"];
}

- (void)setDeviceHeight:(NSString *)deviceHeight {
    [self setDataObject:deviceHeight forKey:@"device_height"];
}

- (NSString *)deviceWidth {
    return [self dataObjectForKey:@"device_width"];
}

- (void)setDeviceWidth:(NSString *)deviceWidth {
    [self setDataObject:deviceWidth forKey:@"device_width"];
}

- (NSString *)sdkVersion {
    return [self dataObjectForKey:@"sdk_version"];
}

- (void)setSdkVersion:(NSString *)sdkVersion {
    [self setDataObject:sdkVersion forKey:@"sdk_version"];
}

- (NSString *)bundleId {
    return [self dataObjectForKey:@"bundle_id"];
}

- (void)setBundleId:(NSString *)bundleId {
    [self setDataObject:bundleId forKey:@"bundle_id"];
}

- (NSString *)library {
    return [self dataObjectForKey:@"library"];
}

- (void)setLibrary:(NSString *)library {
    [self setDataObject:library forKey:@"library"];
}

- (NSArray *)availableFontFamilies {
    return [self dataObjectForKey:@"available_font_families"];
}

- (void)setAvailableFontFamilies:(NSArray *)availableFontFamilies {
    [self setDataObject:availableFontFamilies forKey:@"available_font_families"];
}

@end
