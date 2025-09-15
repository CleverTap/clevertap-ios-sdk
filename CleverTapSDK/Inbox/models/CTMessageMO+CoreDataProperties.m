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
            // Use the encrypted payload as the json property
            self.json = json[@"_ct_encrypted_payload"];
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
    
    // If json is encrypted (stored as string), decrypt it first
    if ([jsonData isKindOfClass:[NSString class]]) {
        NSString *encryptedString = (NSString *)jsonData;
        // Check if it's actually encrypted using AES-GCM markers
        if ([encryptedString hasPrefix:AES_GCM_PREFIX] && [encryptedString hasSuffix:AES_GCM_SUFFIX]) {
            // Get encryption manager from context (you'll need to make this accessible)
            CTEncryptionManager *encryptionManager =  self.user.encryptionManager; /* get from context or user */;
            if (encryptionManager) {
                id decryptedObj = [encryptionManager decryptObject:encryptedString];
                if (decryptedObj && [decryptedObj isKindOfClass:[NSDictionary class]]) {
                    jsonData = decryptedObj;
                }
            }
        }
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
