//
//  CTCustomTemplateInAppData.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 9.05.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTCustomTemplateInAppData : NSObject

@property (nonatomic, copy, readonly) NSString *templateName;
@property (nonatomic, copy, readonly) NSString *templateId;
@property (nonatomic, copy, readonly) NSString *templateDescription;
@property (nonatomic, strong, readonly) NSDictionary *args;
@property (nonatomic, readonly) BOOL isAction;
@property (nonatomic, strong, readonly) NSDictionary *json;

- (instancetype)init NS_UNAVAILABLE;
#if !CLEVERTAP_NO_INAPP_SUPPORT
+ (instancetype _Nullable)createWithJSON:(NSDictionary * _Nonnull)json;
#endif

@end

NS_ASSUME_NONNULL_END
