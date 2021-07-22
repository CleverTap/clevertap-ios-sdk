
#import "CTNotificationServiceExtension.h"

static NSString * const kMediaUrlKey = @"ct_mediaUrl";
static NSString * const kMediaTypeKey = @"ct_mediaType";

static NSString * const kImage = @"image";
static NSString * const kVideo = @"video";
static NSString * const kAudio = @"audio";

@interface CTNotificationServiceExtension()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation CTNotificationServiceExtension

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    NSDictionary *userInfo = request.content.userInfo;
    if (userInfo == nil) {
        [self contentComplete];
        return;
    }
    
    NSString *mediaUrlKey = self.mediaUrlKey ? self.mediaUrlKey : kMediaUrlKey;
    NSString *mediaTypeKey = self.mediaTypeKey ? self.mediaTypeKey : kMediaTypeKey;
    
    NSString *mediaUrl = userInfo[mediaUrlKey];
    NSString *mediaType = userInfo[mediaTypeKey];
    
    if (mediaUrl == nil || mediaType == nil) {
#ifdef DEBUG
        if (mediaUrl == nil) {
             NSLog(@"unable to add attachment: %@ is nil", mediaUrlKey);
        }
        
        if (mediaType == nil) {
            NSLog(@"unable to add attachment: %@ is nil", mediaTypeKey);
        }
       
#endif
        [self contentComplete];
        return;
    }
    
    // load the attachment
    [self loadAttachmentForUrlString:mediaUrl
                            withType:mediaType
                   completionHandler:^(UNNotificationAttachment *attachment) {
                       if (attachment) {
                           self.bestAttemptContent.attachments = [NSArray arrayWithObject:attachment];
                       }
                       [self contentComplete];
                   }];
    
}

- (void)serviceExtensionTimeWillExpire {
    [self contentComplete];
}

- (void)contentComplete {
    self.contentHandler(self.bestAttemptContent);
}

- (NSString *)fileExtensionForMediaType:(NSString *)type {
    NSString *ext = type;
    
    if ([type isEqualToString:kImage]) {
        ext = @"jpg";
    }
    
    if ([type isEqualToString:kVideo]) {
        ext = @"mp4";
    }
    
    if ([type isEqualToString:kAudio]) {
        ext = @"mp3";
    }
    
    return [@"." stringByAppendingString:ext];
}

- (void)loadAttachmentForUrlString:(NSString *)urlString withType:(NSString *)type
                 completionHandler:(void(^)(UNNotificationAttachment *))completionHandler  {
    
    __block UNNotificationAttachment *attachment = nil;
    NSURL *attachmentURL = [NSURL URLWithString:urlString];
    NSString *fileExt = [self fileExtensionForMediaType:type];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session downloadTaskWithURL:attachmentURL
                completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {
                    if (error != nil) {
                        #ifdef DEBUG
                        NSLog(@"unable to add attachment: %@", error.localizedDescription);
                        #endif
                    } else {
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSURL *localURL = [NSURL fileURLWithPath:[temporaryFileLocation.path stringByAppendingString:fileExt]];
                        [fileManager moveItemAtURL:temporaryFileLocation toURL:localURL error:&error];
                        
                        NSError *attachmentError = nil;
                        attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:localURL options:nil error:&attachmentError];
                        if (attachmentError) {
                            #ifdef DEBUG
                            NSLog(@"unable to add attchment: %@", attachmentError.localizedDescription);
                            #endif
                        }
                    }
                    completionHandler(attachment);
                }] resume];
}

@end
