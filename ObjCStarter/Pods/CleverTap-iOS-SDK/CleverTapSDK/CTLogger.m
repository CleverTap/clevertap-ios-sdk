
#import "CTLogger.h"

@implementation CTLogger

static int _debugLevel = 0;

+ (void)setDebugLevel:(int)level {
    _debugLevel = level;
}

+ (int)getDebugLevel {
    return _debugLevel;
}

@end
