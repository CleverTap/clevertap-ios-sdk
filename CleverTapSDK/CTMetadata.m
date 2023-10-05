//
//  CTMetadata.m
//  Pods
//
//  Created by Akash Malhotra on 04/07/23.
//

#import "CTMetadata.h"

@interface CTMetadata() {}
@property (atomic, retain) NSDictionary *wzrkParams;
@end

@implementation CTMetadata
@synthesize wzrkParams=_wzrkParams;

- (void)clearWzrkParams {
    _wzrkParams = nil;
}

- (NSDictionary*)wzrkParams {
    return _wzrkParams;
}
// only set them if not already set during the session
- (void)setWzrkParams:(NSDictionary *)params {
    if (_wzrkParams == nil) {
        _wzrkParams = params;
    }
}

@end
