#import "CTABTestEditorMessage.h"

@interface CTABTestEditorDeviceInfoMessageResponse : CTABTestEditorMessage

@property (nonatomic, copy) NSString *sdkVersion;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *appBuild;
@property (nonatomic, copy) NSString *systemName;
@property (nonatomic, copy) NSString *systemVersion;
@property (nonatomic, copy) NSString *deviceName;
@property (nonatomic, copy) NSString *deviceModel;
@property (nonatomic, copy) NSString *deviceHeight;
@property (nonatomic, copy) NSString *deviceWidth;
@property (nonatomic, copy) NSString *bundleId;
@property (nonatomic, copy) NSString *library;
@property (nonatomic, copy) NSArray *availableFontFamilies;

@end

