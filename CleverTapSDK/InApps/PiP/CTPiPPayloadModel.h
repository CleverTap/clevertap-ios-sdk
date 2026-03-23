#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// MARK: - Enums

typedef NS_ENUM(NSUInteger, CTPiPPosition) {
    CTPiPPositionTopLeft,
    CTPiPPositionTopCenter,
    CTPiPPositionTopRight,
    CTPiPPositionCenterLeft,
    CTPiPPositionCenter,
    CTPiPPositionCenterRight,
    CTPiPPositionBottomLeft,
    CTPiPPositionBottomCenter,
    CTPiPPositionBottomRight,
};

typedef NS_ENUM(NSUInteger, CTPiPAnimation) {
    CTPiPAnimationInstant,
    CTPiPAnimationDissolve,
    CTPiPAnimationMoveIn,
};

typedef NS_ENUM(NSUInteger, CTPiPContentType) {
    CTPiPContentTypeImage,
    CTPiPContentTypeGif,
    CTPiPContentTypeVideo,
    CTPiPContentTypeUnknown,
};

typedef NS_ENUM(NSUInteger, CTPiPOnClickActionType) {
    CTPiPOnClickActionTypeClose,
    CTPiPOnClickActionTypeURL,
    CTPiPOnClickActionTypeKV,
    CTPiPOnClickActionTypeCustomCode,
    CTPiPOnClickActionTypeUnknown,
};

// MARK: - CTPiPMediaModel

@interface CTPiPMediaModel : NSObject
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, strong, nullable, readonly) NSURL *posterURL;
@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, readonly) CTPiPContentType contentType;
@property (nonatomic, copy, nullable, readonly) NSString *altText;
@property (nonatomic, strong, nullable, readonly) NSURL *fallbackURL;
@end

// MARK: - CTPiPMarginsModel

@interface CTPiPMarginsModel : NSObject
@property (nonatomic, readonly) CGFloat vertical;
@property (nonatomic, readonly) CGFloat horizontal;
@end

// MARK: - CTPiPAspectRatioModel

@interface CTPiPAspectRatioModel : NSObject
@property (nonatomic, readonly) NSInteger numerator;
@property (nonatomic, readonly) NSInteger denominator;
/// Computed ratio: numerator / denominator (width / height). Returns 1.0 if invalid.
@property (nonatomic, readonly) CGFloat ratio;
@end

// MARK: - CTPiPBorderModel

@interface CTPiPBorderModel : NSObject
@property (nonatomic, readonly) BOOL enabled;
@property (nonatomic, strong, readonly) UIColor *color;
@property (nonatomic, readonly) CGFloat width;
@end

// MARK: - CTPiPControlsModel

@interface CTPiPControlsModel : NSObject
@property (nonatomic, readonly) BOOL drag;
@property (nonatomic, readonly) BOOL playPause;
@property (nonatomic, readonly) BOOL mute;
@property (nonatomic, readonly) BOOL expandCollapse;
@end

// MARK: - CTPiPOnClickModel

@interface CTPiPOnClickModel : NSObject
@property (nonatomic, readonly) CTPiPOnClickActionType type;
/// iOS-specific deeplink/URL. May be nil.
@property (nonatomic, copy, nullable, readonly) NSString *iosURL;
/// Key-value payload for kv action type. May be nil.
@property (nonatomic, strong, nullable, readonly) NSDictionary *kv;
/// Whether to close PiP after executing the action.
@property (nonatomic, readonly) BOOL close;
@end

// MARK: - CTPiPConfigModel

@interface CTPiPConfigModel : NSObject
@property (nonatomic, readonly) CTPiPPosition position;
@property (nonatomic, strong, readonly) CTPiPMarginsModel *margins;
/// Width as % of screen width (e.g. 30 = 30%)
@property (nonatomic, readonly) NSInteger widthPercent;
@property (nonatomic, strong, readonly) CTPiPAspectRatioModel *aspectRatio;
@property (nonatomic, readonly) CGFloat cornerRadius;
@property (nonatomic, strong, readonly) CTPiPBorderModel *border;
@property (nonatomic, strong, readonly) CTPiPControlsModel *controls;
@property (nonatomic, strong, readonly) CTPiPOnClickModel *onClick;
@property (nonatomic, readonly) CTPiPAnimation animation;
@end

// MARK: - CTPiPPayloadModel

@interface CTPiPPayloadModel : NSObject

@property (nonatomic, readonly) BOOL showClose;
@property (nonatomic, readonly) BOOL isNative;
@property (nonatomic, strong, nullable, readonly) CTPiPMediaModel *media;
@property (nonatomic, strong, nullable, readonly) CTPiPConfigModel *config;

/// Parse the full PiP JSON payload.
+ (nullable instancetype)modelFromJSON:(NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
