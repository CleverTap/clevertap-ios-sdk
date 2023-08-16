## Encryption of PII data 

PII data is stored across the SDK and could be sensitive information. 
From CleverTap iOS SDK v5.2.0 onwards, you can enable encryption for PII data wiz. **Email, Identity, Name and Phone**.  
  
Currently 2 levels of encryption are supported i.e None(0) and Medium(1). Encryption level is None by default.  
**None** - All stored data is in plaintext    
**Medium** - PII data is encrypted completely. 
   
### Default Instance:
The only way to set encryption level for default instance is from the `info.plist`. Add the `CleverTapEncryptionLevel` String key to info.plist file where value `1` means Medium and `0` means None. Encryption Level will be None if any other value is provided.

### Additional Instance:
Different instances can have different encryption levels. To set an encryption level for an additional instance.
```objc
// Objective-C

CleverTapInstanceConfig *ctConfig = [[CleverTapInstanceConfig alloc] initWithAccountId:@"ADDITIONAL_CLEVERTAP_ACCOUNT_ID" accountToken:@"ADDITIONAL_CLEVERTAP_ACCOUNT_TOKEN"];
[ctConfig setEncryptionLevel:CleverTapEncryptionMedium];
CleverTap *additionalCleverTapInstance = [CleverTap instanceWithConfig:ctConfig];
```

```swift
// Swift

let ctConfig = CleverTapInstanceConfig.init(accountId: "ADDITIONAL_CLEVERTAP_ACCOUNT_ID", accountToken: "ADDITIONAL_CLEVERTAP_ACCOUNT_TOKEN")
ctConfig.encryptionLevel = CleverTapEncryptionLevel.medium
let cleverTapAdditionalInstance = CleverTap.instance(with: ctConfig)
```