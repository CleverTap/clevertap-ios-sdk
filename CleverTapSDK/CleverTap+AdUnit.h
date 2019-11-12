#import <Foundation/Foundation.h>
#import "CleverTap.h"

@interface CleverTapAdUnit : NSObject

- (instancetype _Nullable )initWithJSON:(NSDictionary *_Nullable)json;

@property (nullable, nonatomic, copy, readonly) NSDictionary *json;
@property (nullable, nonatomic, copy, readonly) NSString *adID;
@property (nullable, nonatomic, copy, readonly) NSString *type;
@property (nullable, nonatomic, copy, readonly) NSString *title;
@property (nullable, nonatomic, copy, readonly) NSString *body;
@property (nullable, nonatomic, copy, readonly) NSArray  *media;
@property (nullable, nonatomic, copy, readonly) NSArray *links;
@property (nullable, nonatomic, copy, readonly) NSDictionary *customExtras;

@end

//@interface CleverTapAdUnitMedia : NSObject
//
//@property (nullable, nonatomic, copy, readonly) NSString title;
//@property (nullable, nonatomic, copy, readonly) NSString *message;
//@property (nullable, nonatomic, copy, readonly) NSString *mediaUrl;
//
//@end

@protocol CleverTapAdUnitDelegate <NSObject>
@optional
- (void)adUnitIDList:(NSArray *_Nullable)ids;
- (void)adUnits:(NSArray<CleverTapAdUnit *>*_Nullable)adUnits;
@end

typedef void (^CleverTapAdUnitSuccessBlock)(BOOL success);

@interface CleverTap (AdUnit)

- (NSDictionary *_Nullable)getAdUnitCustomExtrasForID:(NSString *_Nonnull)adID;
- (CleverTapAdUnit *_Nullable)getAdUnitForID:(NSString *_Nonnull)adID;

- (void)setAdUnitDelegate:(id <CleverTapAdUnitDelegate>_Nonnull)delegate;
- (void)recordAdUnitViewedEventForID:(NSString *_Nonnull)adID;
- (void)recordAdUnitClickedEventForID:(NSString *_Nonnull)adID;

@end
