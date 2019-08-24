#import <Foundation/Foundation.h>

@interface CTPlistInfo : NSObject

@property (nonatomic, strong, readonly, nullable) NSString *accountId;
@property (nonatomic, strong, readonly, nullable) NSString *accountToken;
@property (nonatomic, strong, readonly, nullable) NSString *accountRegion;
@property (nonatomic, strong, readonly, nullable) NSArray<NSString*>* registeredUrlSchemes;
@property (nonatomic, assign, readonly) BOOL useIDFA;
@property (nonatomic, assign, readonly) BOOL disableAppLaunchedEvent;
@property (nonatomic, assign, readonly) BOOL useCustomCleverTapId;
@property (nonatomic, assign, readonly) BOOL beta;

+ (instancetype _Nullable)sharedInstance;
- (void)changeCredentialsWithAccountID:(NSString * _Nonnull)accountID token:(NSString * _Nonnull)token region:(NSString * _Nullable)region;

@end
