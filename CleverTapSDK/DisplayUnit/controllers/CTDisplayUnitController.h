#import <Foundation/Foundation.h>
#import "CleverTap+DisplayUnit.h"

@protocol CTDisplayUnitDelegate <NSObject>
@required
- (void)displayUnitsDidUpdate;
@end

@interface CTDisplayUnitController : NSObject

@property (nonatomic, assign, readonly) BOOL isInitialized;
@property (nonatomic, copy, readonly) NSArray <CleverTapDisplayUnit *> * _Nullable displayUnits;

@property (nonatomic, weak) id<CTDisplayUnitDelegate> _Nullable delegate;

- (instancetype _Nullable ) init __unavailable;

// blocking, call off main thread
- (instancetype _Nullable)initWithAccountId:(NSString *_Nonnull)accountId
                                       guid:(NSString *_Nonnull)guid;

- (void)updateDisplayUnits:(NSArray<NSDictionary*> *_Nullable)displayUnits;

@end

