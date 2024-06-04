//
//  CTCustomTemplatesManager.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 28.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTTemplateProducer.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTCustomTemplatesManager : NSObject

+ (void)registerTemplateProducer:(id<CTTemplateProducer>)producer;

- (instancetype)init NS_UNAVAILABLE;

- (BOOL)isRegisteredTemplateWithName:(NSString *)name;
- (BOOL)isVisualTemplateWithName:(nonnull NSString *)name;

- (NSDictionary*)syncPayload;

@end

NS_ASSUME_NONNULL_END
