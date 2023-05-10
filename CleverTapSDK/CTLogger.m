#import "CTLogger.h"
#import "CTConstants.h"

@implementation CTLogger

static int _debugLevel = 0;

+ (void)setDebugLevel:(int)level {
    _debugLevel = level;
}

+ (int)getDebugLevel {
    return _debugLevel;
}

+ (void)logInternalError:(NSException *)e {
    CleverTapLogDebug(_debugLevel, @"%@: Caught exception in code: %@\n%@", self, e, [e callStackSymbols]);
}

@end
