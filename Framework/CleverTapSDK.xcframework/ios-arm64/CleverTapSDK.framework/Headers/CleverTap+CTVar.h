//
//  CleverTap+CTVar.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 18/02/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CleverTap.h"
@class CTVar;

NS_ASSUME_NONNULL_BEGIN

@interface CleverTap (Vars)

- (CTVar *)defineVar:(NSString *)name
NS_SWIFT_NAME(defineVar(name:));
- (CTVar *)defineVar:(NSString *)name withInt:(int)defaultValue
NS_SWIFT_NAME(defineVar(name:integer:));
- (CTVar *)defineVar:(NSString *)name withFloat:(float)defaultValue
NS_SWIFT_NAME(defineVar(name:float:));
- (CTVar *)defineVar:(NSString *)name withDouble:(double)defaultValue
NS_SWIFT_NAME(defineVar(name:double:));
- (CTVar *)defineVar:(NSString *)name withCGFloat:(CGFloat)cgFloatValue
NS_SWIFT_NAME(defineVar(name:cgFloat:));
- (CTVar *)defineVar:(NSString *)name withShort:(short)defaultValue
NS_SWIFT_NAME(defineVar(name:short:));
- (CTVar *)defineVar:(NSString *)name withBool:(BOOL)defaultValue
NS_SWIFT_NAME(defineVar(name:boolean:));
- (CTVar *)defineVar:(NSString *)name withString:(nullable NSString *)defaultValue
NS_SWIFT_NAME(defineVar(name:string:));
- (CTVar *)defineVar:(NSString *)name withNumber:(nullable NSNumber *)defaultValue
NS_SWIFT_NAME(defineVar(name:number:));
- (CTVar *)defineVar:(NSString *)name withInteger:(NSInteger)defaultValue
NS_SWIFT_NAME(defineVar(name:NSInteger:));
- (CTVar *)defineVar:(NSString *)name withLong:(long)defaultValue
NS_SWIFT_NAME(defineVar(name:long:));
- (CTVar *)defineVar:(NSString *)name withLongLong:(long long)defaultValue
NS_SWIFT_NAME(defineVar(name:longLong:));
- (CTVar *)defineVar:(NSString *)name withUnsignedChar:(unsigned char)defaultValue
NS_SWIFT_NAME(defineVar(name:unsignedChar:));
- (CTVar *)defineVar:(NSString *)name withUnsignedInt:(unsigned int)defaultValue
NS_SWIFT_NAME(defineVar(name:unsignedInt:));
- (CTVar *)defineVar:(NSString *)name withUnsignedInteger:(NSUInteger)defaultValue
NS_SWIFT_NAME(defineVar(name:unsignedInteger:));
- (CTVar *)defineVar:(NSString *)name withUnsignedLong:(unsigned long)defaultValue
NS_SWIFT_NAME(defineVar(name:unsignedLong:));
- (CTVar *)defineVar:(NSString *)name withUnsignedLongLong:(unsigned long long)defaultValue
NS_SWIFT_NAME(defineVar(name:unsignedLongLong:));
- (CTVar *)defineVar:(NSString *)name withUnsignedShort:(unsigned short)defaultValue
NS_SWIFT_NAME(defineVar(name:UnsignedShort:));
- (CTVar *)defineVar:(NSString *)name withDictionary:(nullable NSDictionary *)defaultValue
NS_SWIFT_NAME(defineVar(name:dictionary:));
- (CTVar *)defineFileVar:(NSString *)name
NS_SWIFT_NAME(defineFileVar(name:));

@end

NS_ASSUME_NONNULL_END
