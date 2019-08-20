#import <UIKit/UIKit.h>
#import "CTABVariant.h"
#import "CTSwizzler.h"
#import "CTConstants.h"
#import "CTInAppResources.h"
#import "CTObjectSelector.h"
#import "CTValueTransformers.h"
#import "CTEditorImageCache.h"

@interface CTABVariant ()

@property (nonatomic) NSString *_id;
@property (nonatomic, strong) NSMutableOrderedSet *actions;
@property (nonatomic, readwrite, strong) NSArray<NSDictionary*>* vars;

@end

@interface CTABVariantAction ()

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) CTObjectSelector *objPath;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) NSArray *args;
@property (nonatomic, strong) NSMutableArray<NSString*> *imageUrls;
@property (nonatomic, strong) NSArray *original;
@property (nonatomic, assign) BOOL cacheOriginal;

@property (nonatomic, assign) BOOL swizzle;
@property (nonatomic, assign) Class swizzleClass;
@property (nonatomic, assign) SEL swizzleSelector;

@property (nonatomic, copy) NSHashTable *appliedTo;

+ (CTABVariantAction *)actionWithObject:(NSDictionary *)actionObject;

- (instancetype)initWithName:(NSString *)name
                        path:(CTObjectSelector *)path
                    selector:(SEL)selector
                        args:(NSArray *)args
               cacheOriginal:(BOOL)cacheOriginal
                    original:(NSArray *)original
                     swizzle:(BOOL)swizzle
                swizzleClass:(Class)swizzleClass
             swizzleSelector:(SEL)swizzleSelector;

- (void)apply;
- (void)revert;
- (void)cleanup;

@end

#pragma mark -

@implementation CTABVariant

#pragma mark Constructing Variants

+ (CTABVariant *)variantWithData:(NSDictionary *)variantData {
    NSString *variantId = variantData[@"var_id"];
    if (!variantId) {
        CleverTapLogStaticDebug(@"%@: Failed to construct variant, not valid variant id: %@", self, variantId);
        return nil;
    }
    NSString *experimentId = variantData[@"exp_id"];
    if (!experimentId) {
        CleverTapLogStaticDebug(@"%@: Failed to construct variant, not valid experiment id: %@", self, experimentId);
        return nil;
    }
    NSNumber *variantVersion = variantData[@"version"];

    NSArray *actions = variantData[@"actions"];
    if (![actions isKindOfClass:[NSArray class]]) {
        actions = [NSArray new];
    }
    
    NSArray *vars = variantData[@"vars"];
    if (![vars isKindOfClass:[NSArray class]]) {
        vars = [NSArray new];
    }
    
    if ([actions count] <= 0 && [vars count] <= 0) {
        CleverTapLogStaticDebug(@"%@: Failed to construct variant: %@, must contain either actions or vars", self, variantId);
        return nil;
    }
    
    return [[CTABVariant alloc] initWithId:variantId
                            experimentId:experimentId
                            variantVersion:variantVersion.unsignedIntegerValue
                                   actions:actions
                                      vars:vars];
}

- (instancetype)init {
    return [self initWithId:0 experimentId:0 variantVersion:0 actions:nil vars:@[]];
}

- (instancetype)initWithId:(NSString *)variantId experimentId:(NSString *)experimentId  variantVersion:(NSUInteger)variantVersion actions:(NSArray *)actions vars:(NSArray *)vars {
    if (self = [super init]) {
        self.variantId = variantId;
        self.experimentId = experimentId;
        self._id = [NSString stringWithFormat:@"%@:%@", self.experimentId, self.variantId];
        self.variantVersion = variantVersion;
        self.actions = [NSMutableOrderedSet orderedSet];
        [self addActions:actions andApply:NO];
        self.vars = [NSArray arrayWithArray:vars];
        _finished = NO;
        _running = NO;
    }
    return self;
}

- (void)cleanup {
    for (CTABVariantAction *action in self.actions) {
        [action cleanup];
    }
}

#pragma mark Actions

- (void)addActions:(NSArray *)actions andApply:(BOOL)apply {
    for (NSDictionary *actionObject in actions) {
        [self addAction:actionObject andApply:apply];
    }
}

- (void)addAction:(NSDictionary *)actionObject andApply:(BOOL)apply {
    CTABVariantAction *action = [CTABVariantAction actionWithObject:actionObject];
    if (action) {
        // Remove any action already in use for this name
        [self.actions removeObject:action];
        [self.actions addObject:action];
        if (apply) {
            [action apply];
        }
    }
}

- (void)removeActionWithName:(NSString *)name {
    for (CTABVariantAction *action in self.actions) {
        if ([action.name isEqualToString:name]) {
            [action revert];
            [self.actions removeObject:action];
            break;
        }
    }
}

#pragma mark NSCoding

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:_variantId forKey:@"variantId"];
    [aCoder encodeObject:__id forKey:@"id"];
    [aCoder encodeObject:_experimentId forKey:@"experimentId"];
    [aCoder encodeObject:@(_variantVersion) forKey:@"version"];
    [aCoder encodeObject:_actions forKey:@"actions"];
    [aCoder encodeObject:self.vars forKey:@"vars"];
    [aCoder encodeObject:@(_finished) forKey:@"finished"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [super init]) {
        self.variantId = [aDecoder decodeObjectForKey:@"variantId"];
        self._id = [aDecoder decodeObjectForKey:@"id"];
        self.experimentId = [aDecoder decodeObjectForKey:@"experimentId"];
        self.variantVersion = [(NSNumber *)[aDecoder decodeObjectForKey:@"version"] unsignedLongValue];
        self.actions = [aDecoder decodeObjectForKey:@"actions"];
        self.vars = [aDecoder decodeObjectForKey:@"vars"];
        _finished = [(NSNumber *)[aDecoder decodeObjectForKey:@"finished"] boolValue];
    }
    return self;
}

#pragma mark Execution

- (void)applyActions {
    if (!self.running && !self.finished) {
        for (CTABVariantAction *action in self.actions) {
            [action apply];
        }
        _running = YES;
    }
}

- (void)revertActions {
    for (CTABVariantAction *action in self.actions) {
        [action revert];
    }

    _running = NO;
}

- (void)finish {
    [self revertActions];
    _finished = YES;
    [self cleanup];
}

- (void)restart {
    _finished = NO;
}

#pragma mark Equality

- (BOOL)isEqualToVariant:(CTABVariant *)variant {
    return ([self._id isEqualToString:variant._id]  && self.variantVersion == variant.variantVersion);
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[CTABVariant class]]) {
        return NO;
    }
    return [self isEqualToVariant:(CTABVariant *)object];
}

- (NSUInteger)hash {
    return [self._id hash];
}

@end

#pragma mark -

@implementation CTABVariantAction

static NSMapTable *gettersForSetters;

static NSMapTable *originalCache;

+ (void)initialize {
    gettersForSetters = [[NSMapTable alloc] initWithKeyOptions:(NSPointerFunctionsOpaqueMemory|NSPointerFunctionsOpaquePersonality) valueOptions:(NSPointerFunctionsOpaqueMemory|NSPointerFunctionsOpaquePersonality) capacity:2];
    [gettersForSetters setObject:MAPTABLE_ID(NSSelectorFromString(@"imageForState:")) forKey:MAPTABLE_ID(NSSelectorFromString(@"setImage:forState:"))];
    [gettersForSetters setObject:MAPTABLE_ID(NSSelectorFromString(@"image")) forKey:MAPTABLE_ID(NSSelectorFromString(@"setImage:"))];
    [gettersForSetters setObject:MAPTABLE_ID(NSSelectorFromString(@"backgroundImageForState:")) forKey:MAPTABLE_ID(NSSelectorFromString(@"setBackgroundImage:forState:"))];
    originalCache = [NSMapTable mapTableWithKeyOptions:(NSMapTableWeakMemory|NSMapTableObjectPointerPersonality)
                                          valueOptions:(NSMapTableStrongMemory|NSMapTableObjectPointerPersonality)];
}

+ (void)runSyncMainQueue:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (CTABVariantAction *)actionWithObject:(NSDictionary *)actionObject {
    // Required parameters
    CTObjectSelector *path = [CTObjectSelector objectSelectorWithPath:actionObject[@"path"]];
    if (!path) {
        CleverTapLogStaticDebug(@"%@: action path is not valid: %@", self, actionObject[@"path"]);
        return nil;
    }
    
    SEL selector = NSSelectorFromString(actionObject[@"selector"]);
    if (selector == (SEL)0) {
        CleverTapLogStaticDebug(@"%@: action selector is not valid: %@", self, actionObject[@"selector"]);
        return nil;
    }
    
    NSArray *args = actionObject[@"args"];
    if (![args isKindOfClass:[NSArray class]]) {
        CleverTapLogStaticDebug(@"%@: action arguments are not valid: %@", self, args);
        return nil;
    }
    
    // Optional parameters
    BOOL cacheOriginal = !actionObject[@"cacheOriginal"] || [actionObject[@"swizzle"] boolValue];
    NSArray *original = [actionObject[@"original"] isKindOfClass:[NSArray class]] ? actionObject[@"original"] : nil;
    NSString *name = actionObject[@"name"];
    BOOL swizzle = !actionObject[@"swizzle"] || [actionObject[@"swizzle"] boolValue];
    Class swizzleClass = NSClassFromString(actionObject[@"swizzleClass"]);
    SEL swizzleSelector = NSSelectorFromString(actionObject[@"swizzleSelector"]);
    
    return [[CTABVariantAction alloc] initWithName:name
                                            path:path
                                        selector:selector
                                            args:args
                                   cacheOriginal:cacheOriginal
                                        original:original
                                         swizzle:swizzle
                                    swizzleClass:swizzleClass
                                 swizzleSelector:swizzleSelector];
}

- (instancetype)init {
    [NSException raise:@"NotSupported" format:@"Please call initWithName: path: selector: args: original: swizzle: swizzleClass: swizzleSelector:"];
    return nil;
}

- (instancetype)initWithName:(NSString *)name path:(CTObjectSelector *)path
                    selector:(SEL)selector args:(NSArray *)args cacheOriginal:(BOOL)cacheOriginal
                    original:(NSArray *)original swizzle:(BOOL)swizzle
                swizzleClass:(Class)swizzleClass swizzleSelector:(SEL)swizzleSelector{
    if ((self = [super init])) {
        self.objPath = path;
        self.selector = selector;
        self.args = args;
        self.original = original;
        self.swizzle = swizzle;
        self.cacheOriginal = cacheOriginal;
        
        if (!name) {
            name = [NSUUID UUID].UUIDString;
        }
        self.name = name;
        
        swizzleClass = swizzleClass != nil ? swizzleClass : [path getRootViewControllerClass];
                
        if ([NSStringFromClass(swizzleClass) isEqualToString:@"UIViewController"]) {
            swizzleClass = nil;
            CleverTapLogStaticDebug(@"%@: Failed to set UIViewController as swizzle class for object path: %@, currently not supported", self, self.objPath);
        }
        if (!swizzleClass) {
            CleverTapLogStaticDebug(@"%@: Unable to determine swizzleClass for object path: %@ therefore not initialing the variant action", self, self.objPath);
            return nil;
        }
        self.swizzleClass = swizzleClass;
        
        if (!swizzleSelector) {
            if ([self.swizzleClass isSubclassOfClass:[UIViewController class]]) {
                 swizzleSelector = NSSelectorFromString(@"viewDidLayoutSubviews");
            } else {
                BOOL shouldUseLayoutSubviews = NO;
                NSArray *classesToUseLayoutSubviews = @[[UITableViewCell class], [UINavigationBar class]];
                for (Class klass in classesToUseLayoutSubviews) {
                    if ([self.swizzleClass isSubclassOfClass:klass] ||
                        [self.objPath pathContainsObjectOfClass:klass]) {
                        shouldUseLayoutSubviews = YES;
                        break;
                    }
                }
                swizzleSelector = NSSelectorFromString((shouldUseLayoutSubviews) ? @"layoutSubviews" : @"didMoveToWindow");
            }
        }
        self.swizzleSelector = swizzleSelector;
        self.appliedTo = [NSHashTable hashTableWithOptions:(NSHashTableWeakMemory|NSHashTableObjectPointerPersonality)];
    }
    return self;
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.objPath = [CTObjectSelector objectSelectorWithPath:[aDecoder decodeObjectForKey:@"path"]];
        self.selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
        self.args = [aDecoder decodeObjectForKey:@"args"];
        self.original = [aDecoder decodeObjectForKey:@"original"];
        self.swizzle = [(NSNumber *)[aDecoder decodeObjectForKey:@"swizzle"] boolValue];
        self.swizzleClass = NSClassFromString([aDecoder decodeObjectForKey:@"swizzleClass"]);
        self.swizzleSelector = NSSelectorFromString([aDecoder decodeObjectForKey:@"swizzleSelector"]);
        self.appliedTo = [NSHashTable hashTableWithOptions:(NSHashTableWeakMemory|NSHashTableObjectPointerPersonality)];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_objPath.path forKey:@"path"];
    [aCoder encodeObject:NSStringFromSelector(_selector) forKey:@"selector"];
    [aCoder encodeObject:_args forKey:@"args"];
    [aCoder encodeObject:_original forKey:@"original"];
    [aCoder encodeObject:@(_swizzle) forKey:@"swizzle"];
    [aCoder encodeObject:NSStringFromClass(_swizzleClass) forKey:@"swizzleClass"];
    [aCoder encodeObject:NSStringFromSelector(_swizzleSelector) forKey:@"swizzleSelector"];
}

- (UIImage *)imageFromImagesDictionary:(NSDictionary *)imagesDictionary {
    NSArray *imagesArray = imagesDictionary[@"images"];
    if (!imagesArray || ![imagesArray isKindOfClass:[NSArray class]] || [imagesArray count] <= 0) {
        return nil;
    }
    // only support static images for now
    NSDictionary *imageDictionary = imagesArray[0];
    NSString *url = imageDictionary[@"url"];
    
    UIImage *image = [CTNSDictionaryFromUIImageValueTransformer imageFromDictionary:imagesDictionary];
    if (image) {
        if (!self.imageUrls) {
            self.imageUrls = [NSMutableArray new];
        }
        if (url && ![self.imageUrls containsObject:url]) {
            [self.imageUrls addObject:url];
        }
    }
    return image;
}

#pragma mark Executing Actions

- (void)apply {
    NSMutableArray *originalArgs = [self.args mutableCopy];
    if (originalArgs && [originalArgs count] > 0) {
        for (NSUInteger i = 0, n = originalArgs.count; i < n; i++) {
            id originalArg = originalArgs[i];
            if ([originalArg isKindOfClass:[NSArray class]] && [originalArg count] > 0 && [originalArg[1] isEqual:@"UIImage"]) {
                UIImage *image = [self imageFromImagesDictionary:originalArg[0]];
                if (image) {
                    originalArgs[i] = @[image, @"UIImage"];
                }
            }
        }
    }
    // Block to execute on swizzle
    void (^executeBlock)(id, SEL) = ^(id view, SEL command) {
        [[self class] runSyncMainQueue:^{
            if (self.cacheOriginal || self.swizzle) {
                [self cacheOriginalImage:nil];
            }
            NSArray *invocations = [[self class] executeSelector:self.selector
                                                        withArgs:originalArgs
                                                          onPath:self.objPath
                                                        fromRoot:[CTInAppResources getSharedApplication].keyWindow.rootViewController
                                                          toLeaf:nil];
            
            for (NSInvocation *invocation in invocations) {
                [self.appliedTo addObject:invocation.target];
            }
        }];
    };
    
    // Execute the block once in case the view to be changed is already on screen.
    executeBlock(nil, _cmd);
    
    if (self.swizzle && self.swizzleClass != nil) {
        // Swizzle the method needed to check for this object coming onscreen
        [CTSwizzler ct_swizzleSelector:self.swizzleSelector
                            onClass:self.swizzleClass
                          withBlock:executeBlock
                              named:self.name];
    }
}

- (void)revert {
    if (self.swizzle && self.swizzleClass != nil) {
        [CTSwizzler ct_unswizzleSelector:self.swizzleSelector
                              onClass:self.swizzleClass
                                named:self.name];
    }
    
    [[self class] runSyncMainQueue:^{
        if (self.original) {
            [[self class] executeSelector:self.selector withArgs:self.original onObjects:self.appliedTo.allObjects];
        } else if (self.cacheOriginal || self.swizzle) {
            [self restoreCachedImage];
        }
        [self.appliedTo removeAllObjects];
    }];
}

- (void)cacheOriginalImage:(id)view {
    NSEnumerator *selectorEnum = [gettersForSetters keyEnumerator];
    SEL selector = nil, cacheSelector = nil;
    while ((selector = (SEL)((__bridge void *)[selectorEnum nextObject]))) {
        if (selector == self.selector) {
            cacheSelector = (SEL)(__bridge void *)[gettersForSetters objectForKey:MAPTABLE_ID(selector)];
            break;
        }
    }
    if (cacheSelector) {
        NSArray *cacheInvocations = [[self class] executeSelector:cacheSelector
                                                         withArgs:self.args
                                                           onPath:self.objPath
                                                         fromRoot:[CTInAppResources getSharedApplication].keyWindow.rootViewController
                                                           toLeaf:view];
        for (NSInvocation *invocation in cacheInvocations) {
            if (![originalCache objectForKey:invocation.target]) {
                void *result;
                [invocation getReturnValue:&result];
                UIImage *originalImage = (__bridge UIImage *)result;
                [originalCache setObject:originalImage forKey:invocation.target];
            }
        }
    }
}

- (void)restoreCachedImage {
    for (NSObject *object in self.appliedTo.allObjects) {
        id originalImage = [originalCache objectForKey:object];
        if (originalImage == nil) {
            originalImage = [UIImage new];
        }
        if (originalImage) {
            NSMutableArray *originalArgs = [self.args mutableCopy];
            for (NSUInteger i = 0, n = originalArgs.count; i < n; i++) {
                id originalArg = originalArgs[i];
                if ([originalArg isKindOfClass:[NSArray class]] && [originalArg[1] isEqual:@"UIImage"]) {
                    originalArgs[i] = @[originalImage, @"UIImage"];
                    break;
                }
            }
            [[self class] executeSelector:self.selector withArgs:originalArgs onObjects:@[object]];
            [originalCache removeObjectForKey:object];
        }
    }
}

- (void)cleanup {
    if (!self.imageUrls || [self.imageUrls count] <= 0) {
        return;
    }
    for (NSString *imageUrl in self.imageUrls) {
        [CTEditorImageCache removeImage:imageUrl];
    }
    self.imageUrls = [NSMutableArray new];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Action: Change %@ on %@ matching %@ from %@ to %@", NSStringFromSelector(self.selector), NSStringFromClass(self.class), self.objPath.path, self.original ?: (self.cacheOriginal ? @"Cached Original" : nil), self.args];
}

+ (NSArray *)executeSelector:(SEL)selector withArgs:(NSArray *)args onPath:(CTObjectSelector *)path fromRoot:(NSObject *)root toLeaf:(NSObject *)leaf {
    if (leaf) {
        if ([path isLeafSelected:leaf fromRoot:root]) {
            return [self executeSelector:selector withArgs:args onObjects:@[leaf]];
        } else {
            return @[];
        }
    } else {
        return [self executeSelector:selector withArgs:args onObjects:[path selectFromRoot:root]];
    }
}

+ (NSArray *)executeSelector:(SEL)selector withArgs:(NSArray *)args onObjects:(NSArray *)objects {
    NSMutableArray *invocations = [NSMutableArray array];
    for (__strong NSObject *o in objects) {
        if ([o isKindOfClass:[UIViewController class]]) {
            o = ((UIViewController*)o).view;
        }
        NSMethodSignature *signature = [o methodSignatureForSelector:selector];
        if (signature != nil) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation retainArguments];
            NSUInteger requiredArgs = signature.numberOfArguments - 2;
            if (args.count >= requiredArgs) {
                [invocation setSelector:selector];
                for (NSUInteger i = 0; i < requiredArgs; i++) {
                    NSArray *argTuple = args[i];
                    if (![argTuple[1] isKindOfClass:[NSString class]]) continue;
                    
                    id arg = transformValue(argTuple[0], argTuple[1]);

                    if ([arg isKindOfClass:[NSValue class]]) {
                        const char *ctype = [(NSValue *)arg objCType];
                        NSUInteger size;
                        NSGetSizeAndAlignment(ctype, &size, nil);
                        void *buf = malloc(size);
                        [(NSValue *)arg getValue:buf];
                        [invocation setArgument:buf atIndex:(int)(i+2)];
                        free(buf);
                    } else {
                        [invocation setArgument:(void *)&arg atIndex:(int)(i+2)];
                    }
                }
                @try {
                    if ([NSStringFromSelector(selector) isEqualToString:@"setFrame:"] && ![o isKindOfClass:[UINavigationBar class]]) {
                        ((UIView *)o).translatesAutoresizingMaskIntoConstraints = YES;
                    }
                    [invocation invokeWithTarget:o];
                }
                @catch (NSException *exception) {
                    CleverTapLogStaticDebug(@"%@: Exception during invocation: %@", self, exception);
                }
                [invocations addObject:invocation];
            } else {
                CleverTapLogStaticDebug(@"%@: Provided args are not enough", self);
            }
        } else {
            CleverTapLogStaticDebug(@"%@: Method not found for %@", self, NSStringFromSelector(selector));
        }
    }
    return [invocations copy];
}

#pragma mark Equality

- (BOOL)isEqualToAction:(CTABVariantAction *)action {
    return [self.name isEqualToString:action.name];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[CTABVariantAction class]]) {
        return NO;
    }
    return [self isEqualToAction:(CTABVariantAction *)object];
}

- (NSUInteger)hash {
    return [self.name hash];
}

@end

