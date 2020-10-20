#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class CTObjectSerializerConfig;
@class CTObjectIdentityProvider;

@interface CTApplicationStateSerializer : NSObject

- (instancetype)initWithApplication:(UIApplication *)application               configuration:(CTObjectSerializerConfig *)configuration objectIdentityProvider:(CTObjectIdentityProvider *)objectIdentityProvider;

- (UIImage *)snapshotForWindowAtIndex:(NSUInteger)index;

- (NSDictionary *)objectHierarchyForWindowAtIndex:(NSUInteger)index;

@end

