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

typedef NS_ENUM(NSUInteger, CTPiPAnimationType) {
    CTPiPAnimationTypeInstant,
    CTPiPAnimationTypeDissolve,
    CTPiPAnimationTypeMoveIn,
};

typedef NS_ENUM(NSUInteger, CTPiPAnimationEasing) {
    CTPiPAnimationEasingLinear,
    CTPiPAnimationEasingEaseIn,
    CTPiPAnimationEasingEaseOut,
    CTPiPAnimationEasingEaseInOut,
    CTPiPAnimationEasingCubicBezier,
};

typedef NS_ENUM(NSUInteger, CTPiPMoveInDirection) {
    CTPiPMoveInDirectionLeft,
    CTPiPMoveInDirectionRight,
    CTPiPMoveInDirectionTop,
    CTPiPMoveInDirectionBottom,
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

// MARK: - CTPiPAnimationModel

@interface CTPiPAnimationModel : NSObject
@property (nonatomic, readonly) CTPiPAnimationType type;
/// Duration in seconds. Defaults: dissolve = 0.3, movein = 0.4.
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) CTPiPAnimationEasing easing;
/// Cubic-bezier control points parsed from e.g. "0.42,0,0.58,1". Only valid when easing == CubicBezier.
@property (nonatomic, readonly) CGFloat bezierX1;
@property (nonatomic, readonly) CGFloat bezierY1;
@property (nonatomic, readonly) CGFloat bezierX2;
@property (nonatomic, readonly) CGFloat bezierY2;
/// Slide-in direction. Only relevant when type == MoveIn.
@property (nonatomic, readonly) CTPiPMoveInDirection moveInDirection;
+ (instancetype)modelFromJSON:(nullable NSDictionary *)json;
@end

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
/// Vertical margin as a percentage of the container height (e.g. 2 = 2%).
@property (nonatomic, readonly) CGFloat vertical;
/// Horizontal margin as a percentage of the container width (e.g. 2 = 2%).
@property (nonatomic, readonly) CGFloat horizontal;
@end

// MARK: - CTPiPAspectRatioModel

@interface CTPiPAspectRatioModel : NSObject
@property (nonatomic, readonly) CGFloat numerator;
@property (nonatomic, readonly) CGFloat denominator;
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
/// Raw onClick JSON — used by custom-code to build a CTNotificationAction with
/// the full template name and vars without re-parsing the payload.
@property (nonatomic, strong, nullable, readonly) NSDictionary *rawJSON;
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
@property (nonatomic, strong, readonly) CTPiPAnimationModel *animation;
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
