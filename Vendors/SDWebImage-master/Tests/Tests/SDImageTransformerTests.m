/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import "UIColor+SDHexString.h"
#import <CoreImage/CoreImage.h>

static void SDAssertCGImagePixelFormatEqual(CGImageRef image1, CGImageRef image2) {
    CGBitmapInfo bitmapInfo1 = CGImageGetBitmapInfo(image1);
    CGBitmapInfo bitmapInfo2 = CGImageGetBitmapInfo(image2);
//    XCTAssertEqual(bitmapInfo1, bitmapInfo2);
    CGImageAlphaInfo alphaInfo1 = bitmapInfo1 & kCGBitmapAlphaInfoMask;
    CGImageAlphaInfo alphaInfo2 = bitmapInfo2 & kCGBitmapAlphaInfoMask;
    XCTAssertEqual(alphaInfo1, alphaInfo2);
    CGImageByteOrderInfo byteOrderInfo1 = bitmapInfo1 & kCGBitmapByteOrderMask;
    CGImageByteOrderInfo byteOrderInfo2 = bitmapInfo2 & kCGBitmapByteOrderMask;
    // Note: Known issue that iOS 17.0~17.2 contains BUG that vImage convert CGImage does not keep byteOrder for 16bit
    // The Buggy API is: `vImageCreateCGImageFromBuffer`, the `format`'s bitmap info will be ignored.
    if (byteOrderInfo1 != byteOrderInfo2) {
        NSLog(@"SDAssertCGImagePixelFormatEqual: mismatched byte order info, maybe Apple's Bug on iOS 17.0-17.2");
    }
    if (@available(iOS 12.0, tvOS 12.0, macOS 10.14, watchOS 5.0, *)) {
        XCTAssertEqual(CGImageGetPixelFormatInfo(image1), CGImageGetPixelFormatInfo(image2));
    }
    XCTAssertEqual(CGImageGetColorSpace(image1), CGImageGetColorSpace(image2));
    XCTAssertEqual(CGImageGetBitsPerPixel(image1), CGImageGetBitsPerPixel(image2));
    XCTAssertEqual(CGImageGetBitsPerComponent(image1), CGImageGetBitsPerComponent(image2));
    XCTAssertEqual(CGImageGetRenderingIntent(image1), CGImageGetRenderingIntent(image2));
    XCTAssertEqual(CGImageGetShouldInterpolate(image1), CGImageGetShouldInterpolate(image2));
}

// TODO: Current sd_colorAtPoint: support 8-bits only, 16bits and float color will fail...
// So I write this `SDAssertCGImageFirstComponentWhite` :(
static void SDAssertCGImageFirstComponentWhite(CGImageRef image, OSType pixelType) {
    CGDataProviderRef provider = CGImageGetDataProvider(image);
    CFDataRef data = CGDataProviderCopyData(provider);
    if (pixelType == kCVPixelFormatType_128RGBAFloat) {
        float *buffer = (float *)CFDataGetBytePtr(data);
        float r = buffer[0];
        float g = buffer[1];
        float b = buffer[2];
        float a = buffer[3];
        XCTAssertEqual(r, 1.0);
        XCTAssertEqual(g, 1.0);
        XCTAssertEqual(b, 1.0);
        XCTAssertEqual(a, 1.0);
    } else if (pixelType == kCVPixelFormatType_64RGBALE) {
        uint16_t *buffer = (uint16_t *)CFDataGetBytePtr(data);
        uint16_t r = buffer[0];
        uint16_t g = buffer[1];
        uint16_t b = buffer[2];
        uint16_t a = buffer[3];
        XCTAssertEqual(r, UINT16_MAX);
        XCTAssertEqual(g, UINT16_MAX);
        XCTAssertEqual(b, UINT16_MAX);
        XCTAssertEqual(a, UINT16_MAX);
    } else if (pixelType == kCVPixelFormatType_32ARGB) {
        uint8_t *buffer = (uint8_t *)CFDataGetBytePtr(data);
        uint8_t a = buffer[0];
        uint8_t r = buffer[1];
        uint8_t g = buffer[2];
        uint8_t b = buffer[3];
        XCTAssertEqual(a, UINT8_MAX);
        XCTAssertEqual(r, UINT8_MAX);
        XCTAssertEqual(g, UINT8_MAX);
        XCTAssertEqual(b, UINT8_MAX);
    } else if (pixelType == kCVPixelFormatType_24RGB) {
        uint8_t *buffer = (uint8_t *)CFDataGetBytePtr(data);
        uint8_t r = buffer[0];
        uint8_t g = buffer[1];
        uint8_t b = buffer[2];
        XCTAssertEqual(r, UINT8_MAX);
        XCTAssertEqual(g, UINT8_MAX);
        XCTAssertEqual(b, UINT8_MAX);
    } else if (pixelType == kCVPixelFormatType_48RGB) {
        uint16_t *buffer = (uint16_t *)CFDataGetBytePtr(data);
        uint16_t r = buffer[0];
        uint16_t g = buffer[1];
        uint16_t b = buffer[2];
        XCTAssertEqual(r, UINT16_MAX);
        XCTAssertEqual(g, UINT16_MAX);
        XCTAssertEqual(b, UINT16_MAX);
    } else {
        XCTFail(@"Should not hit here");
    }
    CFRelease(data);
}

@interface SDImageTransformerTests : SDTestCase

@property (nonatomic, strong) UIImage *testImageCG;
@property (nonatomic, strong) UIImage *testImageCI;

@end

@implementation SDImageTransformerTests

#pragma mark - UIImage+Transform

// UIImage+Transform test is hard to write because it's more about visual effect. Current it's tied to the `TestImage.png`, please keep that image or write new test with new image
- (void)test01UIImageTransformResizeCG {
    [self test01UIImageTransformResizeWithImage:self.testImageCG];
}

- (void)test01UIImageTransformResizeCI {
    [self test01UIImageTransformResizeWithImage:self.testImageCI];
}

- (void)test01UIImageTransformResizeWithImage:(UIImage *)testImage {
    CGSize scaleDownSize = CGSizeMake(200, 100);
    UIImage *scaledDownImage = [testImage sd_resizedImageWithSize:scaleDownSize scaleMode:SDImageScaleModeFill];
    expect(CGSizeEqualToSize(scaledDownImage.size, scaleDownSize)).beTruthy();
    CGSize scaleUpSize = CGSizeMake(2000, 1000);
    UIImage *scaledUpImage = [testImage sd_resizedImageWithSize:scaleUpSize scaleMode:SDImageScaleModeAspectFit];
    expect(CGSizeEqualToSize(scaledUpImage.size, scaleUpSize)).beTruthy();
    // Check image not inversion
    UIColor *topCenterColor = [scaledUpImage sd_colorAtPoint:CGPointMake(1000, 50)];
    expect([topCenterColor.sd_hexString isEqualToString:[UIColor blackColor].sd_hexString]).beTruthy();
}

- (void)test02UIImageTransformCropCG {
    [self test02UIImageTransformCropWithImage:self.testImageCG];
}

- (void)test02UIImageTransformCropCI {
    [self test02UIImageTransformCropWithImage:self.testImageCI];
}

- (void)test02UIImageTransformCropWithImage:(UIImage *)testImage {
    CGRect rect = CGRectMake(50, 10, 200, 200);
    UIImage *croppedImage = [testImage sd_croppedImageWithRect:rect];
    expect(CGSizeEqualToSize(croppedImage.size, CGSizeMake(200, 200))).beTruthy();
    UIColor *startColor = [croppedImage sd_colorAtPoint:CGPointZero];
    expect([startColor.sd_hexString isEqualToString:[UIColor clearColor].sd_hexString]).beTruthy();
    // Check image not inversion
    UIColor *topCenterColor = [croppedImage sd_colorAtPoint:CGPointMake(100, 10)];
    expect([topCenterColor.sd_hexString isEqualToString:[UIColor blackColor].sd_hexString]).beTruthy();
}

- (void)test03UIImageTransformRoundedCornerCG {
    [self test03UIImageTransformRoundedCornerWithImage:self.testImageCG];
}

- (void)test03UIImageTransformRoundedCornerCI {
    [self test03UIImageTransformRoundedCornerWithImage:self.testImageCI];
}

- (void)test03UIImageTransformRoundedCornerWithImage:(UIImage *)testImage {
    CGFloat radius = 50;
#if SD_UIKIT
    SDRectCorner corners = UIRectCornerAllCorners;
#else
    SDRectCorner corners = SDRectCornerAllCorners;
#endif
    CGFloat borderWidth = 1;
    UIColor *borderColor = [UIColor blackColor];
    UIImage *roundedCornerImage = [testImage sd_roundedCornerImageWithRadius:radius corners:corners borderWidth:borderWidth borderColor:borderColor];
    expect(CGSizeEqualToSize(roundedCornerImage.size, CGSizeMake(300, 300))).beTruthy();
    UIColor *startColor = [roundedCornerImage sd_colorAtPoint:CGPointZero];
    expect([startColor.sd_hexString isEqualToString:[UIColor clearColor].sd_hexString]).beTruthy();
    // Check the left center pixel, should be border :)
    UIColor *checkBorderColor = [roundedCornerImage sd_colorAtPoint:CGPointMake(1, 150)];
    expect([checkBorderColor.sd_hexString isEqualToString:borderColor.sd_hexString]).beTruthy();
    // Check rounded corner operation not inversion the image
    UIColor *topCenterColor = [roundedCornerImage sd_colorAtPoint:CGPointMake(150, 20)];
    expect([topCenterColor.sd_hexString isEqualToString:[UIColor blackColor].sd_hexString]).beTruthy();
}

- (void)test04UIImageTransformRotateCG {
    [self test04UIImageTransformRotateWithImage:self.testImageCG];
}

- (void)test04UIImageTransformRotateCI {
    [self test04UIImageTransformRotateWithImage:self.testImageCI];
}

- (void)test04UIImageTransformRotateWithImage:(UIImage *)testImage {
    CGFloat angle = M_PI_4;
    UIImage *rotatedImage = [testImage sd_rotatedImageWithAngle:angle fitSize:NO];
    // Not fit size and no change
    expect(CGSizeEqualToSize(rotatedImage.size, testImage.size)).beTruthy();
    // Fit size, may change size
    rotatedImage = [testImage sd_rotatedImageWithAngle:angle fitSize:YES];
    CGSize rotatedSize = CGSizeMake(ceil(300 * 1.414), ceil(300 * 1.414)); // 45º, square length * sqrt(2)
    expect(rotatedImage.size.width - rotatedSize.width <= 1).beTruthy();
    expect(rotatedImage.size.height - rotatedSize.height <= 1).beTruthy();
    // Check image not inversion
    UIColor *leftCenterColor = [rotatedImage sd_colorAtPoint:CGPointMake(60, 175)];
    expect([leftCenterColor.sd_hexString isEqualToString:[UIColor blackColor].sd_hexString]).beTruthy();
}

- (void)test05UIImageTransformFlipCG {
    [self test05UIImageTransformFlipWithImage:self.testImageCG];
}

- (void)test05UIImageTransformFlipCI {
    [self test05UIImageTransformFlipWithImage:self.testImageCI];
}

- (void)test05UIImageTransformFlipWithImage:(UIImage *)testImage {
    BOOL horizontal = YES;
    BOOL vertical = YES;
    UIImage *flippedImage = [testImage sd_flippedImageWithHorizontal:horizontal vertical:vertical];
    expect(CGSizeEqualToSize(flippedImage.size, testImage.size)).beTruthy();
    // Test pixel colors method here
    UIColor *checkColor = [flippedImage sd_colorAtPoint:CGPointMake(75, 75)];
    expect(checkColor);
    NSArray<UIColor *> *checkColors = [flippedImage sd_colorsWithRect:CGRectMake(75, 75, 10, 10)]; // Rect are all same color
    expect(checkColors.count).to.equal(10 * 10);
    for (UIColor *color in checkColors) {
        expect([color isEqual:checkColor]).to.beTruthy();
    }
    // Check image not inversion
    UIColor *bottomCenterColor = [flippedImage sd_colorAtPoint:CGPointMake(150, 285)];
    expect([bottomCenterColor.sd_hexString isEqualToString:[UIColor blackColor].sd_hexString]).beTruthy();
}

- (void)test06UIImageTransformTintCG {
    [self test06UIImageTransformTintWithImage:self.testImageCG];
}

- (void)test06UIImageTransformTintCI {
    [self test06UIImageTransformTintWithImage:self.testImageCI];
}

- (void)test06UIImageTransformTintWithImage:(UIImage *)testImage {
    UIColor *tintColor = [UIColor blackColor];
    UIImage *tintedImage = [testImage sd_tintedImageWithColor:tintColor];
    expect(CGSizeEqualToSize(tintedImage.size, testImage.size)).beTruthy();
    // Check center color, should keep clear
    UIColor *centerColor = [tintedImage sd_colorAtPoint:CGPointMake(150, 150)];
    expect([centerColor.sd_hexString isEqualToString:[UIColor clearColor].sd_hexString]).beTruthy();
    // Check left color, should be tinted
    UIColor *leftColor = [tintedImage sd_colorAtPoint:CGPointMake(80, 150)];
    expect([leftColor.sd_hexString isEqualToString:tintColor.sd_hexString]).beTruthy();
    // Check rounded corner operation not inversion the image
    UIColor *topCenterColor = [tintedImage sd_colorAtPoint:CGPointMake(150, 20)];
    expect([topCenterColor.sd_hexString isEqualToString:[UIColor blackColor].sd_hexString]).beTruthy();
    
    UIImage *tintedSourceInImage = [testImage sd_tintedImageWithColor:tintColor blendMode:kCGBlendModeSourceIn];
    topCenterColor = [tintedSourceInImage sd_colorAtPoint:CGPointMake(150, 20)];
#if SD_UIKIT
    // Test UIKit's tint color behavior
    if (@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)) {
        UIImage *tintedSystemImage = [testImage imageWithTintColor:tintColor renderingMode:UIImageRenderingModeAlwaysTemplate];
        UIGraphicsImageRendererFormat *format = UIGraphicsImageRendererFormat.preferredFormat;
        format.scale = tintedSourceInImage.scale;
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:tintedSystemImage.size format:format];
        // Draw template image
        tintedSystemImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
                [tintedSystemImage drawInRect:CGRectMake(0, 0, tintedSystemImage.size.width, tintedSystemImage.size.height)];
        }];
        UIColor *testColor1 = [tintedSourceInImage sd_colorAtPoint:CGPointMake(150, 20)];
        UIColor *testColor2 = [tintedSystemImage sd_colorAtPoint:CGPointMake(150, 20)];
        CGFloat r1, g1, b1, a1;
        CGFloat r2, g2, b2, a2;
        [testColor1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
        [testColor2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
        expect(r1).beCloseToWithin(r2, 0.01);
        expect(g1).beCloseToWithin(g2, 0.01);
        expect(b1).beCloseToWithin(b2, 0.01);
        expect(a1).beCloseToWithin(a2, 0.01);
    }
#endif
    expect([topCenterColor.sd_hexString isEqualToString:tintColor.sd_hexString]).beTruthy();
}
#pragma clang diagnostic pop

- (void)test07UIImageTransformBlurCG {
    [self test07UIImageTransformBlurWithImage:self.testImageCG];
}

- (void)test07UIImageTransformBlurCI {
    [self test07UIImageTransformBlurWithImage:self.testImageCI];
}

- (void)test07UIImageTransformBlurWithImage:(UIImage *)testImage {
    CGFloat radius = 25;
    UIImage *blurredImage = [testImage sd_blurredImageWithRadius:radius];
    expect(CGSizeEqualToSize(blurredImage.size, testImage.size)).beTruthy();
    // Check left color, should be blurred
    UIColor *leftColor = [blurredImage sd_colorAtPoint:CGPointMake(80, 150)];
    // Hard-code from the output, allows a little deviation because of blur diffs between OS versions :)
    UIColor *expectedColor = [UIColor colorWithRed:0.59 green:0.14 blue:0.12 alpha:0.75];
    CGFloat r1, g1, b1, a1;
    CGFloat r2, g2, b2, a2;
    [leftColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [expectedColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    expect(r1).beCloseToWithin(r2, 0.01);
    expect(g1).beCloseToWithin(g2, 0.01);
    expect(b1).beCloseToWithin(b2, 0.01);
    expect(a1).beCloseToWithin(a2, 0.01);
    // Check rounded corner operation not inversion the image
    UIColor *topCenterColor = [blurredImage sd_colorAtPoint:CGPointMake(150, 20)];
    UIColor *bottomCenterColor = [blurredImage sd_colorAtPoint:CGPointMake(150, 280)];
    expect([topCenterColor.sd_hexString isEqualToString:bottomCenterColor.sd_hexString]).beFalsy();
}

- (void)test08UIImageTransformFilterCG {
    [self test08UIImageTransformFilterWithImage:self.testImageCG];
}

- (void)test08UIImageTransformFilterCI {
    [self test08UIImageTransformFilterWithImage:self.testImageCI];
}

- (void)test08UIImageTransformFilterWithImage:(UIImage *)testImage {
    // Invert color filter
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    UIImage *filteredImage = [testImage sd_filteredImageWithFilter:filter];
    expect(CGSizeEqualToSize(filteredImage.size, testImage.size)).beTruthy();
    // Check left color, should be inverted
    UIColor *leftColor = [filteredImage sd_colorAtPoint:CGPointMake(80, 150)];
    // Hard-code from the output
    UIColor *expectedColor = [UIColor colorWithRed:0.85098 green:0.992157 blue:0.992157 alpha:1];
    CGFloat r1, g1, b1, a1;
    CGFloat r2, g2, b2, a2;
    [leftColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [expectedColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    expect(r1).beCloseToWithin(r2, 0.01);
    expect(g1).beCloseToWithin(g2, 0.01);
    expect(b1).beCloseToWithin(b2, 0.01);
    expect(a1).beCloseToWithin(a2, 0.01);
    // Check rounded corner operation not inversion the image
    UIColor *topCenterColor = [filteredImage sd_colorAtPoint:CGPointMake(150, 20)];
    expect([topCenterColor.sd_hexString isEqualToString:[UIColor whiteColor].sd_hexString]).beTruthy();
}

#pragma mark - SDImageTransformer

- (void)test09ImagePipelineTransformer {
    CGSize size = CGSizeMake(100, 100);
    SDImageScaleMode scaleMode = SDImageScaleModeAspectFill;
    CGFloat angle = M_PI_4;
    BOOL fitSize = NO;
    CGFloat radius = 50;
#if SD_UIKIT
    SDRectCorner corners = UIRectCornerAllCorners;
#else
    SDRectCorner corners = SDRectCornerAllCorners;
#endif
    CGFloat borderWidth = 1;
    UIColor *borderCoder = [UIColor blackColor];
    BOOL horizontal = YES;
    BOOL vertical = YES;
    CGRect cropRect = CGRectMake(0, 0, 50, 50);
    UIColor *tintColor = [UIColor clearColor];
    CGFloat blurRadius = 5;
    
    SDImageResizingTransformer *transformer1 = [SDImageResizingTransformer transformerWithSize:size scaleMode:scaleMode];
    SDImageRotationTransformer *transformer2 = [SDImageRotationTransformer transformerWithAngle:angle fitSize:fitSize];
    SDImageRoundCornerTransformer *transformer3 = [SDImageRoundCornerTransformer transformerWithRadius:radius corners:corners borderWidth:borderWidth borderColor:borderCoder];
    SDImageFlippingTransformer *transformer4 = [SDImageFlippingTransformer transformerWithHorizontal:horizontal vertical:vertical];
    SDImageCroppingTransformer *transformer5 = [SDImageCroppingTransformer transformerWithRect:cropRect];
    SDImageTintTransformer *transformer6 = [SDImageTintTransformer transformerWithColor:tintColor];
    SDImageBlurTransformer *transformer7 = [SDImageBlurTransformer transformerWithRadius:blurRadius];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    SDImageFilterTransformer *transformer8 = [SDImageFilterTransformer transformerWithFilter:filter];
    
    // Chain all built-in transformers for test case
    SDImagePipelineTransformer *pipelineTransformer = [SDImagePipelineTransformer transformerWithTransformers:@[
                                                                                                                transformer1,
                                                                                                                transformer2,
                                                                                                                transformer3,
                                                                                                                transformer4,
                                                                                                                transformer5,
                                                                                                                transformer6,
                                                                                                                transformer7,
                                                                                                                transformer8
                                                                                                                ]];
    NSArray *transformerKeys = @[
                      @"SDImageResizingTransformer({100.000000,100.000000},2)",
                      @"SDImageRotationTransformer(0.785398,0)",
                      @"SDImageRoundCornerTransformer(50.000000,18446744073709551615,1.000000,#ff000000)",
                      @"SDImageFlippingTransformer(1,1)",
                      @"SDImageCroppingTransformer({0.000000,0.000000,50.000000,50.000000})",
                      @"SDImageTintTransformer(#00000000,18)",
                      @"SDImageBlurTransformer(5.000000)",
                      @"SDImageFilterTransformer(CIColorInvert)"
                      ];
    NSString *transformerKey = [transformerKeys componentsJoinedByString:@"-"]; // SDImageTransformerKeySeparator
    expect([pipelineTransformer.transformerKey isEqualToString:transformerKey]).beTruthy();
    
    UIImage *transformedImage = [pipelineTransformer transformedImageWithImage:self.testImageCG forKey:@"Test"];
    expect(transformedImage).notTo.beNil();
    expect(CGSizeEqualToSize(transformedImage.size, cropRect.size)).beTruthy();
}

- (void)test10TransformerKeyForCacheKey {
    NSString *transformerKey = @"SDImageFlippingTransformer(1,0)";
    
    // File path representation test cases
    NSString *key = @"image.png";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"image-SDImageFlippingTransformer(1,0).png");
    
    key = @"image";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"image-SDImageFlippingTransformer(1,0)");
    
    key = @".image";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@".image-SDImageFlippingTransformer(1,0)");
    
    key = @"image.";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"image.-SDImageFlippingTransformer(1,0)");
    
    key = @"Test/image.png";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"Test/image-SDImageFlippingTransformer(1,0).png");
    
    // URL representation test cases
    key = @"http://foo/image.png";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"http://foo/image-SDImageFlippingTransformer(1,0).png");
    
    key = @"http://foo/image";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"http://foo/image-SDImageFlippingTransformer(1,0)");
    
    key = @"http://foo/.image";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"http://foo/.image-SDImageFlippingTransformer(1,0)");
    
    key = @"http://foo/image.png?foo=bar#mark";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"http://foo/image-SDImageFlippingTransformer(1,0).png?foo=bar#mark");
    
    key = @"ftp://root:password@foo.com/image.png";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"ftp://root:password@foo.com/image-SDImageFlippingTransformer(1,0).png");
}

#pragma mark - Coder Helper

- (void)test20CGImageCreateDecodedWithOrientation {
    // Test EXIF orientation tag, you can open this image with `Preview.app`, open inspector (Command+I) and rotate (Command+L/R) to check
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[self testPNGPathForName:@"TestEXIF"]];
    CGImageRef originalCGImage = image.CGImage;
    expect(image).notTo.beNil();
    
    // Check the longest side of "F" point color
    UIColor *pointColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
    
    CGImageRef upCGImage = [SDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationUp];
#if SD_UIKIT
    UIImage *upImage = [[UIImage alloc] initWithCGImage:upCGImage];
#else
    UIImage *upImage = [[UIImage alloc] initWithCGImage:upCGImage size:NSZeroSize];
#endif
    expect([[upImage sd_colorAtPoint:CGPointMake(40, 160)].sd_hexString isEqualToString:pointColor.sd_hexString]).beTruthy();
    expect(upImage.size).equal(CGSizeMake(150, 200));
    CGImageRelease(upCGImage);
    
    CGImageRef upMirroredCGImage = [SDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationUpMirrored];
#if SD_UIKIT
    UIImage *upMirroredImage = [[UIImage alloc] initWithCGImage:upMirroredCGImage];
#else
    UIImage *upMirroredImage = [[UIImage alloc] initWithCGImage:upMirroredCGImage size:NSZeroSize];
#endif
    expect([[upMirroredImage sd_colorAtPoint:CGPointMake(110, 160)].sd_hexString isEqualToString:pointColor.sd_hexString]).beTruthy();
    expect(upMirroredImage.size).equal(CGSizeMake(150, 200));
    CGImageRelease(upMirroredCGImage);
    
    CGImageRef downCGImage = [SDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationDown];
#if SD_UIKIT
    UIImage *downImage = [[UIImage alloc] initWithCGImage:downCGImage];
#else
    UIImage *downImage = [[UIImage alloc] initWithCGImage:downCGImage size:NSZeroSize];
#endif
    expect([[downImage sd_colorAtPoint:CGPointMake(110, 30)].sd_hexString isEqualToString:pointColor.sd_hexString]).beTruthy();
    expect(downImage.size).equal(CGSizeMake(150, 200));
    CGImageRelease(downCGImage);
    
    CGImageRef downMirrorerdCGImage = [SDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationDownMirrored];
#if SD_UIKIT
    UIImage *downMirroredImage = [[UIImage alloc] initWithCGImage:downMirrorerdCGImage];
#else
    UIImage *downMirroredImage = [[UIImage alloc] initWithCGImage:downMirrorerdCGImage size:NSZeroSize];
#endif
    expect([[downMirroredImage sd_colorAtPoint:CGPointMake(40, 30)].sd_hexString isEqualToString:pointColor.sd_hexString]).beTruthy();
    expect(downMirroredImage.size).equal(CGSizeMake(150, 200));
    CGImageRelease(downMirrorerdCGImage);
    
    CGImageRef leftMirroredCGImage = [SDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationLeftMirrored];
#if SD_UIKIT
    UIImage *leftMirroredImage = [[UIImage alloc] initWithCGImage:leftMirroredCGImage];
#else
    UIImage *leftMirroredImage = [[UIImage alloc] initWithCGImage:leftMirroredCGImage size:NSZeroSize];
#endif
    expect([[leftMirroredImage sd_colorAtPoint:CGPointMake(160, 40)].sd_hexString isEqualToString:pointColor.sd_hexString]).beTruthy();
    expect(leftMirroredImage.size).equal(CGSizeMake(200, 150));
    CGImageRelease(leftMirroredCGImage);
    
    CGImageRef rightCGImage = [SDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationRight];
#if SD_UIKIT
    UIImage *rightImage = [[UIImage alloc] initWithCGImage:rightCGImage];
#else
    UIImage *rightImage = [[UIImage alloc] initWithCGImage:rightCGImage size:NSZeroSize];
#endif
    expect([[rightImage sd_colorAtPoint:CGPointMake(30, 40)].sd_hexString isEqualToString:pointColor.sd_hexString]).beTruthy();
    expect(rightImage.size).equal(CGSizeMake(200, 150));
    CGImageRelease(rightCGImage);
    
    CGImageRef rightMirroredCGImage = [SDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationRightMirrored];
#if SD_UIKIT
    UIImage *rightMirroredImage = [[UIImage alloc] initWithCGImage:rightMirroredCGImage];
#else
    UIImage *rightMirroredImage = [[UIImage alloc] initWithCGImage:rightMirroredCGImage size:NSZeroSize];
#endif
    expect([[rightMirroredImage sd_colorAtPoint:CGPointMake(30, 110)].sd_hexString isEqualToString:pointColor.sd_hexString]).beTruthy();
    expect(rightMirroredImage.size).equal(CGSizeMake(200, 150));
    CGImageRelease(rightMirroredCGImage);
    
    CGImageRef leftCGImage = [SDImageCoderHelper CGImageCreateDecoded:originalCGImage orientation:kCGImagePropertyOrientationLeft];
#if SD_UIKIT
    UIImage *leftImage = [[UIImage alloc] initWithCGImage:leftCGImage];
#else
    UIImage *leftImage = [[UIImage alloc] initWithCGImage:leftCGImage size:NSZeroSize];
#endif
    expect([[leftImage sd_colorAtPoint:CGPointMake(160, 110)].sd_hexString isEqualToString:pointColor.sd_hexString]).beTruthy();
    expect(leftImage.size).equal(CGSizeMake(200, 150));
    CGImageRelease(leftCGImage);
}

- (void)test21BMPImageCreateDecodedShouldNotBlank {
    UIImage *testImage = [[UIImage alloc] initWithContentsOfFile:[self testBMPPathForName:@"TestImage"]];
    CGImageRef cgImage = testImage.CGImage;
    expect(cgImage).notTo.beNil();
    UIImage *decodedImage = [SDImageCoderHelper decodedImageWithImage:testImage];
    expect(decodedImage).notTo.beNil();
    UIColor *testColor = [decodedImage sd_colorAtPoint:CGPointMake(100, 100)];
    // Should not be black color
    expect([[testColor sd_hexString] isEqualToString:UIColor.blackColor.sd_hexString]).beFalsy();
}

- (void)test22CGImageCreateScaledWithSize {
    size_t width = 100;
    size_t height = 100;
    size_t scaledWidth = 50;
    size_t scaledHeight = 50;
    // RGB888
    CGImageRef RGB888Image = ^(){
        size_t bitsPerComponent = 8;
        size_t components = 3;
        size_t bitsPerPixel = bitsPerComponent * components;
        size_t bytesPerRow = bitsPerPixel / 8 * width;
        size_t size = bytesPerRow * height;
        size_t count = width * height * components;
        uint8_t bitmap[count];
        for (size_t i = 0; i < count; i++) {
            bitmap[i] = UINT8_MAX;
        }
        CGColorSpaceRef colorspace = [SDImageCoderHelper colorSpaceGetDeviceRGB];
        CGBitmapInfo bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
        CFDataRef data = CFDataCreate(NULL, (UInt8 *)bitmap, size);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CFRelease(data);
        BOOL shouldInterpolate = YES;
        CGColorRenderingIntent intent = kCGRenderingIntentDefault;
        CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorspace, bitmapInfo, provider, NULL, shouldInterpolate, intent);
        CGDataProviderRelease(provider);
        return cgImage;
    }();
    CGImageRef RGB888Scaled = [SDImageCoderHelper CGImageCreateScaled:RGB888Image size:CGSizeMake(scaledWidth, scaledHeight)];
    XCTAssertEqual(CGImageGetWidth(RGB888Scaled), scaledWidth);
    XCTAssertEqual(CGImageGetHeight(RGB888Scaled), scaledHeight);
    SDAssertCGImagePixelFormatEqual(RGB888Scaled, RGB888Image);
    SDAssertCGImageFirstComponentWhite(RGB888Scaled, kCVPixelFormatType_24RGB);

    // RGB16161616
    CGImageRef RGB161616Image = ^(){
        size_t bitsPerComponent = 16;
        size_t components = 3;
        size_t bitsPerPixel = bitsPerComponent * components;
        size_t bytesPerRow = bitsPerPixel / 8 * width;
        size_t size = bytesPerRow * height;
        size_t count = width * height * components;
        uint16_t bitmap[count];
        for (size_t i = 0; i < count; i++) {
            bitmap[i] = UINT16_MAX;
        }
        CGColorSpaceRef colorspace = [SDImageCoderHelper colorSpaceGetDeviceRGB];
        CGBitmapInfo bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrder16Host;
        CFDataRef data = CFDataCreate(NULL, (UInt8 *)bitmap, size);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CFRelease(data);
        BOOL shouldInterpolate = YES;
        CGColorRenderingIntent intent = kCGRenderingIntentDefault;
        CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorspace, bitmapInfo, provider, NULL, shouldInterpolate, intent);
        CGDataProviderRelease(provider);
        return cgImage;
    }();
    CGImageRef RGB161616Scaled = [SDImageCoderHelper CGImageCreateScaled:RGB161616Image size:CGSizeMake(scaledWidth, scaledHeight)];
    XCTAssertEqual(CGImageGetWidth(RGB161616Scaled), scaledWidth);
    XCTAssertEqual(CGImageGetHeight(RGB161616Scaled), scaledHeight);
    SDAssertCGImagePixelFormatEqual(RGB161616Scaled, RGB161616Image);
    SDAssertCGImageFirstComponentWhite(RGB161616Scaled, kCVPixelFormatType_48RGB);
    
    // ARGB8888
    CGImageRef ARGB8888Image = ^(){
        size_t bitsPerComponent = 8;
        size_t components = 4;
        size_t bitsPerPixel = bitsPerComponent * components;
        size_t bytesPerRow = bitsPerPixel / 8 * width;
        size_t size = bytesPerRow * height;
        size_t count = width * height * components;
        uint8_t bitmap[count];
        for (size_t i = 0; i < count; i++) {
            bitmap[i] = UINT8_MAX;
        }
        CGColorSpaceRef colorspace = [SDImageCoderHelper colorSpaceGetDeviceRGB];
        CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault;
        CFDataRef data = CFDataCreate(NULL, (UInt8 *)bitmap, size);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CFRelease(data);
        BOOL shouldInterpolate = YES;
        CGColorRenderingIntent intent = kCGRenderingIntentDefault;
        CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorspace, bitmapInfo, provider, NULL, shouldInterpolate, intent);
        CGDataProviderRelease(provider);
        return cgImage;
    }();
    CGImageRef ARGB8888Scaled = [SDImageCoderHelper CGImageCreateScaled:ARGB8888Image size:CGSizeMake(scaledWidth, scaledHeight)];
    XCTAssertEqual(CGImageGetWidth(ARGB8888Scaled), scaledWidth);
    XCTAssertEqual(CGImageGetHeight(ARGB8888Scaled), scaledHeight);
    SDAssertCGImagePixelFormatEqual(ARGB8888Scaled, ARGB8888Image);
    SDAssertCGImageFirstComponentWhite(ARGB8888Scaled, kCVPixelFormatType_32ARGB);
    
    // RGBA16161616
    CGImageRef RGBA16161616Image = ^(){
        size_t bitsPerComponent = 16;
        size_t components = 4;
        size_t bitsPerPixel = bitsPerComponent * components;
        size_t bytesPerRow = bitsPerPixel / 8 * width;
        size_t size = bytesPerRow * height;
        size_t count = width * height * components;
        uint16_t bitmap[count];
        for (size_t i = 0; i < count; i++) {
            bitmap[i] = UINT16_MAX;
        }
        CGColorSpaceRef colorspace = [SDImageCoderHelper colorSpaceGetDeviceRGB];
        CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder16Host;
        CFDataRef data = CFDataCreate(NULL, (UInt8 *)bitmap, size);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CFRelease(data);
        BOOL shouldInterpolate = YES;
        CGColorRenderingIntent intent = kCGRenderingIntentDefault;
        CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorspace, bitmapInfo, provider, NULL, shouldInterpolate, intent);
        CGDataProviderRelease(provider);
        return cgImage;
    }();
    CGImageRef RGBA16161616Scaled = [SDImageCoderHelper CGImageCreateScaled:RGBA16161616Image size:CGSizeMake(scaledWidth, scaledHeight)];
    XCTAssertEqual(CGImageGetWidth(RGBA16161616Scaled), scaledWidth);
    XCTAssertEqual(CGImageGetHeight(RGBA16161616Scaled), scaledHeight);
    SDAssertCGImagePixelFormatEqual(RGBA16161616Scaled, RGBA16161616Image);
    SDAssertCGImageFirstComponentWhite(RGBA16161616Scaled, kCVPixelFormatType_64RGBALE);
    
    // RGBAFFFF
    CGImageRef RGBAFFFFImage = ^(){
        size_t bitsPerComponent = 32;
        size_t components = 4;
        size_t bitsPerPixel = bitsPerComponent * components;
        size_t bytesPerRow = bitsPerPixel / 8 * width;
        size_t size = bytesPerRow * height;
        size_t count = width * height * components;
        float bitmap[count];
        for (size_t i = 0; i < count; i++) {
            bitmap[i] = 1.0;
        }
        CGColorSpaceRef colorspace = [SDImageCoderHelper colorSpaceGetDeviceRGB];
        CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Host | kCGBitmapFloatComponents;
        CFDataRef data = CFDataCreate(NULL, (UInt8 *)bitmap, size);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CFRelease(data);
        BOOL shouldInterpolate = YES;
        CGColorRenderingIntent intent = kCGRenderingIntentDefault;
        CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorspace, bitmapInfo, provider, NULL, shouldInterpolate, intent);
        CGDataProviderRelease(provider);
        return cgImage;
    }();
    CGImageRef RGBAFFFFScaled = [SDImageCoderHelper CGImageCreateScaled:RGBAFFFFImage size:CGSizeMake(scaledWidth, scaledHeight)];
    XCTAssertEqual(CGImageGetWidth(RGBAFFFFScaled), scaledWidth);
    XCTAssertEqual(CGImageGetHeight(RGBAFFFFScaled), scaledHeight);
    SDAssertCGImagePixelFormatEqual(RGBAFFFFScaled, RGBAFFFFImage);
    SDAssertCGImageFirstComponentWhite(RGBAFFFFScaled, kCVPixelFormatType_128RGBAFloat);
    
    // Cleanup and check by human eyes using preview, all should be white image
    CGImageRelease(RGB888Image);
    CGImageRelease(RGB888Scaled);
    CGImageRelease(RGB161616Image);
    CGImageRelease(RGB161616Scaled);
    CGImageRelease(ARGB8888Image);
    CGImageRelease(ARGB8888Scaled);
    CGImageRelease(RGBA16161616Image);
    CGImageRelease(RGBA16161616Scaled);
    CGImageRelease(RGBAFFFFImage);
    CGImageRelease(RGBAFFFFScaled);
}

#pragma mark - Helper

- (UIImage *)testImageCG {
    if (!_testImageCG) {
        _testImageCG = [[UIImage alloc] initWithContentsOfFile:[self testPNGPathForName:@"TestImage"]];
    }
    return _testImageCG;
}

- (UIImage *)testImageCI {
    if (!_testImageCI) {
        CIImage *ciImage = [[CIImage alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[self testPNGPathForName:@"TestImage"]]];
#if SD_UIKIT
        _testImageCI = [[UIImage alloc] initWithCIImage:ciImage scale:1 orientation:UIImageOrientationUp];
#else
        _testImageCI = [[UIImage alloc] initWithCIImage:ciImage scale:1 orientation:kCGImagePropertyOrientationUp];
#endif
    }
    return _testImageCI;
}

- (NSString *)testPNGPathForName:(NSString *)name {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:name ofType:@"png"];
}

- (NSString *)testBMPPathForName:(NSString *)name {
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  return [testBundle pathForResource:name ofType:@"bmp"];
}

@end
