#import <CommonCrypto/CommonDigest.h>
#import "CTABTestEditorSnapshotMessageResponse.h"

NSString *const CTABTestEditorSnapshotMessageResponseType = @"snapshot_response";

@implementation CTABTestEditorSnapshotMessageResponse

+ (instancetype)message {
    return [[[self class] alloc] initWithType:CTABTestEditorSnapshotMessageResponseType];
}

- (void)setScreenshot:(UIImage *)screenshot {
    id dataObject = nil;
    id imageHash = nil;
    if (screenshot) {
        NSData *jpegSnapshotImageData = UIImageJPEGRepresentation(screenshot, 0.5);
        if (jpegSnapshotImageData) {
            dataObject = [jpegSnapshotImageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            imageHash = [self getImageHash:jpegSnapshotImageData];
        }
    }
    
    _imageHash = imageHash;
    [self setDataObject:(dataObject ?: [NSNull null]) forKey:@"screenshot"];
    [self setDataObject:(imageHash ?: [NSNull null]) forKey:@"image_hash"];
}

- (UIImage *)screenshot {
    NSString *base64Image = [self dataObjectForKey:@"screenshot"];
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64Image
                                                            options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return imageData ? [UIImage imageWithData:imageData] : nil;
}

- (void)setSerializedObjects:(NSDictionary *)serializedObjects {
    [self setDataObject:serializedObjects forKey:@"serialized_objects"];
}

- (NSDictionary *)serializedObjects {
    return [self dataObjectForKey:@"serialized_objects"];
}

- (NSString *)getImageHash:(NSData *)imageData {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(imageData.bytes, (uint)imageData.length, result);
    NSString *imageHash = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                           result[0], result[1], result[2], result[3],
                           result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11],
                           result[12], result[13], result[14], result[15]];
    return imageHash;
}

- (NSString *)orientation {
    return [self dataObjectForKey:@"orientation"];
}

- (void)setOrientation:(NSString *)orientation {
    [self setDataObject:orientation forKey:@"orientation"];
}



@end
