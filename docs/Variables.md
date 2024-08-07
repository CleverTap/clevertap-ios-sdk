# Overview
You can define variables using the CleverTap iOS SDK. When you define a variable in your code, you can sync them to the CleverTap Dashboard via the provided SDK methods.

# Supported Variable Types

Currently, CleverTap SDK supports the following variable types:

- String
- BOOL
- Dictionary
- int
- float 
- double
- short
- long
- Number
- File (supported from **v7.0.0**)

# Define Variables

Variables can be defined using a shared or custom CleverTap instance. The Variable is defined using the `defineVar` method, which returns an instance of a `CTVar` variable. You must provide the name and default value of the variable. 

```swift
// Swift

// Primitive types
let var_string = CleverTap.sharedInstance()?.defineVar(name: "var_string", string: "hello, world")
let var_int = CleverTap.sharedInstance()?.defineVar(name: "var_int", integer: 10)
let var_bool = CleverTap.sharedInstance()?.defineVar(name: "var_bool", boolean: true)
let var_float = CleverTap.sharedInstance()?.defineVar(name: "var_float", float: 6.0)
let var_double = CleverTap.sharedInstance()?.defineVar(name: "var_double", double: 60.999)
let var_short = CleverTap.sharedInstance()?.defineVar(name: "var_short", short: 1)
let var_number = CleverTap.sharedInstance()?.defineVar(name: "var_number", number: NSNumber(value: 32))
let var_long = CleverTap.sharedInstance()?.defineVar(name: "var_long", long: 64)
// Dictionary
let var_dict = CleverTap.sharedInstance()?.defineVar(name: "var_dict", dictionary: [
        "nested_string": "hello, nested",
        "nested_double": 10.5
    ])

let var_dict_nested = CleverTap.sharedInstance()?.defineVar(name: "var_dict_complex", dictionary: [
        "nested_int": 1,
        "nested_string": "hello, world",
        "nested_map": [
            "nested_map_int": 15,
            "nested_map_string": "hello, nested map",
        ]
    ])



```
```objectivec
// Objective-C

#import <CleverTapSDK/CleverTap+CTVar.h>

// Primitive types
    CTVar *var_string = [[CleverTap sharedInstance] defineVar:@"var_string" withString:@"hello, world"];
    CTVar *var_int = [[CleverTap sharedInstance] defineVar:@"var_int" withInt:10];
    CTVar *var_bool = [[CleverTap sharedInstance] defineVar:@"var_bool" withBool:YES];
    CTVar *var_float = [[CleverTap sharedInstance] defineVar:@"var_float" withFloat:6.0];
    CTVar *var_double = [[CleverTap sharedInstance] defineVar:@"var_double" withDouble:60.999];
    CTVar *var_short = [[CleverTap sharedInstance] defineVar:@"var_short" withShort:1];
    CTVar *var_number = [[CleverTap sharedInstance] defineVar:@"var_number" withNumber:[[NSNumber alloc] initWithInt:32]];
    CTVar *var_long = [[CleverTap sharedInstance] defineVar:@"var_long" withLong:64];
    // Dictionary
    CTVar *var_dict = [[CleverTap sharedInstance] defineVar:@"var_dict" withDictionary:@{
        @"nested_string": @"hello, nested",
        @"nested_double": @10.5
    }];
  CTVar *var_dict_nested = [[CleverTap sharedInstance] defineVar:@"var_dict_complex" withDictionary:@{
            @"nested_int": @1,
            @"nested_string": @"hello, world",
            @"nested_map": @{
                @"nested_map_int": @15,
                @"nested_map_string": @"hello, nested map",
            }
    }];

```

# Define File Variables

CleverTap supports file types for variables from `v7.0.0+`. Supported file types include but are not limited to images (jpg, jpeg, png, gif), text files, and PDFs. The File Variable is defined using the `defineFileVar` method, which returns an instance of a `CTVar` variable. The file variable does not have a default value.

```objectivec
#import <CleverTapSDK/CleverTap+CTVar.h>

CTVar *var_file = [[CleverTap sharedInstance] defineFileVar:@"fileVariable"];
```
```swift Swift
let var_file = CleverTap.sharedInstance()?.defineFileVar(name: "fileVariable")
```

# Setup Callbacks

CleverTap iOS SDK provides several callbacks for the developer to receive feedback from the SDK. You can use them as per your requirement, using all of them is not mandatory. They are as follows:

- Status of fetch variables request
- `onVariablesChanged`
- `onceVariablesChanged`
- `onValueChanged`
- Variables Delegate
- File variables Callback
- File variables individual Callback
- File variables Delegates

## Status of Variables Fetch Request

This method provides a boolean flag to ensure that the variables are successfully fetched from the server.

```swift
// Swift

CleverTap.sharedInstance()?.fetchVariables({ success in
    print(success)
})
```
```objectivec
// Objective-C

#import <CleverTapSDK/CleverTap+CTVar.h>

[[CleverTap sharedInstance] fetchVariables:^(BOOL success) {
        
    }];
```

## `onVariablesChanged`

This callback is invoked when variables are initialized with values fetched from the server. It is called each time new values are fetched.

```swift
// Swift

let var_string = CleverTap.sharedInstance()?.defineVar(name: "myString", string: "hello,world")
CleverTap.sharedInstance()?.onVariablesChanged {
    print("CleverTap.onVariablesChanged: \(var_string?.value ?? "")")
}


```
```objectivec
// Objective-C

#import <CleverTapSDK/CleverTap+CTVar.h>

CTVar *var_string = [[CleverTap sharedInstance] defineVar:@"var_string" withString:@"hello, world"];
    [[CleverTap sharedInstance] onVariablesChanged:^{
        NSLog(@"CleverTap.onVariablesChanged: %@", [var_string value]);
    }];
```

## `onceVariablesChanged`

This callback is invoked when variables are initialized with values fetched from the server. It is called only once.

```swift
// Swift

let var_string = CleverTap.sharedInstance()?.defineVar(name: "myString", string: "hello,world")
CleverTap.sharedInstance()?.onceVariablesChanged {
    print("CleverTap.onceVariablesChanged: \(var_string?.value ?? "")")
}

```
```objectivec
// Objective-C

#import <CleverTapSDK/CleverTap+CTVar.h>

CTVar *var_string = [[CleverTap sharedInstance] defineVar:@"var_string" withString:@"hello, world"];


    [[CleverTap sharedInstance] onceVariablesChanged:^{
        // Executed only once
        NSLog(@"CleverTap.onceVariablesChanged: %@", [var_string value]);
    }];

```

## `onValueChanged`

This callback is invoked when the value of the variable changes.

```swift
// Swift

let var_string = CleverTap.sharedInstance()?.defineVar(name: "myString", string: "hello,world")
var_string?.onValueChanged {
    print("var_string.onValueChanged: \(var_string?.value ?? "")")
}

```
```objectivec
// Objective-C

#import <CleverTapSDK/CleverTap+CTVar.h>

CTVar *var_string = [[CleverTap sharedInstance] defineVar:@"var_string" withString:@"hello, world"];
    [var_string onValueChanged:^{
        NSLog(@"var_string.onValueChanged: %@", [var_string value]);
    }];
```

## Variables Delegate

The `VarDelegate` method is implemented to be invoked when the variable value is changed.

```swift
// Swift

@objc class VarDelegateImpl: NSObject, VarDelegate {
    func valueDidChange(_ variable: CleverTapSDK.Var) {
        print("CleverTap \(String(describing: variable.name)):valueDidChange to: \(variable.value!)")
    }
}

var_string?.setDelegate(self)
```
```objectivec
// Objective-C

#import <CleverTapSDK/CleverTap+CTVar.h>

@interface CTVarDelegateImpl : NSObject <CTVarDelegate>
@end


@implementation CTVarDelegateImpl
- (void)valueDidChange:(CTVar *)variable {
// valueDidChange
}
@end

CTVarDelegateImpl *del = [[CTVarDelegateImpl alloc] init];
[var_string setDelegate:del];
```

## File Variables Callbacks

### `onVariablesChangedAndNoDownloadsPending`

This callback will be called when no files need to be downloaded or all downloads have been completed. It is called each time new values are fetched and downloads are completed.

```objectivec
[[CleverTap sharedInstance] onVariablesChangedAndNoDownloadsPending:^{
  // Executed each time
}];
```
```swift
CleverTap.sharedInstance()?.onVariablesChangedAndNoDownloadsPending {
   // Executed each time        
}
```

### `onceVariablesChangedAndNoDownloadsPending`

This callback will also be called when no files need to be downloaded or all downloads have been completed, but It is called only once.

```objectivec
[[CleverTap sharedInstance] onceVariablesChangedAndNoDownloadsPending:^{
  // Executed only once
}];
```
```swift
CleverTap.sharedInstance()?.onceVariablesChangedAndNoDownloadsPending {
    // Executed only once            
}
```

## File variables individual Callback

### `onFileIsReady`

This callback will be called when the value of the file variable is downloaded and ready. This is only available for File variables.

```objectivec
#import <CleverTapSDK/CleverTap+CTVar.h>

CTVar *var_file = [[CleverTap sharedInstance] defineFileVar:@"fileVariable"];
[var_file onFileIsReady:^{
      // Called when file is downloaded.
}];
```
```swift
let var_file = CleverTap.sharedInstance()?.defineFileVar(name: "fileVariable")

var_file?.onFileIsReady {
  // Called when file is downloaded.          
}
```

## File Variables Delegates

The `fileIsReady` method is called when file is downloaded. This method is only for file type variables and variable's value will return the file downloaded path.

```objectivec
#import <CleverTapSDK/CleverTap+CTVar.h>

@interface CTVarDelegateImpl : NSObject <CTVarDelegate>
@end


@implementation CTVarDelegateImpl
- (void)valueDidChange:(CTVar *)variable {
// valueDidChange
}

- (void)fileIsReady:(CTVar *)var {
    NSLog(@"CleverTap file var:%@ is downloaded at path: %@", var.name ,var.value);
}
@end

CTVarDelegateImpl *del = [[CTVarDelegateImpl alloc] init];
[var_file setDelegate:del];
```
```swift
@objc class VarDelegateImpl: NSObject, VarDelegate {
    func valueDidChange(_ variable: CleverTapSDK.Var) {
        print("CleverTap \(String(describing: variable.name)):valueDidChange to: \(variable.value!)")
    }
    
    func fileIsReady(_ variable: CleverTapSDK.Var) {
        print("CleverTap file downloaded to path: \(variable.value ?? "nil")")
    }
}

var_file?.setDelegate(self)
```

# Sync Defined Variables

After defining your variables in the code, you must send/sync variables to the server. To do so, the app must be in DEBUG mode and mark a particular CleverTap user profile as a test profile from the CleverTap dashboard. [Learn how to mark a profile as **Test Profile**](https://developer.clevertap.com/docs/concepts-user-profiles#mark-a-user-profile-as-a-test-profile)

After marking the profile as a test profile,  you must sync the app variables in DEBUG mode:

```swift
// Swift

// 1. Define CleverTap variables 
// …
// 2. Add variables/values changed callbacks
// …

// 3. Sync CleverTap Variables from DEBUG mode/builds
CleverTap.sharedInstance()?.syncVariables();
```
```objectivec
// Objective-C

// 1. Define CleverTap variables 
// …
// 2. Add variables/values changed callbacks
// …

// 3. Sync CleverTap Variables from DEBUG mode/builds
[[CleverTap sharedInstance] syncVariables];
```

> 📘 Key Points to Remember
> 
> - In a scenario where there is already a draft created by another user profile in the dashboard, the sync call will fail to avoid overriding important changes made by someone else. In this case, Publish or Dismiss the existing draft before you proceed with syncing variables again. However, you can override a draft you created via the sync method previously to optimize the integration experience.
> - You can receive the following console logs from the CleverTap SDK:
>   - Variables synced successfully.
>   - Unauthorized access from a non-test profile. Please mark this profile as a test profile from the CleverTap dashboard.

# Fetch Variables During a Session

You can fetch the updated values for your CleverTap variables from the server during a session. If variables have changed, the appropriate callbacks will be fired. The provided callback provides a boolean flag that indicates if the fetch call was successful. The callback is fired regardless of whether the variables have changed or not.

```swift
// Swift

CleverTap.sharedInstance()?.fetchVariables({ success in
    print(success)
})
```
```objectivec
// Objective-C

[[CleverTap sharedInstance] fetchVariables:^(BOOL success) {
        
}];
```

# Use Fetched Variables Values

This process involves the following two major steps:

1. Fetch variable values.
2. Access variable values.

## Fetch Variable Values

Variables are updated automatically when server values are received. If you want to receive feedback when a specific variable is updated, use the individual callback:

```swift
// Swift

variable?.onValueChanged {
    print("variable.onValueChanged: \(variable?.value ?? "")")
}
```
```objectivec
// Objective-C

[variable onValueChanged:^{
    NSLog(@"variable.onValueChanged: %@", [variable value]);
}];
```

## Access Variable Values

You can access these fetched values in the following three ways:

### From `Var` instance

You can use several methods on the `Var` instance as shown in the following code. For File Variables, value returns the file downloaded path.

```swift
// Swift

variable?.defaultValue // returns default value
variable?.value // returns current value
variable?.numberValue // returns value as NSNumber if applicable
variable?.stringValue // returns value as String

// File Variables
let var_file = CleverTap.sharedInstance()?.defineFileVar(name: "fileVariable")
var_file?.value // returns file downloaded path
var_file?.stringValue // returns file downloaded path
var_file?.fileValue // returns file downloaded path
```
```objectivec
// Objective-C

variable.defaultValue; // returns default value
variable.value; // returns current value
variable.numberValue; // returns value as NSNumber if applicable
variable.stringValue; // returns value as String

// File Variables
CTVar *var_file = [[CleverTap sharedInstance] defineFileVar:@"fileVariable"];
var_file.value // returns file downloaded path
var_file.stringValue // returns file downloaded path
var_file.fileValue // returns file downloaded path
```

### Using `CleverTap` Instance method

You can use the `CleverTap` instance method to get the current value of a variable. If the variable is nonexistent, the method returns `null`:

```swift
// Swift

CleverTap.sharedInstance()?.getVariableValue("variable name")
```
```objectivec
// Objective-C

[[CleverTap sharedInstance]getVariableValue:@"variable name"];
```
