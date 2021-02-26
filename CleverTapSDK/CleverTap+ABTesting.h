#import <Foundation/Foundation.h>
#import "CleverTap.h"

/**
 **NOTE: Deprecation Notice - These method has been deprecated by CleverTap, this code will be removed from future versions of the CleverTap iOS SDK.
*/

typedef void (^CleverTapExperimentsUpdatedBlock)(void);

@interface CleverTap (ABTesting)

/*!
 @method
 
 @abstract
 Set the enabled state of the UIEditor connection
 
 @discussion
 If enabled, the SDK will allow remote configuration of visual UI Edits
 The Editor connection is Disabled by default
 
 @param enabled  whether the editor is enabled
 */
+ (void)setUIEditorConnectionEnabled:(BOOL)enabled __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Get whether the UIEditor connection to the CleverTap dashboard is enabled
 
 @discussion
 Returns whether the UIEditor connection is enabled.
 */
+ (BOOL)isUIEditorConnectionEnabled __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a callback block when experiments are updated.
 */
- (void)registerExperimentsUpdatedBlock:(CleverTapExperimentsUpdatedBlock _Nonnull)block __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a bool dynamic variable with a specified name and default value.
 */
- (void)registerBoolVariableWithName:(NSString* _Nonnull)name __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a double dynamic variable with a specified name and default value.
 */
- (void)registerDoubleVariableWithName:(NSString* _Nonnull)name __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a integer dynamic variable with a specified name and default value.
 */
- (void)registerIntegerVariableWithName:(NSString* _Nonnull)name __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a string dynamic variable with a specified name and default value.
 */
- (void)registerStringVariableWithName:(NSString* _Nonnull)name __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a dynamic variable of an array containing bools with a specified name and default value.
 */
- (void)registerArrayOfBoolVariableWithName:(NSString* _Nonnull)name __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a dynamic variable of an array containing doubles with a specified name and default value.
 */
- (void)registerArrayOfDoubleVariableWithName:(NSString* _Nonnull)name __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a dynamic variable of an array containing integers with a specified name and default value.
 */
- (void)registerArrayOfIntegerVariableWithName:(NSString* _Nonnull)name __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a dynamic variable of an array containing strings with a specified name and default value.
 */
- (void)registerArrayOfStringVariableWithName:(NSString* _Nonnull)name __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a dynamic variable of an dictionary with key/value pairs of string/bool with a specified name and default value.
 */
- (void)registerDictionaryOfBoolVariableWithName:(NSString* _Nonnull)name __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a dynamic variable of an dictionary with key/value pairs of string/double with a specified name and default value.
 */
- (void)registerDictionaryOfDoubleVariableWithName:(NSString* _Nonnull)name __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a dynamic variable of an dictionary with key/value pairs of string/integer with a specified name and default value.
 */
- (void)registerDictionaryOfIntegerVariableWithName:(NSString* _Nonnull)name __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Register a dynamic variable of an dictionary with key/value pairs of string/string with a specified name and default value.
 */
- (void)registerDictionaryOfStringVariableWithName:(NSString* _Nonnull)name __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Retrieve a bool dynamic variable that has already been declared.
 */
- (BOOL)getBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(BOOL)defaultValue __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Retrieve a double dynamic variable that has already been declared.
 */
- (double)getDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(double)defaultValue __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Retrieve a integer dynamic variable that has already been declared.
 */
- (int)getIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(int)defaultValue __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Retrieve a string dynamic variable that has already been declared.
 */
- (NSString* _Nonnull)getStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSString * _Nonnull)defaultValue __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Retrieve a bool array dynamic variable that has already been declared.
 */
- (NSArray<NSNumber*>* _Nonnull)getArrayOfBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Retrieve a double array dynamic variable that has already been declared.
 */
- (NSArray<NSNumber*>* _Nonnull)getArrayOfDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Retrieve a integer array dynamic variable that has already been declared.
 */
- (NSArray<NSNumber*>* _Nonnull)getArrayOfIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Retrieve a string array dynamic variable that has already been declared.
 */
- (NSArray<NSString*>* _Nonnull)getArrayOfStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSString*>* _Nonnull)defaultValue __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Retrieve a bool dictionary dynamic variable that has already been declared.
 */
- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Retrieve a double dictionary dynamic variable that has already been declared.
 */
- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Retrieve a integer dictionary dynamic variable that has already been declared.
 */
- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue __attribute((deprecated()));

/*!
 @method
 
 @abstract
 Retrieve a string dictionary dynamic variable that has already been declared.
 */
- (NSDictionary<NSString*, NSString*>* _Nonnull)getDictionaryOfStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSString*>* _Nonnull)defaultValue __attribute((deprecated()));

@end
