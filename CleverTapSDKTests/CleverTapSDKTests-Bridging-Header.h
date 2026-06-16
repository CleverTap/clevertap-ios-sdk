//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
// CleverTapInternal.h provides access to the sessionManager property and other
// internal CleverTap additions used by the test suite.
// Pattern B: Test targets (binary wrappers) are permitted to use bridging headers,
// unlike framework targets. Import private SDK headers directly here so Swift
// test files can access internal types without importing the private module.
#import "CleverTapInternal.h"
#import "CTConstants.h"
