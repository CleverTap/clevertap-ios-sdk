#import <Foundation/Foundation.h>

@class CTValidationResult;
@class CTLocalDataStore;

@interface CTProfileBuilder : NSObject

+ (void)build:(NSDictionary *)profile completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildGraphUser:(id)graphUser completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildGooglePlusUser:(id)googleUser completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildRemoveValueForKey:(NSString *)key completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildSetMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildAddMultiValue:(NSString *)value forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildAddMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildRemoveMultiValue:(NSString *)value forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildRemoveMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion;

@end
