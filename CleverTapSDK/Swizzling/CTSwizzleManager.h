//
//  CTSwizzleManager.h
//  Pods
//
//  Created by Akash Malhotra on 27/06/23.
//

#import <Foundation/Foundation.h>
#import "CleverTap.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTSwizzleManager : NSObject
+ (void)swizzleAppDelegate;
+ (void)swizzleWillPresentOnClass:(Class)cls;
@end

NS_ASSUME_NONNULL_END
