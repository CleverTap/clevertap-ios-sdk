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

- (void)setErrorDesc:(NSString *_Nullable)errorDsc;
- (void)setObject:(NSObject *_Nullable)obj;
- (void)setErrorCode:(int)errorCod;

// Legacy compatibility
+ (CTValidationResult *_Nullable)resultWithErrorCode:(int)code andMessage:(NSString *_Nonnull)message;

// Basic creation methods
+ (CTValidationResult *_Nullable)successWithData:(id _Nullable )data;
+ (CTValidationResult *_Nullable)warningWithCode:(CTValidationErrorCode)code message:(NSString *_Nullable)message data:(nullable id)data;
+ (CTValidationResult *_Nullable)dropWithCode:(int)code message:(NSString *_Nullable)message reason:(CTDropReason)reason;

// Sub-results methods for nested validation
+ (CTValidationResult *_Nullable)warningWithSubResults:(NSArray<CTValidationResult *> *_Nullable)subResults data:(nullable id)data;
+ (CTValidationResult *_Nullable)dropWithSubResults:(NSArray<CTValidationResult *> *_Nullable)subResults reason:(CTDropReason)reason;

- (BOOL)shouldDrop;

@end
