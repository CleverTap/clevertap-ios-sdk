# Custom Code Templates

iOS SDK 7.0.0 and above offers support for a custom presentation of in-app messages. This allows for utilizing the in-app notifications functionality with custom configuration and presentation logic. There are two types of Custom Code Templates that can be defined through the SDK: Templates and App Functions. Templates can contain action arguments while App Functions cannot. App Functions can be used as actions while Templates cannot. App Functions can be either 'visual' or not. 'Visual' functions can contain UI logic and will be part of the [In-App queue](#in-App-queue), while non-visual App Functions will be triggered directly when invoked and should not contain UI logic.

## Creating templates and functions
All templates consist of a name, arguments and a presenter. They are all specified when creating a template through the builder. Name and presenter are required and names must be unique across the application. The template builders validate the correctness of the template definitions and will throw a `NSException` exception when an invalid template is being created. Template definitions must be valid in order to be triggered correctly.

### Arguments
Arguments are key-value pairs that represent the configuration of the custom code templates. The supported argument types are:
- `BOOL`, `NSString`, `NSNumber`. They must have a default value which would be used if no other value is configured for the notification.
- Dictionary - A `Dictionary` of supported primitives with keys being the argument names.
- File - a file argument that will be downloaded when the template is triggered
- Action - an action argument that could be a function template or a built-in action like ‘close’ or ‘open url’

#### Hierarchical arguments
You can group arguments together by either using a dictionary argument or indicating the group in the argument's name by using a '.' symbol. Both definitions are treated the same. File and Action type arguments can only be added to a group by specifying it in the name of the argument.

The following code snippets define identical arguments:
```swift
builder.addArgument("map", dictionary: [
   "a": 5,
   "b": 6
])
```
and
```swift
builder.addArgument("map.a", number: 5)
builder.addArgument("map.b", number: 6)
```

### Example
#### Objective-C
```objc
CTInAppTemplateBuilder *builder = [CTInAppTemplateBuilder new];
[builder setName:@"template"];
[builder setPresenter:presenter];
[builder addArgument:@"string" withString:@"Default Text"];
[builder addFileArgument:@"file"];
[builder addArgument:@"int" withNumber:@0];
CTCustomTemplate *template = [builder build];
```

#### Swift
```swift
let templateBuilder = CTInAppTemplateBuilder()
templateBuilder.setName("template")
templateBuilder.setPresenter(presenter)
templateBuilder.addArgument("string", string: "Default Text")
templateBuilder.addFileArgument("file")
templateBuilder.addArgument("int", number: 0)
let template = templateBuilder.build()
```

## Registering custom templates
Templates must be registered before the CleverTap instance that would use them is created. A common place for this initialization is in `UIApplicationDelegate application:didFinishLaunchingWithOptions:`. If your application uses multiple `CleverTap` instances, use the `CleverTapInstanceConfig` to differentiate which templates should be registered to which `CleverTap` instance(s).

Custom templates are registered through `CTCustomTemplatesManager.registerTemplateProducer` which accepts a `CTTemplateProducer` that contains the definitions of the templates.

### Objective-C
```objc
#import <CleverTapSDK/CTInAppTemplateBuilder.h>
#import <CleverTapSDK/CTTemplateProducer.h>
#import <CleverTapSDK/CTAppFunctionBuilder.h>


@interface TemplateProducer: NSObject<CTTemplateProducer>


@end


@implementation TemplateProducer


- (NSSet<CTCustomTemplate *> * _Nonnull)defineTemplates:(CleverTapInstanceConfig * _Nonnull)instanceConfig {
    CTInAppTemplateBuilder *builder = [CTInAppTemplateBuilder new];
    [builder setName:@"template"];
    [builder setPresenter:presenter];
    [builder addArgument:@"string" withString:@"Default Text"];
    [builder addFileArgument:@"file"];
    [builder addArgument:@"int" withNumber:@0];
    CTCustomTemplate *template = [builder build];
    
    CTAppFunctionBuilder *functionBuilder = [[CTAppFunctionBuilder alloc] initWithIsVisual:YES];
    [functionBuilder setName:@"function"];
    [functionBuilder setPresenter:functionPresenter];
    [functionBuilder addArgument:@"int" withNumber:@0];
    CTCustomTemplate *function = [functionBuilder build];
    
    return [[NSSet alloc] initWithObjects:template, function, nil];
}


@end
```

### Swift
```swift
class TemplateProducer: CTTemplateProducer {


    public func defineTemplates(_ instanceConfig: CleverTapInstanceConfig) -> Set<CTCustomTemplate> {
        let templateBuilder = CTInAppTemplateBuilder()
        templateBuilder.setName("template")
        templateBuilder.setPresenter(presenter)
        templateBuilder.addArgument("string", string: "Default Text")
        templateBuilder.addFileArgument("file")
        templateBuilder.addArgument("int", number: 0)
        let template = templateBuilder.build()
        
        let functionBuilder = CTAppFunctionBuilder(isVisual: true)
        functionBuilder.setName("function")
        functionBuilder.setPresenter(functionPresenter)
        functionBuilder.addArgument("int", number: 0)
        let function = functionBuilder.build()


        return [template, function]
    }
}
```

## Synching in-app templates to the dashboard

In order for the templates to be usable in campaigns they must be synched with the dashboard. When all templates and functions are defined and registered in the SDK, they can be synched by:
```swift
 cleverTapInstance.syncCustomTemplates()
```
The synching can only be done in debug builds and with a SDK user that is marked as 'test user'. We recommend only running this function while developing the templates and delete the invocation in release builds.

## Presenting templates

When a custom template is triggered, its presenter will be invoked. Presenters must implement `CTTemplatePresenter`. Implement the `onPresent()` method in which to use the template invocation to present their custom UI logic. `CTTemplatePresenter` should also implement `onClose` which will be invoked when a template should be closed (which could occur when an action of type 'close' is triggered). Use this method to remove the UI associated with the template and call `context.dismissed`.

All presenter methods provide a `CTTemplateContext` context. It can be used to:
- Obtain argument values by using the appropriate methods (`stringNamed:`, `numberNamed:` etc.).
- Trigger actions by their name through `triggerActionNamed:`.
- Set the state of the template invocation. `presented` and `dismissed` notify the SDK of the state of the current template invocation. The presented state is when an in-app is displayed to the user and the dismissed state is when the in-app is no longer being displayed.

#### Template presenter
```swift
class Presenter: CTTemplatePresenter {
    func onPresent(context: CTTemplateContext) {
        // keep the context as long as the template UI is being displayed
        // so that context.setDismissed() can be called when the UI is closed.
        // showUI()
        context.presented()
    }
    
    func onCloseClicked(context: CTTemplateContext) {
        // close the corresponding UI
        context.dismissed()
    }
}
```

Only one visual template or other InApp message can be displayed at a time by the SDK and no new messages can be shown until the current one is dismissed.

### In-App queue
When an in-app needs to be shown it is added to a queue (depending on its priority) and is displayed when all messages before it have been dismissed. The queue is persisted to the storage and kept across app launches to ensure all messages are displayed when possible. The custom code in-apps behave in the same way. They will be triggered once their corresponding notification is the next in the queue to be shown. However since the control of the dismissal is left to the application's code, the next in-app message will not be shown until the current code template has called `context.dismissed()`

### File downloading and caching
File arguments are automatically downloaded and are ready for use when an in-app template is presented. The files are downloaded when a file argument has changed and this file is not already cached. For client-side in-apps this happens both at App Launch and retried if needed when an in-app should be presented. For server-side in-apps the file downloading happens only before presenting the in-app. If any of the file arguments of an in-app fails to be downloaded, the whole in-app is skipped and the custom template will not be triggered.
