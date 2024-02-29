//
//  CTTemplateContext.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTTemplateContext : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (NSString *)templateName
NS_SWIFT_NAME(name());

- (nullable NSString *)stringNamed:(NSString *)name
NS_SWIFT_NAME(string(name:));

- (nullable NSString *)fileNamed:(NSString *)name
NS_SWIFT_NAME(file(name:));

- (nullable NSNumber *)numberNamed:(NSString *)name
NS_SWIFT_NAME(number(name:));

- (BOOL)boolNamed:(NSString *)name
NS_SWIFT_NAME(boolean(name:));

- (nullable NSDictionary *)dictionaryNamed:(NSString *)name
NS_SWIFT_NAME(dictionary(name:));

/**
 * Executes the action given by the "name" key.
 * Records Notification Clicked event.
 */
- (void)executeActionNamed:(NSString *)name
NS_SWIFT_NAME(executeAction(name:));

/**
 * Call this method to notify the SDK the template is dismissed.
 */
- (void)dismissed;

@end

NS_ASSUME_NONNULL_END
