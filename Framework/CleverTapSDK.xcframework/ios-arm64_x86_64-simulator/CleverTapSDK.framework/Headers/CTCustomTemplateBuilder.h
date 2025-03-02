//
//  CTCustomTemplateBuilder.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 6.03.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTTemplatePresenter.h"
#import "CTCustomTemplate.h"

#define TEMPLATE_TYPE @"template"
#define FUNCTION_TYPE @"function"

NS_ASSUME_NONNULL_BEGIN

/*!
 Builder for ``CTCustomTemplate``s creation. Set `name` and  `presenter` before calling ``build``.
 Arguments can be specified by using one of the `addArgument:` methods. Argument names must be unique.
 The "." characters in template arguments' names denote hierarchical structure. 
 They are treated the same way as the keys within dictionaries passed to ``addArgument:withDictionary:``.
 If a higher-level name (to the left of a "." symbol) matches a dictionary argument's name,
 it is treated the same as if the argument was part of the dictionary itself.
 
 For example, the following code snippets define identical arguments:
 ```
 [builder addArgument:@"map" withDictionary:@{
    @"a": @5,
    @"b": @6
 }];
 ```
 and
 ```
 [builder addArgument:@"map.a" withNumber:@5];
 [builder addArgument:@"map.b" withNumber:@6];
 ```
 
 Methods of this class throw `NSException`  with name `CleverTapCustomTemplateException`
 for invalid states or parameters. Defined templates must be correct when the app is running. If such an
 exception is thrown the template definition must be corrected instead of handling the error.
 */
@interface CTCustomTemplateBuilder : NSObject

- (instancetype)init NS_UNAVAILABLE;

/*!
 The name for the template. It should be provided exactly once. 
 It must be unique across template definitions.
 Must be non-blank.
 
 This method throws `NSException`  with name `CleverTapCustomTemplateException` if the name is already set or the provided name is blank.
 */
- (void)setName:(NSString *)name;

- (void)addArgument:(NSString *)name withString:(NSString *)defaultValue
NS_SWIFT_NAME(addArgument(_:string:));

- (void)addArgument:(NSString *)name withNumber:(NSNumber *)defaultValue
NS_SWIFT_NAME(addArgument(_:number:));

- (void)addArgument:(NSString *)name withBool:(BOOL)defaultValue
NS_SWIFT_NAME(addArgument(_:boolean:));

/*!
 Add a dictionary structure to the arguments of the ``CTCustomTemplate``. 
 The `name` should be unique across all arguments and also
 all keys in `defaultValue` should form unique names across all arguments.
 
 @param defaultValue The dictionary must be non-empty. Values can be of type `NSNumber` or `NSString` or another `NSDictionary` which values can also be of the same types.
 */
- (void)addArgument:(nonnull NSString *)name withDictionary:(nonnull NSDictionary *)defaultValue
NS_SWIFT_NAME(addArgument(_:dictionary:));

- (void)addFileArgument:(NSString *)name;

/*!
 The presenter for this template. See ``CTTemplatePresenter``.
 */
- (void)setPresenter:(id<CTTemplatePresenter>)presenter;

/*!
 Creates the ``CTCustomTemplate`` with the previously defined name, arguments and presenter.
 Name and presenter must be set before calling this method.
 
 This method throws `NSException`  with name `CleverTapCustomTemplateException` if name or presenter were not set.
 */
- (CTCustomTemplate *)build;

@end

NS_ASSUME_NONNULL_END
