//
//  CTTemplateContext.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 Representation of the context around a ``CTCustomTemplate``. Use the `<type>Named:` methods to obtain the
 current values of the arguments. Use ``triggerActionNamed:`` to trigger template actions.
 Use ``presented`` and ``dismissed`` to notify the SDK of the current state of this InApp context.
 */
@interface CTTemplateContext : NSObject

- (instancetype)init NS_UNAVAILABLE;

/*!
 The name of the template or function.
 
 @return The name of the ``CTCustomTemplate``.
 */
- (NSString *)templateName
NS_SWIFT_NAME(name());

/*!
 Retrieve a `NSString` argument by `name`.
 
 @return The argument value or `nil` if no such argument is defined for the ``CTCustomTemplate``.
 */
- (nullable NSString *)stringNamed:(NSString *)name
NS_SWIFT_NAME(string(name:));

/*!
 Retrieve a `NSNumber` argument by `name`.
 
 @return The argument value or `nil` if no such argument is defined for the ``CTCustomTemplate``.
 */
- (nullable NSNumber *)numberNamed:(NSString *)name
NS_SWIFT_NAME(number(name:));

/*!
 Retrieve a `char` argument by `name`.
 
 @return The argument value or `0` if no such argument is defined for the ``CTCustomTemplate``.
 */
- (int)charNamed:(NSString *)name
NS_SWIFT_NAME(char(name:));

/*!
 Retrieve an `int` argument by `name`.
 
 @return The argument value or `0` if no such argument is defined for the ``CTCustomTemplate``.
 */
- (int)intNamed:(NSString *)name
NS_SWIFT_NAME(int(name:));

/*!
 Retrieve a `double` argument by `name`.
 
 @return The argument value or `0` if no such argument is defined for the ``CTCustomTemplate``.
 */
- (double)doubleNamed:(NSString *)name
NS_SWIFT_NAME(double(name:));

/*!
 Retrieve a `float` argument by `name`.
 
 @return The argument value or `0` if no such argument is defined for the ``CTCustomTemplate``.
 */
- (float)floatNamed:(NSString *)name
NS_SWIFT_NAME(float(name:));

/*!
 Retrieve a `long` argument by `name`.
 
 @return The argument value or `0` if no such argument is defined for the ``CTCustomTemplate``.
 */
- (long)longNamed:(NSString *)name
NS_SWIFT_NAME(long(name:));

/*!
 Retrieve a `long long` argument by `name`.
 
 @return The argument value or `0` if no such argument is defined for the ``CTCustomTemplate``.
 */
- (long long)longLongNamed:(NSString *)name
NS_SWIFT_NAME(longLong(name:));

/*!
 Retrieve a `BOOL` argument by `name`.
 
 @return The argument value or `NO` if no such argument is defined for the ``CTCustomTemplate``.
 */
- (BOOL)boolNamed:(NSString *)name
NS_SWIFT_NAME(boolean(name:));

/*!
 Retrieve a dictionary of all arguments under `name`. Dictionary arguments will be combined with dot notation arguments. All
 values are converted to their defined type in the ``CTCustomTemplate``. Action arguments are mapped to their
 name as `NSString`. Returns `nil` if no arguments are found for the requested map.
 
 @return A dictionary of all arguments under `name` or `nil`.
 */
- (nullable NSDictionary *)dictionaryNamed:(NSString *)name
NS_SWIFT_NAME(dictionary(name:));

/*!
 Retrieve an absolute file path argument by `name`.
 
 @return The argument value or `nil` if no such argument is defined for the ``CTCustomTemplate``.
 */
- (nullable NSString *)fileNamed:(NSString *)name
NS_SWIFT_NAME(file(name:));

/*!
 Call this method to notify the SDK the ``CTCustomTemplate`` is presented.
 */
- (void)presented;

/*!
 Trigger an action argument by `name`.
 Records a "Notification Clicked" event.
 */
- (void)triggerActionNamed:(NSString *)name
NS_SWIFT_NAME(triggerAction(name:));

/*!
 Notify the SDK that the current ``CTCustomTemplate`` is dismissed. The current ``CTCustomTemplate`` is considered to be
 visible to the user until this method is called. Since the SDK can show only one InApp message at a time, all
 other messages will be queued until the current one is dismissed.
 */
- (void)dismissed;

@end

NS_ASSUME_NONNULL_END
