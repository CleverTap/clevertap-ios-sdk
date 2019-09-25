#import <Foundation/Foundation.h>

@class CTValidationResult;
@class CTLocalDataStore;

@interface CTProfileBuilder : NSObject

+ (void)build:(NSDictionary *_Nonnull)profile completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildGraphUser:(id _Nonnull)graphUser completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildGooglePlusUser:(id _Nonnull)googleUser completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildRemoveValueForKey:(NSString *_Nonnull)key completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildSetMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nullable)key localDataStore:(CTLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildAddMultiValue:(NSString *_Nonnull)value forKey:(NSString *_Nullable)key localDataStore:(CTLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildAddMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nullable)key localDataStore:(CTLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildRemoveMultiValue:(NSString *_Nonnull)value forKey:(NSString *_Nullable)key localDataStore:(CTLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildRemoveMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nullable)key localDataStore:(CTLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion;

@end
