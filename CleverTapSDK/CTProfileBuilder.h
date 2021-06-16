#import <Foundation/Foundation.h>

@class CTValidationResult;
@class CTLocalDataStore;

@interface CTProfileBuilder : NSObject

+ (void)build:(NSDictionary *_Nonnull)profile completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildRemoveValueForKey:(NSString *_Nonnull)key completionHandler:(void(^ _Nonnull )(NSDictionary *_Nullable customFields, NSDictionary *_Nullable systemFields, NSArray<CTValidationResult*> *_Nullable errors))completion;

+ (void)buildSetMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nullable)key localDataStore:(CTLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary *_Nullable customFields, NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*> *_Nullable errors))completion;

+ (void)buildAddMultiValue:(NSString *_Nonnull)value forKey:(NSString *_Nullable)key localDataStore:(CTLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary *_Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildAddMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nullable)key localDataStore:(CTLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary *_Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*> *_Nullable errors))completion;

+ (void)buildRemoveMultiValue:(NSString *_Nonnull)value forKey:(NSString *_Nullable)key localDataStore:(CTLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary *_Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*> *_Nullable errors))completion;

+ (void)buildRemoveMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nullable)key localDataStore:(CTLocalDataStore*_Nullable)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary *_Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*> *_Nullable errors))completion;

+ (void)buildIncrementValueBy:(NSNumber *_Nonnull)value forKey: (NSString *_Nonnull)key localDataStore:(CTLocalDataStore* _Nonnull)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary *_Nullable operatorDict, NSNumber *_Nullable updatedValue, NSArray<CTValidationResult*> *_Nullable errors))completion;

+ (void)buildDecrementValueBy:(NSNumber *_Nonnull)value forKey: (NSString *_Nonnull)key localDataStore:(CTLocalDataStore* _Nonnull)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary *_Nullable operatorDict, NSNumber *_Nullable updatedValue, NSArray<CTValidationResult*> *_Nullable errors))completion;

@end
