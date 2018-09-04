#import <Foundation/Foundation.h>

@interface CleverTapInstanceConfig () <NSCopying> {}

@property (nonatomic, assign, readonly) BOOL isDefaultInstance;
@property (nonatomic, strong, readonly) NSString* queueLabel;
@property (nonatomic, assign) BOOL isCreatedPostAppLaunched;

- (instancetype _Nonnull)initWithAccountId:( NSString* _Nonnull )accountId
                              accountToken:( NSString* _Nonnull )accountToken
                             accountRegion:(NSString* _Nullable )accountRegion
                         isDefaultInstance:(BOOL)isDefault;

@end
