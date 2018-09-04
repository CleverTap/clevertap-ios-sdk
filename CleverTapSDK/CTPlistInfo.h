#import <Foundation/Foundation.h>

@interface CTPlistInfo : NSObject

@property (nonatomic, strong, readonly) NSString *accountId;
@property (nonatomic, strong, readonly) NSString *accountToken;
@property (nonatomic, strong, readonly) NSString *accountRegion;
@property (nonatomic, strong, readonly) NSArray<NSString*>* registeredUrlSchemes;
@property (nonatomic, assign, readonly) BOOL useIDFA;
@property (nonatomic, assign, readonly) BOOL disableAppLaunchedEvent;

+ (instancetype)sharedInstance;
- (void)changeCredentialsWithAccountID:(NSString * _Nonnull)accountID token:(NSString * _Nonnull)token region:(NSString * _Nullable)region;

@end
