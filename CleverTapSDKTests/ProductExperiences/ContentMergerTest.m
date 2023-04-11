//
//  ContentMergerTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 23.03.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "ContentMerger.h"

@interface ContentMergerTest : XCTestCase

@end

@implementation ContentMergerTest

- (void)testMergePrimitive {
    NSString *vars = @"a";
    NSNumber *diff = @4;
    NSNumber *result = (NSNumber *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertEqualObjects(diff, result);
}

- (void)testMergeBool {
    NSNumber *vars = @YES;
    NSNumber *diff = @NO;
    NSNumber *result = (NSNumber *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertEqualObjects(diff, result);
    XCTAssertFalse([result boolValue]);
}

- (void)testMergeBoolYes {
    NSNumber *vars = @NO;
    NSNumber *diff = @YES;
    NSNumber *result = (NSNumber *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertEqualObjects(diff, result);
    XCTAssertTrue([result boolValue]);
}

- (void)testMergeMapWithPrimitive {
    NSDictionary *vars = @{
        @"abc": @"qwe",
        @"1": @123
    };
    NSString *diff = @"diff";
    NSString *result = (NSString *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertEqualObjects(diff, result);
}

- (void)testMergeValues {
    NSString *resultString = (NSString *)[ContentMerger mergeWithVars:@"defaultValue" diff:@"newValue"];
    XCTAssertEqualObjects(@"newValue", resultString);
    
    NSNumber *resultNumber = (NSNumber *)[ContentMerger mergeWithVars:@199 diff:@123456789];
    XCTAssertEqualObjects(@123456789, resultNumber);
    
    NSString *resultNull = (NSString *)[ContentMerger mergeWithVars:[NSNull null] diff:@"newValue"];
    XCTAssertEqualObjects(@"newValue", resultNull);
}

- (void)testMergeValuesComplex {
    NSDictionary *vars = @{
        @"messageId1": @{
            @"vars": @{
                @"myNumber": @0,
                @"myString": @"defaultValue"
            }
        }
    };
    
    NSDictionary *diff = @{
        @"messageId1": @{
            @"vars": @{
                @"myNumber": @1,
                @"myString": @"newValue"
            }
        }
    };
    
    NSDictionary *expected = diff;
    NSDictionary *result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertTrue([result isEqualToDictionary:expected]);
}

- (void)testMergeValuesIncludeDefaults {
    NSDictionary *vars = @{
        @"messageId1": @{
            @"vars": @{
                @"myNumber": @0,
                @"myString": @"defaultValue"
            }
        }
    };
    
    NSDictionary *diff = @{
        @"messageId1": @{
            @"vars": @{
                @"myString": @"newValue"
            }
        }
    };
    
    NSDictionary *expected = @{
        @"messageId1": @{
            @"vars": @{
                @"myNumber": @0,
                @"myString": @"newValue"
            }
        }
    };
    
    NSDictionary *result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertTrue([result isEqualToDictionary:expected]);
}

- (void)testMergeDictionaries {
    NSDictionary *vars = @{
        @"abc": @"qwe",
        @"nested2": @{
            @"a": @"a",
            @"c": [NSNull null],
            @"d": @4444
        }
    };
    
    NSDictionary *diff = @{
        @"abc": @"rty",
        @"nested2": @{
            @"a": @"a",
            @"c": @"value",
            @"d": @555
        }
    };
    
    NSDictionary *expected = @{
        @"abc": @"rty",
        @"nested2": @{
            @"a": @"a",
            @"c": @"value",
            @"d": @555
        }
    };

    id result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertTrue([expected isEqualToDictionary:result]);
}

- (void)testMergeDictionariesWithNull {
    NSDictionary *vars = @{
        @"a": [NSNull null],
        @"b": [NSNull null]
    };
    
    NSDictionary *diff = @{
        @"a": @"text",
        @"c": [NSNull null]
    };
    
    NSDictionary *expected = @{
        @"a": @"text",
        @"b": [NSNull null],
        @"c": [NSNull null]
    };

    id result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertTrue([expected isEqualToDictionary:result]);
}

- (void)testMergeDictionariesIncludeDefaults {
    NSDictionary *vars = @{
        @"abc": @"qwe",
        @"nested": @{
            @"abc": @"qwe",
            @"1": @123
        },
        @"nested2": @{
            @"a": @"a",
            @"b": @[@1, @2, @3, @4],
            @"c": [NSNull null],
            @"d": @4444
        }
    };
    
    NSDictionary *diff = @{
        @"nested": @{
            @"abc": @"abc",
            @"qwerty": @"qwerty"
        },
        @"nested2": @{
            @"a": @"b",
            @"d": @111,
            @"e": @999
        }
    };
    
    NSDictionary *expected = @{
        @"abc": @"qwe",
        @"nested": @{
            @"abc": @"abc",
            @"1": @123,
            @"qwerty": @"qwerty"
        },
        @"nested2": @{
            @"a": @"b",
            @"b": @[@1, @2, @3, @4],
            @"c": [NSNull null],
            @"d": @111,
            @"e": @999
        }
    };
    
    id result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertTrue([expected isEqualToDictionary:result]);
}

- (void)testMergeDictionariesIncludeDiffs {
    NSDictionary *vars = @{
        @"abc": @"qwe",
        @"nested": @{
            @"abc": @"qwe",
            @"1": @123
        }
    };
    
    NSDictionary *diff = @{
        @"nested": @{
            @"qwerty": @"qwerty",
            @"nested2": @{
                @"a": @"b"
            }
        }
    };
    
    NSDictionary *expected = @{
        @"abc": @"qwe",
        @"nested": @{
            @"abc": @"qwe",
            @"1": @123,
            @"qwerty": @"qwerty",
            @"nested2": @{
                @"a": @"b"
            }
        }
    };
    
    id result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertTrue([expected isEqualToDictionary:result]);
}

- (void)testMergeWithEmpty {
    NSDictionary *vars = @{
        @"abc": @"qwe",
        @"nested": @{
            @"abc": @"qwe",
            @"1": @123
        }
    };
    
    NSDictionary *diff = @{};
    
    id result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertTrue([vars isEqualToDictionary:result]);
}

- (void)testMergeEmpty {
    NSDictionary *vars = @{};
    
    NSDictionary *diff = @{
        @"abc": @"qwe",
        @"nested": @{
            @"abc": @"qwe",
            @"1": @123
        }
    };
    
    id result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertTrue([diff isEqualToDictionary:result]);
}

- (void)testMergeNull {
    NSNull *vars = [NSNull null];
    
    NSDictionary *diff = @{
        @"abc": @"qwe",
        @"nested": @{
            @"abc": @"qwe",
            @"1": @123
        }
    };
    
    id result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertTrue([diff isEqualToDictionary:result]);
}

- (void)testMergeWithNull {
    NSDictionary *vars = @{};
    
    NSNull *diff = [NSNull null];
    
    id result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertTrue([[NSNull null] isEqual:result]);
}

- (void)testMergeDifferentTypes {
    NSDictionary *vars = @{
        @"k1": @20,
        @"k2": @"hi",
        @"k3": @YES,
        @"k4": @4.3
    };
    NSDictionary *diff = @{
        @"k1": @21,
        @"k3": @NO,
        @"k4": @-4.8
    };
    NSDictionary *expected = @{
        @"k1": @21,
        @"k2": @"hi",
        @"k3": @NO,
        @"k4": @-4.8
    };
    NSDictionary *result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertTrue([result isEqualToDictionary:expected]);
}

- (void)testMergeNestedDictionaries {
    NSDictionary *vars = @{
        @"k2": @{
            @"m1": @(1),
            @"m2": @"hello",
            @"m3": @(NO)
        },
        @"k3": @{
            @"m1": @(1),
            @"m2": @"hello",
            @"m3": @(NO)
        },
        @"k4": @{
            @"m1": @(1),
            @"m2": @"hello",
            @"m3": @(NO)
        },
        @"k5": @(4.3)
    };
    
    NSDictionary *diffs = @{
        @"k2": @{
            @"m1": @(1),
            @"m2": @"hello",
            @"m3": @(NO)
        },
        @"k3": @{
            @"m1": @(2),
            @"m2": @"bye",
            @"m3": @(YES)
        },
        @"k4": @{
            @"m1": @(2),
            @"m3": @(YES),
            @"m4": @"new key"
        }
    };
    
    NSDictionary *expected = @{
        @"k2": @{
            @"m1": @(1),
            @"m2": @"hello",
            @"m3": @(NO)
        },
        @"k3": @{
            @"m1": @(2),
            @"m2": @"bye",
            @"m3": @(YES)
        },
        @"k4": @{
            @"m1": @(2),
            @"m2": @"hello",
            @"m3": @(YES),
            @"m4": @"new key"
        },
        @"k5": @(4.3)
    };
    
    NSDictionary *result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diffs];
    XCTAssertEqualObjects(result, expected);
}

- (void)testMergeArr {
    NSArray *vars = @[@1, @2, @3, @4];
    NSArray *diff = @[@1, @2, @3, @6];
    
    // ContentMerger does not support merging arrays
    id result = (NSArray *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertNil(result);
}

- (void)testMergeDictionariesArr {
    NSDictionary *vars = @{
        @"arr": @[@1, @2, @3, @4],
    };
    
    NSDictionary *diff = @{
        @"arr": @[@1, @2, @3, @5],
    };
    
    // ContentMerger does not support merging arrays, expect vars dictionary
    id result = (NSDictionary *)[ContentMerger mergeWithVars:vars diff:diff];
    XCTAssertTrue([vars isEqualToDictionary:result]);
}

@end
