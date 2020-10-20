#import <UIKit/UIKit.h>
#import "CTABTestEditorMessage.h"

@interface CTABTestEditorSnapshotMessageResponse : CTABTestEditorMessage

@property (nonatomic, strong) UIImage *screenshot;
@property (nonatomic, strong, readonly) NSString *imageHash;
@property (nonatomic, copy) NSDictionary *serializedObjects;
@property (nonatomic, copy) NSString *orientation;

@end

