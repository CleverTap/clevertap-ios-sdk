#import <Foundation/Foundation.h>

@interface CTValidationResult : NSObject

- (NSString *)errorDesc;

- (NSObject *)object;

- (int)errorCode;

- (void)setErrorDesc:(NSString *)errorDsc;

- (void)setObject:(NSObject *)obj;

- (void)setErrorCode:(int)errorCod;

+ (CTValidationResult *) resultWithErrorCode:(int) code andMessage:(NSString*) message;

@end
