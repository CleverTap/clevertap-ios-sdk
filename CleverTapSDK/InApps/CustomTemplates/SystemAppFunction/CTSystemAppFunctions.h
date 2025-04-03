//
//  CTSystemAppFunctions.h
//  CleverTapSDK
//
//  Created by Nishant Kumar on 19/03/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTSystemAppFunction_h
#define CTSystemAppFunction_h

#import <Foundation/Foundation.h>
#import "CTCustomTemplate.h"

@interface CTSystemAppFunctions : NSObject

+ (NSDictionary<NSString *, CTCustomTemplate *> *)systemAppFunctions;

@end


#endif /* CTSystemAppFunction_h */
