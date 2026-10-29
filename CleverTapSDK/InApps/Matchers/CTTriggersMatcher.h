//
//  CTTriggersMatcher.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 2.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CTEventAdapter;
#import "CTLocalDataStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTTriggersMatcher : NSObject

- (instancetype)initWithDataStore:(CTLocalDataStore *)dataStore;
- (BOOL)matchEventWhenTriggers:(NSArray *)whenTriggers event:(CTEventAdapter *)event;

@end

NS_ASSUME_NONNULL_END
