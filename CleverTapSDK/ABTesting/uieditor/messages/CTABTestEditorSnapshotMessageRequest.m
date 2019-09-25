#import "CTABTestEditorSnapshotMessageRequest.h"
#import "CTABTestEditorSnapshotMessageResponse.h"
#import "CTApplicationStateSerializer.h"
#import "CTObjectSerializerConfig.h"
#import "CTObjectIdentityProvider.h"
#import "CTInAppResources.h"

NSString * const CTABTestEditorSnapshotMessageRequestType = @"snapshot_request";

static NSString * const kObjectIdentityProviderKey = @"object_identity_provider";
static NSString * const kSnapshot_hierarchyKey = @"snapshot_hierarchy";

@implementation CTABTestEditorSnapshotMessageRequest

+ (instancetype)message {
    return [[[self class] alloc] initWithType:CTABTestEditorSnapshotMessageRequestType];
}

- (CTABTestEditorMessage *)response {
    CTObjectSerializerConfig *serializerConfig = [self.session sessionObjectForKey:kSnapshotSerializerConfigKey];
    if (serializerConfig == nil) {
        CleverTapLogStaticDebug(@"Failed to serialized because serializer config is not present.");
        return nil;
    }
    
    // Get the object identity provider from the connection's session store or create one if there is none already.
    CTObjectIdentityProvider *objectIdentityProvider = [self.session sessionObjectForKey:kObjectIdentityProviderKey];
    if (objectIdentityProvider == nil) {
        objectIdentityProvider = [[CTObjectIdentityProvider alloc] init];
        [self.session setSessionObject:objectIdentityProvider forKey:kObjectIdentityProviderKey];
    }
    
    CTApplicationStateSerializer *serializer = [[CTApplicationStateSerializer alloc]
                                                initWithApplication:[CTInAppResources getSharedApplication]
                                                configuration:serializerConfig objectIdentityProvider:objectIdentityProvider];
    
    CTABTestEditorSnapshotMessageResponse *snapshotMessage = [CTABTestEditorSnapshotMessageResponse messageWithOptions:nil];
    __block UIImage *screenshot = nil;
    __block NSDictionary *serializedObjects = nil;
    __block NSString *orientation = nil;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        screenshot = [serializer snapshotForWindowAtIndex:0];
        orientation = [self orientation];
    });
    snapshotMessage.orientation = orientation;
    snapshotMessage.screenshot = screenshot;
    NSString *imageHash = [self dataObjectForKey:@"image_hash"];

    if ([imageHash isEqualToString:snapshotMessage.imageHash]) {
        serializedObjects = [self.session sessionObjectForKey:@"snapshot_hierarchy"];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            serializedObjects = [serializer objectHierarchyForWindowAtIndex:0];
        });
        [self.session setSessionObject:serializedObjects forKey:@"snapshot_hierarchy"];
    }
    
    snapshotMessage.serializedObjects = serializedObjects;
    return snapshotMessage;
}

- (NSString *)orientation {
    UIInterfaceOrientation orientation = [[CTInAppResources getSharedApplication] statusBarOrientation];
    BOOL landscape = (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
    if (landscape) {
        return @"landscape";
    } else {
        return @"portrait";
    }
}

@end
