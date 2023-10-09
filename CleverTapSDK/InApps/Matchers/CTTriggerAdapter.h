//
//  TriggerAdapter.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 2.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTTriggerCondition.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTTriggerAdapter : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithJSON:(NSDictionary *)triggerJSON;

@property (nonatomic, strong, readonly) NSString *eventName;

@property (nonatomic, readonly) NSInteger propertyCount;
@property (nonatomic, readonly) NSInteger itemsCount;

- (CTTriggerCondition * _Nullable)propertyAtIndex:(NSInteger)index;
- (CTTriggerCondition * _Nullable)itemAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
