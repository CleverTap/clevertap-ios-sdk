#import "CTApplicationStateSerializer.h"
#import "CTConstants.h"
#import "CTObjectSerializer.h"
#import "CTClassDescription.h"
#import "CTObjectSerializerConfig.h"
#import "CTObjectIdentityProvider.h"

@implementation CTApplicationStateSerializer{
    CTObjectSerializer *_serializer;
    UIApplication *_application;
}

- (instancetype)initWithApplication:(UIApplication *)application configuration:(CTObjectSerializerConfig *)configuration objectIdentityProvider:(CTObjectIdentityProvider *)objectIdentityProvider{
  
    if (application == nil || configuration == nil) return nil;
    
    self = [super init];
    if (self) {
        _application = application;
        _serializer = [[CTObjectSerializer alloc] initWithConfiguration:configuration
                       objectIdentityProvider:objectIdentityProvider];
    }
    return self;
}

- (UIImage *)snapshotForWindowAtIndex:(NSUInteger)index{
    UIImage *snapshotImage = nil;
    UIWindow *window = [self windowAtIndex:index];
    if (window && !CGRectEqualToRect(window.frame, CGRectZero)) {
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, window.screen.scale);
        if ([window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO] == NO) {
            CleverTapLogStaticInternal(@"Failed to get the snapshot for window at index: %d.", (int)index);
        }
        snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return snapshotImage;
}

- (NSDictionary *)objectHierarchyForWindowAtIndex:(NSUInteger)index{
    UIWindow *window = [self windowAtIndex:index];
    if (window) {
        return [_serializer serializedObjectsWithRootObject:window];
    }
    return @{};
}

- (UIWindow *)windowAtIndex:(NSUInteger)index{
    if (index > _application.windows.count) return nil;
    return _application.windows[index];
}

@end
