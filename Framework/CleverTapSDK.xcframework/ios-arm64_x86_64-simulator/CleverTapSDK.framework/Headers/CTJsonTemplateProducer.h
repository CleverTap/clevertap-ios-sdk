//
//  CTJsonTemplateProducer.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 13.09.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTTemplatePresenter.h"
#import "CTTemplateProducer.h"
#import "CTCustomTemplate.h"
#import "CleverTapInstanceConfig.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 A ``CTTemplateProducer`` that creates templates based on a json definition.
 */
@interface CTJsonTemplateProducer : NSObject <CTTemplateProducer>

- (instancetype)init NS_UNAVAILABLE;

/*!
 Creates a template producer with a json definition, template presenter and function presenter.
 
 See ``CTTemplatePresenter`` for more information on the template/function presenter.
 
 Invalid definitions throw `NSException` with name `CleverTapCustomTemplateException` when ``defineTemplates:`` is called.
 
 @param jsonTemplatesDefinition A string with a json definition of templates in the following format:
 ```
 {
   "TemplateName": {
     "type": "template",
     "arguments": {
       "Argument1": {
         "type": "string|number|boolean|file|action|object",
         "value": "val" // different type depending on "type", e.g 12.5, true, "str" or {}
         },
       "Argument2": {
         "type": "object",
         "value": {
           "Nested1": {
             "type": "string|number|boolean|object", // file and action cannot be nested
             "value": {}
           },
           "Nested2": {
             "type": "string|number|boolean|object",
             "value": "val"
           }
         }
       }
     }
   },
   "functionName": {
     "type": "function",
     "isVisual": true|false,
     "arguments": {
       "a": {
       "type": "string|number|boolean|file|object", // action arguments are not supported for functions
       "value": "val"
       }
     }
   }
 }
 ```
 
 @param templatePresenter A presenter for all templates in the json definitions. Required if there
        is at least one template with type "template".
 
 @param functionPresenter A presenter for all functions in the json definitions. Required if there
        is at least one template with type "function".
 */
- (nonnull instancetype)initWithJson:(nonnull NSString *)jsonTemplatesDefinition
                                      templatePresenter:(nonnull id<CTTemplatePresenter>)templatePresenter
                                      functionPresenter:(nonnull id<CTTemplatePresenter>)functionPresenter;


/*!
 Creates ``CTCustomTemplate``s based on the `jsonTemplatesDefinition` this ``CTJsonTemplateProducer`` was initialized with.
 
 @param instanceConfig The config of the CleverTap instance.
 @return A set of the custom templates created.
 
 This method throws an `NSException` with name `CleverTapCustomTemplateException` if an invalid JSON format or values occur while parsing `jsonTemplatesDefinition`.
 See the exception reason for details.
 */
- (NSSet<CTCustomTemplate *> * _Nonnull)defineTemplates:(CleverTapInstanceConfig * _Nonnull)instanceConfig;

@end

NS_ASSUME_NONNULL_END
