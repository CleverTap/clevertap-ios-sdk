#import <Foundation/Foundation.h>
#import "CleverTap.h"

@class CleverTap;

@protocol CleverTapDomainDelegate <NSObject>
@optional
- (void)onDCDomainAvailable:(NSString* _Nonnull)domain;
- (void)onDCDomainUnavailable;
@end

@interface CleverTap (DCDomain)
@end






