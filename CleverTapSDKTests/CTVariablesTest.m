//
//  CTVariablesTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 26.03.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTVariables.h"

@interface CTVariablesTest : XCTestCase

@property(strong, nonatomic) CTVariables *variables;

@end

@implementation CTVariablesTest

- (void)setUp {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"id" accountToken:@"token" accountRegion:@"eu"];
    CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:@"test"];
    _variables = [[CTVariables alloc] initWithConfig:config deviceInfo:deviceInfo];
}

- (void)tearDown {
    _variables = nil;
}

#pragma mark Unflatten Variables
- (void)testUnflattenVariables {
    NSDictionary *flat = @{
        @"a.b.c.d": @"d value",
        @"a.b.c.dd": @"dd value",
        @"a.e": @"e value",
        @"a.b.bb": @"bb value",
    };
    NSDictionary *expected = @{
        @"a": @{
            @"b": @{
                @"c": @{
                    @"d": @"d value",
                    @"dd": @"dd value"
                },
                @"bb": @"bb value"
            },
            @"e": @"e value"
        }
    };
    NSDictionary *result = [self.variables unflatten:flat];
    XCTAssertEqualObjects(result, expected);
}

- (void)testUnflattenWithFlatInput {
    NSDictionary *inputDict = @{
        @"a": @"value1",
        @"b": @123
    };
    
    NSDictionary *expectedOutput = @{
        @"a": @"value1",
        @"b": @123
    };
    
    NSDictionary *actualOutput = [self.variables unflatten:inputDict];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

- (void)testUnflattenWithDictionaryInput {
    NSDictionary *inputDict = @{
        @"testVarName.a.b": @{
            @"defaultValue": @"value1"
        },
        @"testVarName.a.c.d": @{
            @"defaultValue": @"value2"
        },
        @"testVarName.e": @{
            @"defaultValue": @"value3"
        },
        @"testVarName.f": @{
            @"defaultValue": @"value4"
        }
    };
    
    NSDictionary *expectedOutput = @{
        @"testVarName": @{
            @"a": @{
                @"b": @{
                    @"defaultValue": @"value1"
                },
                @"c": @{
                    @"d": @{
                        @"defaultValue": @"value2"
                    }
                }
            },
            @"e": @{
                @"defaultValue": @"value3"
            },
            @"f": @{
                @"defaultValue": @"value4"
            }
        }
    };
    
    NSDictionary *actualOutput = [self.variables unflatten:inputDict];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

- (void)testUnflattenWithEmptyInput {
    NSDictionary *inputDict = @{};
    
    NSDictionary *expectedOutput = @{};
    
    NSDictionary *actualOutput = [self.variables unflatten:inputDict];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

- (void)testUnflattenWithInvalidDictionary {
    NSDictionary *inputDict = @{
        @"a.b.c.d": @"d value",
        @"a.b.c": @"c value",
        @"a.e": @"e value",
        @"a.b": @"b value",
    };
    
    NSDictionary *expectedOutput = @{
        @"a": @{
            @"b": @"b value",
            @"e": @"e value"
        }
    };
    
    NSDictionary *actualOutput = [self.variables unflatten:inputDict];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

- (void)testUnflattenWithInvalidDictionaryDifferentOrder {
    NSDictionary *inputDict = @{
        @"a.b.c": @"c value",
        @"a.b.c.d": @"d value",
        @"a.e": @"e value",
        @"a.b": @"b value",
    };
    
    NSDictionary *expectedOutput = @{
        @"a": @{
            @"b": @"b value",
            @"e": @"e value"
        }
    };
    
    NSDictionary *actualOutput = [self.variables unflatten:inputDict];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

- (void)testUnflattenWithInvalidInputArray {
    NSDictionary *inputDict = @{
        @"a": @[ @"value2" ]
    };
    
    NSDictionary *expectedOutput = @{
        @"a": @[ @"value2" ]
    };
    
    NSDictionary *actualOutput = [self.variables unflatten:inputDict];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

#pragma mark Flatten Variables

- (void)testFlatten {
    NSDictionary *inputDict = @{
        @"Team": @{
            @"TeamName": @"Testing",
            @"Designation": @"Tester"
        },
        @"Name": @"CleverTap",
        @"EmployeeID": @123
    };
    
    NSString *varName = @"Employee";
    NSDictionary *expected = @{
        @"Employee.Team.TeamName": @{
            @"defaultValue": @"Testing"
        },
        @"Employee.Team.Designation": @{
            @"defaultValue": @"Tester"
        },
        @"Employee.Name": @{
            @"defaultValue": @"CleverTap"
        },
        @"Employee.EmployeeID": @{
            @"defaultValue": @123
        }
    };
    
    NSDictionary *result = [self.variables flatten:inputDict varName:varName];
    XCTAssertEqualObjects(result, expected);
}

- (void)testFlattenWithMultipleDictionaries {
    NSDictionary *inputDict = @{
        @"a": @{
            @"b": @"value1",
            @"c": @{
                @"d": @"value2",
                @"e": @{
                    @"f": @"value3",
                    @"g": @"value4"
                },
                @"h": @"value5"
            },
            @"i": @"value6"
        },
        @"j": @"value7",
        @"k": @{
            @"l": @"value8",
            @"m": @{
                @"n": @"value9"
            }
        }
    };
    
    NSString *varName = @"testVarName";
    NSDictionary *expected = @{
        @"testVarName.a.b": @{
            @"defaultValue": @"value1"
        },
        @"testVarName.a.c.d": @{
            @"defaultValue": @"value2"
        },
        @"testVarName.a.c.e.f": @{
            @"defaultValue": @"value3"
        },
        @"testVarName.a.c.e.g": @{
            @"defaultValue": @"value4"
        },
        @"testVarName.a.c.h": @{
            @"defaultValue": @"value5"
        },
        @"testVarName.a.i": @{
            @"defaultValue": @"value6"
        },
        @"testVarName.j": @{
            @"defaultValue": @"value7"
        },
        @"testVarName.k.l": @{
            @"defaultValue": @"value8"
        },
        @"testVarName.k.m.n": @{
            @"defaultValue": @"value9"
        },
    };
    
    NSDictionary *actual = [self.variables flatten:inputDict varName:varName];
    XCTAssertEqualObjects(actual, expected);
}

- (void)testFlattenWithEmptyInput {
    NSDictionary *inputDict = @{};
    
    NSString *varName = @"testVarName";
    NSDictionary *expectedOutput = @{};
    
    NSDictionary *actualOutput = [self.variables flatten:inputDict varName:varName];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

- (void)testFlattenWithInvalidInputArray {
    NSDictionary *inputDict = @{
        @"a": @"value1",
        @"b": @123,
        @"c": @[ @"value2" ]
    };
    
    NSString *varName = @"testVarName";
    // The array will be dropped
    NSDictionary *expectedOutput = @{
        @"testVarName.a": @{
            @"defaultValue": @"value1"
        },
        @"testVarName.b": @{
            @"defaultValue": @123
        }
    };
    
    NSDictionary *actualOutput = [self.variables flatten:inputDict varName:varName];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

@end

