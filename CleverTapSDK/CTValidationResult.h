#import <Foundation/Foundation.h>
#import "CTValidationConfig.h"

typedef NS_ENUM(NSInteger, CTValidationOutcome) {
    CTValidationOutcomeSuccess = 0,
    CTValidationOutcomeWarning = 1,
    CTValidationOutcomeDrop = 2
};

typedef NS_ENUM(NSInteger, CTDropReason) {
    CTDropReasonNullEventName,
    CTDropReasonRestrictedEventName,
    CTDropReasonDiscardedEventName,
    CTDropReasonEmptyKey,
    CTDropReasonRestrictedMultiValueKey
};

@interface CTValidationResult : NSObject

@property (nonatomic, assign) int errorCode;
@property (nonatomic, strong) NSString *errorDesc;
@property (nonatomic, strong) NSObject *object;

@property (nonatomic, assign) CTValidationOutcome outcome;
@property (nonatomic, assign) CTDropReason dropReason;
@property (nonatomic, strong, nullable) id cleanedData;
@property (nonatomic, strong, nullable) NSArray<CTValidationResult *> *subResults;

- (void)setErrorDesc:(NSString *)errorDsc;
- (void)setObject:(NSObject *)obj;
- (void)setErrorCode:(int)errorCod;

// Legacy compatibility
+ (CTValidationResult *)resultWithErrorCode:(int)code andMessage:(NSString *)message;

// Basic creation methods
+ (CTValidationResult *)success;
+ (CTValidationResult *)successWithData:(id)data;
+ (CTValidationResult *)warningWithCode:(CTValidationErrorCode)code
                                message:(NSString *)message
                                   data:(nullable id)data;
+ (CTValidationResult *)dropWithCode:(int)code
                             message:(NSString *)message
                              reason:(CTDropReason)reason;

// Sub-results methods for nested validation
+ (CTValidationResult *)warningWithSubResults:(NSArray<CTValidationResult *> *)subResults
                                         data:(nullable id)data;
+ (CTValidationResult *)dropWithSubResults:(NSArray<CTValidationResult *> *)subResults
                                    reason:(CTDropReason)reason;

- (BOOL)shouldDrop;

@end
