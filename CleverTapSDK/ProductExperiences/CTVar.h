#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^CleverTapVariablesChangedBlock)(void);
typedef void (^CleverTapFetchVariablesBlock)(BOOL success);

@class CTVar;
/**
 * Receives callbacks for {@link CTVar}
 */
NS_SWIFT_NAME(VarDelegate)
@protocol CTVarDelegate <NSObject>
@optional
/**
 * Called when the value of the variable changes.
 */
- (void)valueDidChange:(CTVar *)variable;
/**
 * Called when the file is downloaded and ready.
 */
- (void)fileIsReady:(CTVar *)var;
@end

/**
 * A variable is any part of your application that can change from an experiment.
 * Check out {@link Macros the macros} for defining variables more easily.
 */
NS_SWIFT_NAME(Var)
@interface CTVar : NSObject

@property (readonly, strong, nullable) NSString *stringValue;
@property (readonly, strong, nullable) NSNumber *numberValue;
@property (readonly, strong, nullable) id value;
@property (readonly, strong, nullable) id defaultValue;
@property (readonly, strong, nullable) NSString *fileValue;

/**
 * @{
 * Defines a {@link LPVar}
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Returns the name of the variable.
 */
- (NSString *)name;

/**
 * Returns the components of the variable's name.
 */
- (NSArray<NSString *> *)nameComponents;

/**
 * Returns the default value of a variable.
 */
- (nullable id)defaultValue;

/**
 * Returns the kind of the variable.
 */
- (NSString *)kind;

/**
 * Returns whether the variable has changed since the last time the app was run.
 */
- (BOOL)hasChanged;

/**
 * Called when the value of the variable changes.
 */
- (void)onValueChanged:(CleverTapVariablesChangedBlock)block;

/**
 * Called when the value of the file variable is downloaded and ready.
 */
- (void)onFileIsReady:(CleverTapVariablesChangedBlock)block;

/**
 * Sets the delegate of the variable in order to use
 * {@link CTVarDelegate::valueDidChange:}
 */
- (void)setDelegate:(nullable id <CTVarDelegate>)delegate;

- (void)clearState;

/**
 * @{
 * Accessess the value(s) of the variable
 */
- (id)objectForKey:(nullable NSString *)key;
- (id)objectAtIndex:(NSUInteger )index;
- (id)objectForKeyPath:(nullable id)firstComponent, ... NS_REQUIRES_NIL_TERMINATION;
- (id)objectForKeyPathComponents:(nullable NSArray<NSString *> *)pathComponents;

- (nullable NSNumber *)numberValue;
- (nullable NSString *)stringValue;
- (int)intValue;
- (double)doubleValue;
- (CGFloat)cgFloatValue;
- (float)floatValue;
- (short)shortValue;
- (BOOL)boolValue;
- (char)charValue;
- (long)longValue;
- (long long)longLongValue;
- (NSInteger)integerValue;
- (unsigned char)unsignedCharValue;
- (unsigned short)unsignedShortValue;
- (unsigned int)unsignedIntValue;
- (NSUInteger)unsignedIntegerValue;
- (unsigned long)unsignedLongValue;
- (unsigned long long)unsignedLongLongValue;
- (nullable NSString *)fileValue;
/**@}*/
@end

NS_ASSUME_NONNULL_END
