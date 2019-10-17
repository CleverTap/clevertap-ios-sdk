
#import <Foundation/Foundation.h>

@interface CTNotificationButton : NSObject

@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, copy, readonly) NSString *textColor;
@property (nonatomic, copy, readonly) NSString *borderRadius;
@property (nonatomic, copy, readonly) NSString *borderColor;
@property (nonatomic, copy, readonly) NSDictionary *customExtras;

@property (nonatomic, copy, readonly) NSString *backgroundColor;
@property (nonatomic, readonly) NSURL *actionURL;

@property (nonatomic, copy, readonly) NSDictionary *jsonDescription;

@property (nonatomic, readonly) NSString *error;

- (instancetype)init __unavailable;

- (instancetype)initWithJSON:(NSDictionary *)json;

@end
