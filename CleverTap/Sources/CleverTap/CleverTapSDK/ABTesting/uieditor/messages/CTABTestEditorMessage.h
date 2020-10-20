#import <Foundation/Foundation.h>
#import "CTEditorSession.h"
#import "CTABTestUtils.h"
#import "CTConstants.h"

@interface CTABTestEditorMessage : NSObject

@property (nonatomic, readonly, copy) NSString *type;
@property (nonatomic, readonly, strong) CTEditorSession *session;

+ (instancetype)messageWithOptions:(NSDictionary *)options;

- (instancetype)initWithType:(NSString *)type;

- (void)setDataObject:(id)object forKey:(NSString *)key;
- (id)dataObjectForKey:(NSString *)key;
- (NSDictionary *)data;

- (NSData *)JSONData;
- (CTABTestEditorMessage *)response;

@end


