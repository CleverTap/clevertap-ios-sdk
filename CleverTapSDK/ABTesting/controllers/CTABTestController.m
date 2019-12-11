#import <UIKit/UIKit.h>
#import "CTABTestController.h"
#import "CleverTap.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTInAppResources.h"
#import "CTWebSocket.h"
#import "CTConstants.h"
#import "CTVar.h"
#import "CTVarCache.h"
#import "CTPreferences.h"
#import "CTABTestUtils.h"
#import "CTEditorSession.h"
#import "CTObjectSerializerConfig.h"
#import "CTABTestEditorHandshakeMessage.h"
#import "CTABTestEditorVarsMessageRequest.h"
#import "CTABTestEditorSnapshotMessageRequest.h"
#import "CTABTestEditorDeviceInfoMessageRequest.h"

static NSString * const kStartLoadingKey = @"CTConnectLoadingAnimation";
static NSString * const kFinishLoadingKey = @"CTConnectFinishLoadingAnimation";
static NSString * const kDASHBOARD_DOMAIN = @"dashboard.clevertap.com";
static NSString * const kDEFAULT_REGION = @"eu1";

typedef void (^CTABTestingOperationBlock)(void);

@interface CTABTestController () <CTWebSocketDelegate>
@property (nonatomic, strong) UILongPressGestureRecognizer *testConnectGestureRecognizer;
@property (atomic, copy) NSString *guid;
@property (atomic, strong) CleverTapInstanceConfig *config;
@property (atomic, strong) CTEditorSession *session;
@property (atomic, assign) BOOL sessionEnded;
@property (atomic, strong) CTVarCache *varCache;
@property (nonatomic, strong) NSSet *variants;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;

@end

@implementation CTABTestController {
    BOOL _open;
    BOOL _connected;
    NSURL *_url;
    NSDictionary *_typeToMessagesMap;
    CTWebSocket *_webSocket;
    NSOperationQueue *_commandQueue;
    UIView *_recordingView;
    CALayer *_indeterminateLayer;
}

- (instancetype)initWithConfig:(CleverTapInstanceConfig*)config guid:(NSString * _Nonnull)guid delegate:(id<CTABTestingDelegate>)delegate {
    self = [super init];
    if (self) {
        _typeToMessagesMap = @{
           CTABTestEditorDeviceInfoMessageRequestType : [CTABTestEditorDeviceInfoMessageRequest class],
           CTABTestEditorSnapshotMessageRequestType   : [CTABTestEditorSnapshotMessageRequest class],
           CTABTestEditorVarsMessageRequestType       : [CTABTestEditorVarsMessageRequest class]
         };
        _delegate = delegate;
        _config = config;
        _guid = guid;
        NSString *protocol = @"wss";
        NSString *region = _config.accountRegion ? _config.accountRegion : kDEFAULT_REGION;
        region = _config.beta ? [NSString stringWithFormat:@"%@-dashboard-beta", region] : region;
        NSString *domain =  [NSString stringWithFormat:@"%@.%@", region, kDASHBOARD_DOMAIN];
        NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@/websocket/screenab/sdk?tk=%@", protocol, domain, _config.accountId, _config.accountToken];
        _url = [NSURL URLWithString:urlString];
        _open = NO;
        _connected = NO;
        _sessionEnded = NO;
        _commandQueue = [[NSOperationQueue alloc] init];
        _commandQueue.maxConcurrentOperationCount = 1;
        _commandQueue.suspended = YES;
        _varCache = [[CTVarCache alloc] init];
        _variants = [NSSet set];
        _deviceInfo = [delegate getDeviceInfo];
        [self addGestureRecognizer];
        [self _unarchiveVariantsSync:NO];
    }
    return self;
}

- (void)dealloc {
    _webSocket.delegate = nil;
    [self close];
}

// be sure to call off the main thread
- (void)updateExperiments:(NSArray<NSDictionary*> *)experiments {
    [self _updateExperiments:experiments];
}

// be sure to call off the main thread
- (void)resetWithGuid:(NSString*)guid {
    _commandQueue.suspended = YES;
    [_commandQueue cancelAllOperations];
    [self close];
    [self.varCache reset];
    self.variants = [NSSet set];
    _guid = guid;
    [self _unarchiveVariantsSync:YES];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"CleverTap.%@.CTABTestController", _config.accountId];
}

#pragma Vars

- (void)registerBoolVariableWithName:(NSString* _Nonnull)name {
    [self _registerVar:name type:CTVarTypeBool andValue:nil];
}

- (void)registerDoubleVariableWithName:(NSString* _Nonnull)name {
    [self _registerVar:name type:CTVarTypeDouble andValue:nil];
}

- (void)registerIntegerVariableWithName:(NSString* _Nonnull)name {
    [self _registerVar:name type:CTVarTypeInteger andValue:nil];
}

- (void)registerStringVariableWithName:(NSString* _Nonnull)name {
    [self _registerVar:name type:CTVarTypeString andValue:nil];
}

- (void)registerArrayOfBoolVariableWithName:(NSString* _Nonnull)name {
    [self _registerVar:name type:CTVarTypeArrayOfBool andValue:nil];
}

- (void)registerArrayOfDoubleVariableWithName:(NSString* _Nonnull)name {
    [self _registerVar:name type:CTVarTypeArrayOfDouble andValue:nil];
}

- (void)registerArrayOfIntegerVariableWithName:(NSString* _Nonnull)name {
    [self _registerVar:name type:CTVarTypeArrayOfInteger andValue:nil];
}

- (void)registerArrayOfStringVariableWithName:(NSString* _Nonnull)name {
    [self _registerVar:name type:CTVarTypeArrayOfString andValue:nil];
}

- (void)registerDictionaryOfBoolVariableWithName:(NSString* _Nonnull)name {
    [self _registerVar:name type:CTVarTypeDictionaryOfBool andValue:nil];
}

- (void)registerDictionaryOfDoubleVariableWithName:(NSString* _Nonnull)name {
    [self _registerVar:name type:CTVarTypeDictionaryOfDouble andValue:nil];
}

- (void)registerDictionaryOfIntegerVariableWithName:(NSString* _Nonnull)name {
    [self _registerVar:name type:CTVarTypeDictionaryOfInteger andValue:nil];
}

- (void)registerDictionaryOfStringVariableWithName:(NSString* _Nonnull)name {
    [self _registerVar:name type:CTVarTypeDictionaryOfString andValue:nil];
}

- (BOOL)getBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(BOOL)defaultValue {
    CleverTapLogDebug(self.config.logLevel, @"%@:Get Bool Variable With Name: %@", self, name);
    CTVar *existing = [self.varCache getVarWithName:name];
    if (existing && [existing numberValue]) {
        return [[existing numberValue] boolValue];
    }
    return defaultValue;
}

- (double)getDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(double)defaultValue {
    CleverTapLogDebug(self.config.logLevel, @"%@:Get Double Variable With Name: %@", self, name);
    CTVar *existing = [self.varCache getVarWithName:name];
    if (existing && [existing numberValue]) {
        return [[existing numberValue] doubleValue];
    }
    return defaultValue;
}

- (int)getIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(int)defaultValue {
    CleverTapLogDebug(self.config.logLevel, @"%@:Get Integer Variable With Name: %@", self, name);
    CTVar *existing = [self.varCache getVarWithName:name];
    if (existing && [existing numberValue]) {
        return [[existing numberValue] intValue];
    }
    return defaultValue;
}

- (NSString* _Nonnull)getStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSString * _Nonnull)defaultValue {
    CleverTapLogDebug(self.config.logLevel, @"%@:Get String Variable With Name: %@", self, name);
    CTVar *existing = [self.varCache getVarWithName:name];
    if (existing && [existing stringValue]) {
        return [existing stringValue];
    }
    return defaultValue;
}

- (NSArray<NSNumber*>* _Nonnull)getArrayOfBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue {
    CleverTapLogDebug(self.config.logLevel, @"%@:Get ArrayOfBool Variable With Name: %@", self, name);
    return [self _getArrayVariableWithName:name defaultValue:defaultValue];
}

- (NSArray<NSNumber*>* _Nonnull)getArrayOfDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue {
    CleverTapLogDebug(self.config.logLevel, @"%@:Get ArrayOfDouble Variable With Name: %@", self, name);
    return [self _getArrayVariableWithName:name defaultValue:defaultValue];
}

- (NSArray<NSNumber*>* _Nonnull)getArrayOfIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue {
    CleverTapLogDebug(self.config.logLevel, @"%@:Get ArrayOfInteger Variable With Name: %@", self, name);
    return [self _getArrayVariableWithName:name defaultValue:defaultValue];
}

- (NSArray<NSString*>* _Nonnull)getArrayOfStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSString*>* _Nonnull)defaultValue {
    CleverTapLogDebug(self.config.logLevel, @"%@:Get ArrayOfString Variable With Name: %@", self, name);
    return [self _getArrayVariableWithName:name defaultValue:defaultValue];
}

- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue {
    CleverTapLogDebug(self.config.logLevel, @"%@:Get DictionaryOfBool Variable With Name: %@", self, name);
    return [self _getDictionaryVariableWithName:name defaultValue:defaultValue];
}

- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue {
    CleverTapLogDebug(self.config.logLevel, @"%@:Get DictionaryOfDouble Variable With Name: %@", self, name);
    return [self _getDictionaryVariableWithName:name defaultValue:defaultValue];
}

- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue {
    CleverTapLogDebug(self.config.logLevel, @"%@:Get DictionaryOfInteger Variable With Name: %@", self, name);
    return [self _getDictionaryVariableWithName:name defaultValue:defaultValue];
}

- (NSDictionary<NSString*, NSString*>* _Nonnull)getDictionaryOfStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSString*>* _Nonnull)defaultValue {
    CleverTapLogDebug(self.config.logLevel, @"%@:Get DictionaryOfString Variable With Name: %@", self, name);
    return [self _getDictionaryVariableWithName:name defaultValue:defaultValue];
}

#pragma Private

- (NSArray*)_getArrayVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray*)defaultValue {
    CTVar *existing = [self.varCache getVarWithName:name];
    if (existing && [existing arrayValue]) {
        return [existing arrayValue];
    }
    return defaultValue;
}

- (NSDictionary*)_getDictionaryVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary*)defaultValue {
    CTVar *existing = [self.varCache getVarWithName:name];
    if (existing && [existing dictionaryValue]) {
        return [existing dictionaryValue];
    }
    return defaultValue;
}
- (NSString*)variantsArchiveFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-variants.plist", _config.accountId, _guid];
}

- (void)_unarchiveVariantsSync:(BOOL)sync {
    NSString *filePath = [self variantsArchiveFileName];
     __weak CTABTestController *weakSelf = self;
    CTABTestingOperationBlock opBlock = ^{
        NSSet *variants = (NSSet *)[CTPreferences unarchiveFromFile:filePath removeFile:NO];
        if (variants) {
            weakSelf.variants = variants;
        }
        [weakSelf _applyVariants:variants new:NO];
    };
    if (sync) {
        opBlock();
    } else {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:opBlock];
        _commandQueue.suspended = NO;
        [_commandQueue addOperation:operation];
    }
}

- (void)_archiveVariants:(NSSet*)variants sync:(BOOL)sync {
    NSString *filePath = [self variantsArchiveFileName];
    CTABTestingOperationBlock opBlock = ^{
         [CTPreferences archiveObject:variants forFileName:filePath];
    };
    if (sync) {
        opBlock();
    } else {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:opBlock];
        _commandQueue.suspended = NO;
        [_commandQueue addOperation:operation];
    }
}

// be sure to call off the main thread
- (void)_updateExperiments:(NSArray<NSDictionary*> *)experiments {
    if (experiments == nil) {
        return;
    }
    
    // if the experiment come as an empty array, mark all experiments as finished.
    if (experiments.count <= 0){
        [self.varCache reset];
        for (CTABVariant *variant in self.variants) {
            [variant revertActions];
        }
    }
    
    NSMutableSet *parsed = [NSMutableSet set];
    NSMutableSet *newVariants = [NSMutableSet set];
    
    NSSet *finished = [NSSet setWithSet:[self.variants objectsPassingTest:^BOOL(CTABVariant *var, BOOL *stop) { return var.finished; }]];
    NSSet *running = [NSSet setWithSet:[self.variants objectsPassingTest:^BOOL(CTABVariant *var, BOOL *stop) { return var.running; }]];
    
    for (id variantData in experiments) {
        CTABVariant *parseVariant = [CTABVariant variantWithData:variantData];
        if (parseVariant) {
           [parsed addObject:parseVariant];
        }
    }
    
    NSMutableSet *toMarkFinished = [NSMutableSet setWithSet:running];
    [toMarkFinished minusSet:parsed];
    [newVariants unionSet:parsed];
    [newVariants minusSet:running];
    NSMutableSet *toRestart = [NSMutableSet setWithSet:parsed];
    [toRestart intersectSet:running];
    [toRestart intersectSet:finished];
    NSMutableSet *allVariants = [NSMutableSet setWithSet:newVariants];
    [allVariants unionSet:running];
    [toMarkFinished makeObjectsPerformSelector:NSSelectorFromString(@"finish")];
    [toRestart makeObjectsPerformSelector:NSSelectorFromString(@"restart")];
    
    [self _applyVariants:newVariants new:YES];
    self.variants = [allVariants copy];
    [self _archiveVariants:self.variants sync:YES];
}

- (void)_applyVariants:(NSSet *)variants new:(BOOL)areNew {
    for (CTABVariant *variant in variants) {
        [variant applyActions];
        [self applyVars:variant.vars];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(abExperimentsDidUpdate)]) {
        [self.delegate abExperimentsDidUpdate];
    }
}

- (CTObjectSerializerConfig *)configurationFromData:(NSDictionary *)data {
    NSDictionary *config = data[@"config"];
    return config ? [[CTObjectSerializerConfig alloc] initWithDictionary:config] : nil;
}

#pragma mark - Handle Editor Messages

- (void)sendHandshake {
    NSMutableDictionary *_ops = [NSMutableDictionary dictionaryWithDictionary:@{@"id":self.guid, @"name": self.deviceInfo.deviceName, @"os": self.deviceInfo.osName}];
    if (self.deviceInfo.library) {
        _ops[@"library"] = self.deviceInfo.library;
    }
    NSDictionary *options = @{@"data": _ops};
    CTABTestEditorHandshakeMessage *editorMessage = [CTABTestEditorHandshakeMessage messageWithOptions:options];
    CTABTestingOperationBlock opBlock = ^{
        CTABTestEditorMessage *response = [editorMessage response];
        if (response) {
            [self sendMessage: response];
        }
    };
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:opBlock];
    if (operation) {
        [_commandQueue addOperation:operation];
    }
}

- (void)handleConnected {
    _connected = YES;
    _commandQueue.suspended = NO;
    _session = [[CTEditorSession alloc] init];
    [self sendHandshake];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CTInAppResources getSharedApplication] setIdleTimerDisabled:YES];
    });
   
}

- (void)handleSessionStarted {
    [self.varCache reset];
    for (CTABVariant *variant in self.variants) {
        [variant revertActions];
    }
}

- (void)handleSessionEnded {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CTInAppResources getSharedApplication] setIdleTimerDisabled:NO];
    });
    self.sessionEnded = YES;
    CTABVariant *variant = [_session sessionObjectForKey:kCTSessionVariantKey];
    if (variant) {
        [variant revertActions];
        [variant cleanup];
    }
    [self.varCache reset];
    [self close];
    for (CTABVariant *variant in self.variants) {
        [variant applyActions];
        [self applyVars:variant.vars];
    }
}

- (void)sendMessage:(CTABTestEditorMessage *)message {
    if (_webSocket && _connected) {
        CleverTapLogDebug(_config.logLevel, @"Sending message: %@", [message debugDescription]);
        NSString *jsonString = [[NSString alloc] initWithData:[message JSONData] encoding:NSUTF8StringEncoding];
        [_webSocket send:jsonString];
    } else {
        CleverTapLogInternal(_config.logLevel, @"%@: Unable to send message, not connected to web socket", [message debugDescription]);
    }
}

- (void)handleWebSocketMessage:(id)message {
    if (!message) return;
    
    if (self.sessionEnded) {
        CleverTapLogDebug(_config.logLevel, @"Editor Session is ended ignorning message: %@", message);
    }
     
    NSData *jsonData = [message isKindOfClass:[NSString class]] ? [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding] : message;
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:(NSJSONReadingOptions)0 error:&error];
    
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *messageDictionary = (NSDictionary *)jsonObject;
        NSString *type = messageDictionary[@"type"];
        NSDictionary *data = messageDictionary[@"data"];
        
        CTABTestingOperationBlock opBlock = nil;
        if ([type isEqualToString:CTABTestEditorSessionStartRequestType]) {
            opBlock = ^{
                [self handleSessionStarted];
            };
        } else if ([type isEqualToString:CTABTestEditorChangeMessageRequestType]) {
            opBlock = ^{
              [self handleTestEditorChangeRequestWithData:data];
            };
        } else if  ([type isEqualToString:CTABTestEditorClearMessageRequestType]) {
            opBlock = ^{
               [self handleTestEditorClearRequestWithData:data];
            };
        } else if ([type isEqualToString:CTABTestVarsRequestType]) {
            opBlock = ^{
               [self handleTestVars:data];
            };
        }  else if ([type isEqualToString:CTABTestEditorDisconnectMessageRequestType]) {
            opBlock = ^{
                [self handleSessionEnded];
            };
        } else {
            CTABTestEditorMessage *editorMessage = [self editorMessageForMessage:messageDictionary];
            opBlock = ^{
                CTABTestEditorMessage *response = [editorMessage response];
                if (response) {
                    [self sendMessage: response];
                }
            };
        }
        if (opBlock) {
            NSOperation *operation = [NSBlockOperation blockOperationWithBlock:opBlock];
            if (operation) {
                [_commandQueue addOperation:operation];
            }
        }
    } else {
        CleverTapLogDebug(_config.logLevel, @"Invalid socket message expected JSON dictionary: %@", error);
    }
}

- (CTABTestEditorMessage *)editorMessageForMessage:(NSDictionary*)messageDictionary {
    CleverTapLogInfo(_config.logLevel, @"Editor message: %@", messageDictionary);
    CTABTestEditorMessage *editorMessage = nil;
    NSString *type = messageDictionary[@"type"];
    NSDictionary *data = messageDictionary[@"data"];
    CTObjectSerializerConfig *config = [self configurationFromData:data];
    if (config) {
        [_session setSessionObject:config forKey:kSnapshotSerializerConfigKey];
    }
    NSMutableDictionary *options = [NSMutableDictionary new];
    options[@"session"] = _session;
    options[@"data"] = data;

    if ([type isEqualToString:CTABTestEditorVarsMessageRequestType]) {
        options[@"vars"] = [self.varCache serializeVars];
    }

    if ([type isEqualToString:CTABTestEditorDeviceInfoMessageRequestType]) {
        options[@"deviceInfo"] = self.deviceInfo;
    }
    editorMessage = [_typeToMessagesMap[type] messageWithOptions:options];
    return editorMessage;
}

- (void)handleTestEditorChangeRequestWithData:(NSDictionary *)data {
    CTABVariant *variant = [_session sessionObjectForKey:kCTSessionVariantKey];
    if (!variant) {
        variant = [[CTABVariant alloc] init];
        [_session setSessionObject:variant forKey:kCTSessionVariantKey];
    }
    id actions = data[@"actions"];
    if ([actions isKindOfClass:[NSArray class]]) {
        [variant addActions:actions andApply:YES];
    }
}

- (void)handleTestEditorClearRequestWithData:(NSDictionary *)data {
    CTABVariant *variant = [_session sessionObjectForKey:kCTSessionVariantKey];
    if (variant) {
        NSArray *actions = data[@"actions"];
        if (actions && actions.count == 0) {
            [variant revertActions];
            return;
        }
        for (NSString *name in actions) {
            [variant removeActionWithName:name];
        }
    }
}

- (void)handleTestVars:(NSDictionary *)data {
    [self applyVars:data[@"vars"]];
}

- (void)applyVars:(NSArray *)vars {
    @try {
        if (vars && [vars isKindOfClass:[NSArray class]]) {
            for (NSDictionary* var in vars) {
                [self _registerVar:var[@"name"] type:[CTABTestUtils CTVarTypeFromString:var[@"type"]] andValue:var[@"value"]];
            }
        }
    } @catch (NSException *e) {
        CleverTapLogDebug(_config.logLevel, @"%@: Unable to apply vars: %@", self, e.description);
    }
}

- (void)clearVars:(NSArray *)vars {
    @try {
        if (vars && [vars isKindOfClass:[NSArray class]]) {
            for (NSDictionary* var in vars) {
                [self.varCache clearVarWithName:var[@"name"]];
            }
        }
    } @catch (NSException *e) {
        CleverTapLogDebug(_config.logLevel, @"%@: Unable to clear vars: %@", self, e.description);
    }
}

- (void)_registerVar:(NSString *)name type:(CTVarType)type andValue:(id)value {
    [self.varCache registerVarWithName:name type:type andValue:value];
    CleverTapLogDebug(self.config.logLevel, @"%@: Registered Variable with name: %@, type: %@, value:%@", self, name, [CTABTestUtils StringFromCTVarType:type], value);
}

- (void)addGestureRecognizer {
    if (!_config.enableUIEditor) {
        CleverTapLogDebug(_config.logLevel, @"%@: UIEditor Connection is disabled", self);
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.testConnectGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTestConnectGesture:)];
        self.testConnectGestureRecognizer.minimumPressDuration = 3;
        self.testConnectGestureRecognizer.cancelsTouchesInView = NO;
        self.testConnectGestureRecognizer.numberOfTouchesRequired = 2;
        self->_testConnectGestureRecognizer.enabled = self->_config.enableUIEditor;
        [[CTInAppResources getSharedApplication].keyWindow addGestureRecognizer:self.testConnectGestureRecognizer];
        CleverTapLogDebug(self->_config.logLevel, @"%@: Added ABTest Editor connection gesture recognizer, enabled state is %@", self, self->_testConnectGestureRecognizer.enabled ? @"YES": @"NO");
    });
}

- (void)handleTestConnectGesture:(id)sender {
    if (!sender || ([sender isKindOfClass:[UIGestureRecognizer class]] && ((UIGestureRecognizer *)sender).state == UIGestureRecognizerStateBegan)) {
        CleverTapLogDebug(_config.logLevel, @"%@: Handling the ABTest Editor connection gesture", self);
        [self connectEditor];
    }
}

- (void)connectEditor {
    if (_connected) {
        return;
    }
    self.sessionEnded = NO;
    CleverTapLogDebug(_config.logLevel, @"%@: Connecting to the Editor", self);
    [self open:YES maxInterval:0 maxRetries:0];
}

- (void)open:(BOOL)initiate maxInterval:(int)maxInterval maxRetries:(int)maxRetries {
    static int retries = 0;
    BOOL inRetryLoop = retries > 0;
    CleverTapLogDebug(_config.logLevel, @"%@: In websocket open. initiate = %d, retries = %d, maxRetries = %d, maxInterval = %d, connected = %d", self, initiate, retries, maxRetries, maxInterval, _connected);
    if (self.sessionEnded || _connected || (inRetryLoop && retries >= maxRetries) ) {
        retries = 0;
    } else if (initiate ^ inRetryLoop) {
        if (!_open) {
            CleverTapLogDebug(_config.logLevel, @"%@: Attempting to open WebSocket to: %@, try %d/%d ", self, _url, retries, maxRetries);
            _open = YES;
            _webSocket = [[CTWebSocket alloc] initWithURL:_url];
            _webSocket.delegate = self;
            [_webSocket open];
        }
        if (retries < maxRetries) {
            __weak CTABTestController *weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MIN(pow(1.4, retries), maxInterval) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                CTABTestController *strongSelf = weakSelf;
                [strongSelf open:NO maxInterval:maxInterval maxRetries:maxRetries];
            });
            retries++;
        }
    }
}

- (void)close {
    [_webSocket close];
    _session = nil;
}

#pragma mark - CTWebSocketDelegate Methods

- (void)webSocket:(CTWebSocket *)webSocket didReceiveMessage:(id)message {
    if (!_connected) {
        _connected = YES;
    }
    CleverTapLogDebug(_config.logLevel, @"%@: WebSocket did receive message: %@", self, message);
    [self handleWebSocketMessage:message];
}

- (void)webSocketDidOpen:(CTWebSocket *)webSocket {
     CleverTapLogDebug(_config.logLevel, @"%@: %@ did open.", self, webSocket);
    [self handleConnected];
}

- (void)webSocket:(CTWebSocket *)webSocket didFailWithError:(NSError *)error {
    CleverTapLogDebug(_config.logLevel, @"%@: WebSocket did fail with error: %@", self, error);
    _commandQueue.suspended = YES;
    [_commandQueue cancelAllOperations];
    _open = NO;
    if (_connected) {
        _connected = NO;
       [self open:YES maxInterval:10 maxRetries:10];
    }
}

- (void)webSocket:(CTWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    CleverTapLogInternal(_config.logLevel, @"%@: WebSocket did close with code '%d' reason '%@'.", self, (int)code, reason);
    _commandQueue.suspended = YES;
    [_commandQueue cancelAllOperations];
    _open = NO;
    if (_connected) {
        _connected = NO;
        [self handleSessionEnded];
    }
}

@end
