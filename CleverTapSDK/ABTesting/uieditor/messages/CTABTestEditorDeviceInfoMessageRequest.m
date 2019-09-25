#import <UIKit/UIKit.h>
#import "CTInAppResources.h"
#import "CTDeviceInfo.h"
#import "CTABTestEditorDeviceInfoMessageRequest.h"
#import "CTABTestEditorDeviceInfoMessageResponse.h"

NSString *const CTABTestEditorDeviceInfoMessageRequestType = @"device_info_request";

@interface CTABTestEditorDeviceInfoMessageRequest ()

@property (nonatomic, strong) CTDeviceInfo *deviceInfo;

@end

@implementation CTABTestEditorDeviceInfoMessageRequest

+ (instancetype)message {
    return [[[self class] alloc] initWithType:CTABTestEditorDeviceInfoMessageRequestType];
}

+ (instancetype)messageWithOptions:(NSDictionary *)options {
    CTABTestEditorDeviceInfoMessageRequest *message = [CTABTestEditorDeviceInfoMessageRequest message];
    message.deviceInfo = options[@"deviceInfo"];
    return message;
}

- (CTABTestEditorMessage *)response {
    CTABTestEditorDeviceInfoMessageResponse *deviceInfoMessageResponse = [CTABTestEditorDeviceInfoMessageResponse messageWithOptions:nil];

    deviceInfoMessageResponse.sdkVersion = self.deviceInfo.sdkVersion;
    deviceInfoMessageResponse.appBuild = self.deviceInfo.appBuild;
    deviceInfoMessageResponse.appVersion = self.deviceInfo.appVersion;
    deviceInfoMessageResponse.bundleId = self.deviceInfo.bundleId;
    deviceInfoMessageResponse.systemVersion = self.deviceInfo.osVersion;
    deviceInfoMessageResponse.systemName = self.deviceInfo.osName;
    deviceInfoMessageResponse.deviceName = self.deviceInfo.deviceName;
    deviceInfoMessageResponse.deviceModel = self.deviceInfo.model;

    if (self.deviceInfo.library) {
        deviceInfoMessageResponse.library = self.deviceInfo.library;
    }

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
