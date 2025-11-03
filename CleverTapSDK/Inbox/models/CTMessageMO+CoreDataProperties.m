#import "CTMessageMO.h"
#import "CTConstants.h"
#import "CTUserMO.h"

@implementation CTMessageMO (CoreDataProperties)

+ (NSFetchRequest<CTMessageMO *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"CTMessage"];
}

- (instancetype)initWithJSON:(NSDictionary *)json forContext:(NSManagedObjectContext *)context {
    CleverTapLogStaticInternal(@"Initializing new CTMessageMO with data: %@", json);
    
    self = [self initWithEntity:[NSEntityDescription entityForName:@"CTMessage" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    
    if (self != nil) {
        // Check if this message was pre-encrypted
        if (json[@"_ct_is_encrypted"] && [json[@"_ct_is_encrypted"] boolValue]) {
            id encryptedPayload = json[@"_ct_encrypted_payload"];
            
            if (!encryptedPayload) {
                CleverTapLogStaticDebug(@"Message marked as encrypted but missing _ct_encrypted_payload");
                self.json = [json copy];
            }
            else if ([encryptedPayload isKindOfClass:[NSDictionary class]]) {
                // Store the encrypted wrapper dictionary directly
                // This maintains NSDictionary type for backward compatibility
                self.json = encryptedPayload;
            }
            else {
                // Fallback for older encrypted format (if any)
                CleverTapLogStaticDebug(@"Unexpected encrypted payload format");
                self.json = [json copy];
            }
        } else {
            // Use the original message
            self.json = [json copy];
        }
        
        self.tags = json[@"msg"][@"tags"];
        
        NSString *id = json[@"_id"];
        if (id) {
            self.id = id;
        }
        
        NSString *wzrkId = json[@"wzrk_id"];
        if (wzrkId) {
            self.wzrk_id = wzrkId;
        }
        
        NSUInteger date = [json[@"date"] longValue];
        self.date = date ? date : (long)[[NSDate date] timeIntervalSince1970];
        
        NSUInteger expires = [json[@"wzrk_ttl"] longValue];
        self.expires = expires ? expires : 0;
    }
    return self;
}

- (NSDictionary *)toJSON {
    id jsonData = self.json;
    
    // Check if json is an encrypted wrapper dictionary
    if ([jsonData isKindOfClass:[NSDictionary class]]) {
        NSDictionary *jsonDict = (NSDictionary *)jsonData;
        
        // Check for encrypted data marker
        if (jsonDict[@"_ct_encrypted_data"]) {
            // Get encryption manager
            CTEncryptionManager *encryptionManager = self.user.encryptionManager;
            NSString *encryptedString = jsonDict[@"_ct_encrypted_data"];
            
            // Decrypt if we have encryption manager
            if (encryptionManager && [encryptionManager isTextAESGCMEncrypted:encryptedString]) {
                id decryptedObj = [encryptionManager decryptObject:encryptedString];
                if (decryptedObj && [decryptedObj isKindOfClass:[NSDictionary class]]) {
                    jsonData = decryptedObj;
                } else {
                    CleverTapLogStaticDebug(@"Failed to decrypt message with ID: %@, returning minimal data", self.id);
                    return @{@"isRead": @(self.isRead), @"date": @(self.date)};
                }
            } else {
                // No encryption manager (old version scenario)
                // Return minimal data to avoid showing encrypted content
                CleverTapLogStaticDebug(@"Encrypted message detected but no encryption manager available for ID: %@", self.id);
                return @{@"isRead": @(self.isRead), @"date": @(self.date)};
            }
        }
        // else: normal unencrypted dictionary, use as-is
    }
    
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:jsonData];
    json[@"isRead"] = @(self.isRead);
    json[@"date"] = @(self.date);
    return json;
}

@dynamic date;
@dynamic expires;
@dynamic id;
@dynamic wzrk_id;
@dynamic user;
@dynamic json;
@dynamic isRead;
@dynamic tags;

@end
