#import <UIKit/UIKit.h>
#import "CTInAppResources.h"
#import "CleverTapBuildInfo.h"
#import "CTABTestEditorDeviceInfoMessageRequest.h"
#import "CTABTestEditorDeviceInfoMessageResponse.h"

NSString *const CTABTestEditorDeviceInfoMessageRequestType = @"device_info_request";

@implementation CTABTestEditorDeviceInfoMessageRequest

+ (instancetype)message {
    return [[[self class] alloc] initWithType:CTABTestEditorDeviceInfoMessageRequestType];
}

- (CTABTestEditorMessage *)response {
    CTABTestEditorDeviceInfoMessageResponse *deviceInfoMessageResponse = [CTABTestEditorDeviceInfoMessageResponse messageWithOptions:nil];
        UIDevice *currentDevice = [UIDevice currentDevice];
        deviceInfoMessageResponse.sdkVersion = WR_SDK_REVISION;
        deviceInfoMessageResponse.appBuild = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
        deviceInfoMessageResponse.appVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
        deviceInfoMessageResponse.bundleId = [NSBundle mainBundle].infoDictionary[@"CFBundleIdentifier"];
        deviceInfoMessageResponse.systemVersion = currentDevice.systemVersion;
        deviceInfoMessageResponse.systemName = currentDevice.systemName;
        deviceInfoMessageResponse.deviceName = currentDevice.name;
        deviceInfoMessageResponse.deviceModel = currentDevice.model;
    
        dispatch_sync(dispatch_get_main_queue(), ^{
            UIInterfaceOrientation orientation = [[CTInAppResources getSharedApplication] statusBarOrientation];
            BOOL landscape = (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
            if  (landscape) {
                deviceInfoMessageResponse.deviceWidth = [self deviceHeight];
                deviceInfoMessageResponse.deviceHeight = [self deviceWidth];
            } else {
                deviceInfoMessageResponse.deviceWidth = [self deviceWidth];
                deviceInfoMessageResponse.deviceHeight = [self deviceHeight];
            }
        });
    
        deviceInfoMessageResponse.availableFontFamilies = [self availableFontFamilies];
        return deviceInfoMessageResponse;
}

- (NSArray *)availableFontFamilies {
    NSMutableDictionary *fontFamilies = [NSMutableDictionary dictionary];
    
    // Get all the font families and font names.
    for (NSString *familyName in [UIFont familyNames]) {
        fontFamilies[familyName] = [self fontDictionaryForFontFamilyName:familyName fontNames:[UIFont fontNamesForFamilyName:familyName]];
    }
    
    // For the system fonts update the font families.
    NSArray *systemFonts = @[[UIFont systemFontOfSize:17.0f],
                             [UIFont boldSystemFontOfSize:17.0f],
                             [UIFont italicSystemFontOfSize:17.0f]];
    
    for (UIFont *systemFont in systemFonts) {
        NSString *familyName = systemFont.familyName;
        NSString *fontName = systemFont.fontName;
        
        NSMutableDictionary *font = fontFamilies[familyName];
        if (font) {
            NSMutableArray *fontNames = font[@"font_names"];
            if ([fontNames containsObject:fontName] == NO) {
                [fontNames addObject:fontName];
            }
        } else {
            fontFamilies[familyName] = [self fontDictionaryForFontFamilyName:familyName fontNames:@[fontName]];
        }
    }
    
    return fontFamilies.allValues;
}

- (NSMutableDictionary *)fontDictionaryForFontFamilyName:(NSString *)familyName fontNames:(NSArray *)fontNames {
    return [@{
              @"family": familyName,
              @"font_names": [fontNames mutableCopy]
              } mutableCopy];
}

- (NSString*)deviceWidth {
    int width = (int)[[UIScreen mainScreen] bounds].size.width ;
    NSString *_deviceWidth = [NSString stringWithFormat:@"%i", width];
    return _deviceWidth;
}

- (NSString*)deviceHeight {
    int height = (int)[[UIScreen mainScreen] bounds].size.height;
    NSString *_deviceHeight = [NSString stringWithFormat:@"%i", height];
    return _deviceHeight;
}

@end
