## Overview
Custom proxy domain allows you to proxy all events raised from the CleverTap SDK through your required domain. If you want to use your own application server, then use a proxy domain to handle and/or relay CleverTap events.

Note: In this phase, custom domain support for Push Impression event handling is not provided.

Follow these steps to create a CloudFront distribution for the proxy domain and then integrate CleverTap SDK with proxy domain configuration. 


## AWS Certificate Manager
To create a certificate using ACM in required region: 

- Go to Certificate Manager in AWS
- Click on Request Certificate and select Request a public certificate option
  <p align="center">
  <img alt="Request Certificate" src="/docs/images/CustomDomain/ACM/Request a public certificate" width="85%">
  </p>
- Add the proxy domain name you want to use
  <p align="center">
  <img alt="Add the domain name" src="/docs/images/CustomDomain/ACM/Add the domain name" width="85%">
  </p>
- Select a validation method as per your domain account permission
  <p align="center">
  <img alt="Select validation method" src="/docs/images/CustomDomain/ACM/Select validation method" width="85%">
  </p>
- After review, Confirm and request the certificate
- Copy the CNAME record from ACM details to add it in DNS Settings
  <p align="center">
  <img alt="CNAME record details" src="/docs/images/CustomDomain/ACM/CNAME record details" width="85%">
  </p>
- Add the CNAME Record in DNS Settings as shown below 
  <p align="center">
  <img alt="Add CNAME in DNS" src="/docs/images/CustomDomain/ACM/Add CNAME in DNS" width="85%">
  </p>
- In few minutes, ACM Validation status should update from <b>Pending</b> to <b>Success</b>

We will use this certificate while creating CloudFront distribution. 

## AWS CloudFront Distribution 
<ol type="a">
  <li> Origin:</li>
  <ol type="1">
    <li>Enter Origin Domain: eu1.clevertap-prod.com</li>
    <li>Select Protocol: HTTPS</li>&nbsp;
    <p align="center">
  <img src="/docs/images/CustomDomain/AWS CloudFront/a.Origin.png" width="85%">
  </p>
  </ol>
  
  <li> Default cache behaviour:</li>
   <ol type="1">
     <li>Select Redirect HTTP to HTTPS in Viewer protocol policy</li>
     <li>Select GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE in Allowed HTTP methods</li>&nbsp;
     <p align="center">
      <img src="/docs/images/CustomDomain/AWS CloudFront/b1.Cache behaviour.png" width="85%">
     </p>
     <li>Under Cache key and origin requests, select Cache policy and origin request policy (recommended) option and choose <b>CachingOptimized</b> from dropdown</li>&nbsp;
     <p align="center">
      <img src="/docs/images/CustomDomain/AWS CloudFront/b3.Cache policy.png" width="85%">
     </p>
   </ol>
  
  <li> Settings:</li>
   <ol type="1">
     <li>Add proxy name in Alternate domain name (CNAME): analytics.sdktesting.xyz</li>
     <li>Choose the earlier created certificate in Custom SSL certificate - optional</li>&nbsp;
     <p align="center">
     <img src="/docs/images/CustomDomain/AWS CloudFront/c1.Settings.png" width="85%">
     </p>
     <li>Select the recommended option under Security policy</li>&nbsp;
     <p align="center">
     <img src="/docs/images/CustomDomain/AWS CloudFront/c3.Security policy.png" width="85%">
     </p>
     </ol>
  
  <li>Keep rest of the settings as it is and click Create Distribution</li>&nbsp;
  <p align="center">
  <img src="/docs/images/CustomDomain/AWS CloudFront/d.Create distribution.png" width="85%">
  </p>
  
  <li>Add another CNAME in DNS Settings to point your subdomain(analytics in this case) to cloudfront distribution as shown</li>&nbsp;
   <p align="center">
  <img src="/docs/images/CustomDomain/AWS CloudFront/e.Subdomain in DNS Settings.png" width="85%">
  </p>
  
  <li>Once CloudFront distribution is deployed, hit proxy domain on browser to check if settings are up and running.</li>
  
</ol>


## Integrating CleverTap to use proxy domain

### Using autointegrate
- Add your CleverTap credentials in the Info.plist file of your application. Insert the account ID and account token values from your CleverTap account against keys CleverTapAccountID and CleverTapToken. Add CleverTapProxyDomain key with proxy domain value.
<p align="center">
<img src="/docs/images/CustomDomain/SDKIntegration/Infoplist.png" width="85%">
</p>

- Import CleverTapSDK in your AppDelegate file and call CleverTap's autoIntegrate in the ```didFinishLaunchingWithOptions```  method.
```swift
  CleverTap.autoIntegrate()
```
- Use CleverTap's sharedInstance to log events.
```swift
  CleverTap.sharedInstance()?.recordEvent("Product viewed")
```
&nbsp;

### Using manual integration
- Create CleverTapInstanceConfig with parameters account ID, account token and proxy domain values.
```swift
  let ctConfig = CleverTapInstanceConfig(accountId: ACCOUNT_ID, accountToken: ACCOUNT_TOKEN, proxyDomain: "analytics.sdktesting.xyz")
```
- Instantiate the CleverTap instance by calling CleverTapAPI.instanceWithConfig method with the CleverTapInstanceConfig object you created.
```swift
  let cleverTapProxyInstance = CleverTap.instance(with: ctConfig)
```
- Use the instance created using above steps to log events.
```swift
  cleverTapProxyInstance.recordEvent("Product viewed")
```
&nbsp;

### Test
After integration, you should be able to see logged events on CleverTap dashboard.

