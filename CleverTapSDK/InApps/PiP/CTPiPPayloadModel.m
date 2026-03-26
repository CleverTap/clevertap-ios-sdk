#import "CTPiPPayloadModel.h"
#import "CTUIUtils.h"

// MARK: - CTPiPMediaModel (Private)

@interface CTPiPMediaModel ()
@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, strong, nullable, readwrite) NSURL *posterURL;
@property (nonatomic, copy, readwrite) NSString *key;
@property (nonatomic, readwrite) CTPiPContentType contentType;
@property (nonatomic, copy, nullable, readwrite) NSString *altText;
@property (nonatomic, strong, nullable, readwrite) NSURL *fallbackURL;
@end

@implementation CTPiPMediaModel

+ (nullable instancetype)modelFromJSON:(NSDictionary *)json {
    if (![json isKindOfClass:[NSDictionary class]]) return nil;
    NSString *urlString = json[@"url"];
    if (urlString.length == 0) return nil;
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return nil;

    CTPiPMediaModel *model = [CTPiPMediaModel new];
    model.url = url;
    model.key = json[@"key"] ?: @"";
    model.altText = json[@"alt_text"];

    NSString *posterString = json[@"poster"];
    if (posterString.length > 0) {
        model.posterURL = [NSURL URLWithString:posterString];
    }
    NSString *fallbackString = json[@"fallback_url"];
    if (fallbackString.length > 0) {
        model.fallbackURL = [NSURL URLWithString:fallbackString];
    }

    NSString *contentType = json[@"content_type"];
    if ([contentType isEqualToString:@"image/gif"]) {
        model.contentType = CTPiPContentTypeGif;
    } else if ([contentType hasPrefix:@"image"]) {
        model.contentType = CTPiPContentTypeImage;
    } else if ([contentType hasPrefix:@"video"]) {
        model.contentType = CTPiPContentTypeVideo;
    } else {
        model.contentType = CTPiPContentTypeUnknown;
    }
    return model;
}

@end

// MARK: - CTPiPMarginsModel (Private)

@interface CTPiPMarginsModel ()
@property (nonatomic, readwrite) CGFloat vertical;
@property (nonatomic, readwrite) CGFloat horizontal;
@end

@implementation CTPiPMarginsModel

+ (instancetype)modelFromJSON:(NSDictionary *)json {
    CTPiPMarginsModel *model = [CTPiPMarginsModel new];
    if ([json isKindOfClass:[NSDictionary class]]) {
        model.vertical = json[@"vertical"] ? [json[@"vertical"] floatValue] : 10.0;
        model.horizontal = json[@"horizontal"] ? [json[@"horizontal"] floatValue] : 10.0;
    } else {
        model.vertical = 10.0;
        model.horizontal = 10.0;
    }
    return model;
}

@end

// MARK: - CTPiPAspectRatioModel (Private)

@interface CTPiPAspectRatioModel ()
@property (nonatomic, readwrite) NSInteger numerator;
@property (nonatomic, readwrite) NSInteger denominator;
@end

@implementation CTPiPAspectRatioModel

+ (instancetype)modelFromJSON:(NSDictionary *)json {
    CTPiPAspectRatioModel *model = [CTPiPAspectRatioModel new];
    if ([json isKindOfClass:[NSDictionary class]]) {
        model.numerator = json[@"numerator"] ? [json[@"numerator"] integerValue] : 9;
        model.denominator = json[@"denominator"] ? [json[@"denominator"] integerValue] : 16;
    } else {
        model.numerator = 9;
        model.denominator = 16;
    }
    return model;
}

- (CGFloat)ratio {
    if (self.numerator <= 0) return 1.0;
    return (CGFloat)self.denominator / (CGFloat)self.numerator;
}

@end

// MARK: - CTPiPBorderModel (Private)

@interface CTPiPBorderModel ()
@property (nonatomic, readwrite) BOOL enabled;
@property (nonatomic, strong, readwrite) UIColor *color;
@property (nonatomic, readwrite) CGFloat width;
@end

@implementation CTPiPBorderModel

+ (instancetype)modelFromJSON:(NSDictionary *)json {
    CTPiPBorderModel *model = [CTPiPBorderModel new];
    if ([json isKindOfClass:[NSDictionary class]]) {
        model.enabled = [json[@"enabled"] boolValue];
        NSString *colorHex = json[@"color"];
        model.color = colorHex.length > 0 ? [CTUIUtils ct_colorWithHexString:colorHex] : UIColor.blackColor;
        model.width = json[@"width"] ? [json[@"width"] floatValue] : 1.0;
    } else {
        model.enabled = NO;
        model.color = UIColor.blackColor;
        model.width = 1.0;
    }
    return model;
}

@end

// MARK: - CTPiPControlsModel (Private)

@interface CTPiPControlsModel ()
@property (nonatomic, readwrite) BOOL drag;
@property (nonatomic, readwrite) BOOL playPause;
@property (nonatomic, readwrite) BOOL mute;
@property (nonatomic, readwrite) BOOL expandCollapse;
@end

@implementation CTPiPControlsModel

+ (instancetype)modelFromJSON:(NSDictionary *)json {
    CTPiPControlsModel *model = [CTPiPControlsModel new];
    if ([json isKindOfClass:[NSDictionary class]]) {
        model.drag = [json[@"drag"] boolValue];
        model.playPause = [json[@"playPause"] boolValue];
        model.mute = [json[@"mute"] boolValue];
        model.expandCollapse = [json[@"expandCollapse"] boolValue];
    }
    return model;
}

@end

// MARK: - CTPiPOnClickModel (Private)

@interface CTPiPOnClickModel ()
@property (nonatomic, readwrite) CTPiPOnClickActionType type;
@property (nonatomic, copy, nullable, readwrite) NSString *iosURL;
@property (nonatomic, strong, nullable, readwrite) NSDictionary *kv;
@property (nonatomic, readwrite) BOOL close;
@end

@implementation CTPiPOnClickModel

+ (instancetype)modelFromJSON:(NSDictionary *)json {
    CTPiPOnClickModel *model = [CTPiPOnClickModel new];
    if ([json isKindOfClass:[NSDictionary class]]) {
        NSString *typeString = json[@"type"];
        if ([typeString isEqualToString:@"close"]) {
            model.type = CTPiPOnClickActionTypeClose;
        } else if ([typeString isEqualToString:@"url"]) {
            model.type = CTPiPOnClickActionTypeURL;
        } else if ([typeString isEqualToString:@"kv"]) {
            model.type = CTPiPOnClickActionTypeKV;
        } else if ([typeString isEqualToString:@"custom-code"]) {
            model.type = CTPiPOnClickActionTypeCustomCode;
        } else {
            model.type = CTPiPOnClickActionTypeUnknown;
        }
        NSString *iosURL = json[@"ios"];
        model.iosURL = iosURL.length > 0 ? iosURL : nil;
        id kv = json[@"kv"];
        model.kv = [kv isKindOfClass:[NSDictionary class]] ? kv : nil;
        model.close = [json[@"close"] boolValue];
    } else {
        model.type = CTPiPOnClickActionTypeUnknown;
    }
    return model;
}

@end

// MARK: - CTPiPAnimationModel (Private)

@interface CTPiPAnimationModel ()
@property (nonatomic, readwrite) CTPiPAnimationType type;
@property (nonatomic, readwrite) NSTimeInterval duration;
@property (nonatomic, readwrite) CTPiPAnimationEasing easing;
@property (nonatomic, readwrite) CGFloat bezierX1;
@property (nonatomic, readwrite) CGFloat bezierY1;
@property (nonatomic, readwrite) CGFloat bezierX2;
@property (nonatomic, readwrite) CGFloat bezierY2;
@property (nonatomic, readwrite) CTPiPMoveInDirection moveInDirection;
@end

@implementation CTPiPAnimationModel

+ (instancetype)modelFromJSON:(NSDictionary *)json {
    CTPiPAnimationModel *model = [CTPiPAnimationModel new];

    // Type
    NSString *typeStr = [json isKindOfClass:[NSDictionary class]] ? json[@"type"] : nil;
    if ([typeStr isEqualToString:@"dissolve"]) {
        model.type = CTPiPAnimationTypeDissolve;
    } else if ([typeStr isEqualToString:@"movein"]) {
        model.type = CTPiPAnimationTypeMoveIn;
    } else {
        model.type = CTPiPAnimationTypeInstant;
    }

    // Duration — JSON is in milliseconds, convert to seconds; sensible defaults per type
    NSTimeInterval defaultDuration = (model.type == CTPiPAnimationTypeMoveIn) ? 0.4 : 0.3;
    id rawDuration = [json isKindOfClass:[NSDictionary class]] ? json[@"duration"] : nil;
    model.duration = rawDuration ? ([rawDuration doubleValue] / 1000.0) : defaultDuration;
    if (model.duration <= 0) { model.duration = defaultDuration; }

    // Easing
    NSString *easingStr = [json isKindOfClass:[NSDictionary class]] ? json[@"easing"] : nil;
    if ([easingStr isEqualToString:@"linear"]) {
        model.easing = CTPiPAnimationEasingLinear;
    } else if ([easingStr isEqualToString:@"ease-in"]) {
        model.easing = CTPiPAnimationEasingEaseIn;
    } else if ([easingStr isEqualToString:@"ease-out"]) {
        model.easing = CTPiPAnimationEasingEaseOut;
    } else if ([easingStr isEqualToString:@"cubic-bezier"]) {
        model.easing = CTPiPAnimationEasingCubicBezier;
    } else {
        model.easing = CTPiPAnimationEasingEaseInOut; // default
    }

    // Bezier control points — "x1,y1,x2,y2"
    NSString *bezierStr = [json isKindOfClass:[NSDictionary class]] ? json[@"bezier"] : nil;
    if (bezierStr.length > 0) {
        NSArray<NSString *> *parts = [bezierStr componentsSeparatedByString:@","];
        if (parts.count == 4) {
            model.bezierX1 = [parts[0] floatValue];
            model.bezierY1 = [parts[1] floatValue];
            model.bezierX2 = [parts[2] floatValue];
            model.bezierY2 = [parts[3] floatValue];
        }
    }

    // MoveIn direction
    NSString *dirStr = [json isKindOfClass:[NSDictionary class]] ? json[@"moveInDirection"] : nil;
    if ([dirStr isEqualToString:@"left"]) {
        model.moveInDirection = CTPiPMoveInDirectionLeft;
    } else if ([dirStr isEqualToString:@"right"]) {
        model.moveInDirection = CTPiPMoveInDirectionRight;
    } else if ([dirStr isEqualToString:@"top"]) {
        model.moveInDirection = CTPiPMoveInDirectionTop;
    } else {
        model.moveInDirection = CTPiPMoveInDirectionBottom; // default
    }

    return model;
}

@end

// MARK: - CTPiPConfigModel (Private)

@interface CTPiPConfigModel ()
@property (nonatomic, readwrite) CTPiPPosition position;
@property (nonatomic, strong, readwrite) CTPiPMarginsModel *margins;
@property (nonatomic, readwrite) NSInteger widthPercent;
@property (nonatomic, strong, readwrite) CTPiPAspectRatioModel *aspectRatio;
@property (nonatomic, readwrite) CGFloat cornerRadius;
@property (nonatomic, strong, readwrite) CTPiPBorderModel *border;
@property (nonatomic, strong, readwrite) CTPiPControlsModel *controls;
@property (nonatomic, strong, readwrite) CTPiPOnClickModel *onClick;
@property (nonatomic, strong, readwrite) CTPiPAnimationModel *animation;
@end

@implementation CTPiPConfigModel

+ (instancetype)modelFromJSON:(NSDictionary *)json {
    CTPiPConfigModel *model = [CTPiPConfigModel new];

    NSString *positionString = json[@"position"] ?: @"bottom-right";
    model.position = [CTPiPConfigModel positionFromString:positionString];

    model.margins = [CTPiPMarginsModel modelFromJSON:json[@"margins"]];

    NSInteger wp = json[@"width"] ? [json[@"width"] integerValue] : 30;
    model.widthPercent = MAX(10, MIN(wp, 100));

    model.aspectRatio = [CTPiPAspectRatioModel modelFromJSON:json[@"aspectRatio"]];
    model.cornerRadius = json[@"cornerRadius"] ? [json[@"cornerRadius"] floatValue] : 4.0;
    model.border = [CTPiPBorderModel modelFromJSON:json[@"border"]];
    model.controls = [CTPiPControlsModel modelFromJSON:json[@"controls"]];
    model.onClick = [CTPiPOnClickModel modelFromJSON:json[@"onClick"]];
    model.animation = [CTPiPAnimationModel modelFromJSON:json[@"animation"]];

    return model;
}

+ (CTPiPPosition)positionFromString:(NSString *)string {
    NSDictionary<NSString *, NSNumber *> *map = @{
        @"top-left":      @(CTPiPPositionTopLeft),
        @"top-center":    @(CTPiPPositionTopCenter),
        @"top-right":     @(CTPiPPositionTopRight),
        @"center-left":   @(CTPiPPositionCenterLeft),
        @"center":        @(CTPiPPositionCenter),
        @"center-right":  @(CTPiPPositionCenterRight),
        @"bottom-left":   @(CTPiPPositionBottomLeft),
        @"bottom-center": @(CTPiPPositionBottomCenter),
        @"bottom-right":  @(CTPiPPositionBottomRight),
    };
    NSNumber *value = map[string];
    return value ? [value unsignedIntegerValue] : CTPiPPositionBottomRight;
}

@end

// MARK: - CTPiPPayloadModel (Private)

@interface CTPiPPayloadModel ()
@property (nonatomic, readwrite) BOOL showClose;
@property (nonatomic, readwrite) BOOL isNative;
@property (nonatomic, strong, nullable, readwrite) CTPiPMediaModel *media;
@property (nonatomic, strong, nullable, readwrite) CTPiPConfigModel *config;
@end

@implementation CTPiPPayloadModel

+ (nullable instancetype)modelFromJSON:(NSDictionary *)json {
    if (![json isKindOfClass:[NSDictionary class]]) return nil;

    CTPiPPayloadModel *model = [CTPiPPayloadModel new];
    model.showClose = [json[@"close"] boolValue];
    model.isNative = json[@"is_native"] ? [json[@"is_native"] boolValue] : YES;

    NSDictionary *mediaDic = json[@"media"];
    model.media = [CTPiPMediaModel modelFromJSON:mediaDic];

    NSDictionary *pipDic = json[@"pip"];
    if ([pipDic isKindOfClass:[NSDictionary class]]) {
        model.config = [CTPiPConfigModel modelFromJSON:pipDic];
    }

    return model;
}

@end
