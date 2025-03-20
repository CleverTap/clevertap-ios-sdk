//
//  CTSystemAppFunction.h
//  CleverTapSDK
//
//  Created by Nishant Kumar on 19/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTSystemAppFunction_h
#define CTSystemAppFunction_h

#import <Foundation/Foundation.h>
#import "CTCustomTemplate.h"

@interface CTSystemAppFunction : NSObject

+ (NSDictionary<NSString *, CTCustomTemplate *> *)getSystemAppFunctions;

@end


#endif /* CTSystemAppFunction_h */
