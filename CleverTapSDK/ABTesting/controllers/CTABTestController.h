
#import <Foundation/Foundation.h>
#import "CTABVariant.h"
#import "CTDeviceInfo.h"

@protocol CTABTestingDelegate <NSObject>
@required
- (void)abExperimentsDidUpdate;
- (CTDeviceInfo* _Nonnull)getDeviceInfo;

@end

@class CleverTapInstanceConfig;

@interface CTABTestController : NSObject

@property (nonatomic, weak) id<CTABTestingDelegate> _Nullable delegate;

- (instancetype _Nullable)initWithConfig:(CleverTapInstanceConfig *_Nonnull)config
                                    guid:(NSString *_Nonnull)guid
                                delegate:(id<CTABTestingDelegate>_Nonnull)delegate;
- (void)updateExperiments:(NSArray<NSDictionary*> *_Nonnull)experiments;
- (void)resetWithGuid:(NSString* _Nullable)guid;

- (void)registerBoolVariableWithName:(NSString* _Nonnull)name;
- (void)registerDoubleVariableWithName:(NSString* _Nonnull)name;
- (void)registerIntegerVariableWithName:(NSString* _Nonnull)name;
- (void)registerStringVariableWithName:(NSString* _Nonnull)name;

- (void)registerArrayOfBoolVariableWithName:(NSString* _Nonnull)name;
- (void)registerArrayOfDoubleVariableWithName:(NSString* _Nonnull)name;
- (void)registerArrayOfIntegerVariableWithName:(NSString* _Nonnull)name;
- (void)registerArrayOfStringVariableWithName:(NSString* _Nonnull)name;

- (void)registerDictionaryOfBoolVariableWithName:(NSString* _Nonnull)name;
- (void)registerDictionaryOfDoubleVariableWithName:(NSString* _Nonnull)name;
- (void)registerDictionaryOfIntegerVariableWithName:(NSString* _Nonnull)name;
- (void)registerDictionaryOfStringVariableWithName:(NSString* _Nonnull)name;


- (BOOL)getBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(BOOL)defaultValue;
- (double)getDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(double)defaultValue;
- (int)getIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(int)defaultValue;
- (NSString* _Nonnull)getStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSString * _Nonnull)defaultValue;

- (NSArray<NSNumber*>* _Nonnull)getArrayOfBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue;
- (NSArray<NSNumber*>* _Nonnull)getArrayOfDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue;
- (NSArray<NSNumber*>* _Nonnull)getArrayOfIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue;
- (NSArray<NSString*>* _Nonnull)getArrayOfStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSString*>* _Nonnull)defaultValue;

- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue;
- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue;
- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue;
- (NSDictionary<NSString*, NSString*>* _Nonnull)getDictionaryOfStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSString*>* _Nonnull)defaultValue;


@end
