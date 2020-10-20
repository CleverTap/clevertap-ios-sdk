#import <Foundation/Foundation.h>

@interface CTObjectSelector : NSObject

@property (nonatomic, strong, readonly) NSString *path;

+ (CTObjectSelector *)objectSelectorWithPath:(NSString *)path;
- (instancetype)initWithPath:(NSString *)path;

- (NSArray *)selectFromRoot:(id)root;
- (NSArray *)fuzzySelectFromRoot:(id)root;

- (BOOL)isLeafSelected:(id)leaf fromRoot:(id)root;
- (BOOL)fuzzyIsLeafSelected:(id)leaf fromRoot:(id)root;

- (Class)selectedClass;
- (Class)getRootViewControllerClass;
- (BOOL)pathContainsObjectOfClass:(Class)klass;
- (NSString *)description;

@end
