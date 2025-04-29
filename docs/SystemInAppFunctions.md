# System In-App Functions
The CleverTap iOS SDK (v7.2.0 and above) supports a set of built-in system in-app functions. These can be triggered either via in-app notification button actions or launched as stand-alone campaigns. For more details, refer to the [CleverTap Documentation](https://developer.clevertap.com/docs/)

## Open URL
This function will open url or deeplink for `iOS` URL configured through the CleverTap Dashboard while selecting function as stand-alone in-app template. `Notification Viewed` event is raised for valid URL.

## Push Permission
This function starts the push permission request flow. Here is a summary of the flow and its results:
```mermaid
flowchart TD
    Start([Push Permission Request]) --> A{Permission request trigger}
    A -->|Launched as a stand-alone campaign| B{Permission already granted?}
    A -->|In-app notification containing a push permission request action| C{Permission already granted?}
    
    B -->|Yes| D([System function dismissed])
    B -->|No| E{Can show system permission prompt?}
    
    E -->|Yes| F[Show system prompt]
    F -->|Notification Viewed event is raised| G{User selection}
    G -->|Accept/Deny| H([System function dismissed])
    E -->|No| J([System function dismissed])
    
    C -->|Yes| K[The in-app notification is not displayed]
    C -->|No| L[Display in-app notification]
    
    L -->|Notification Viewed event for in-app campaign itself is raised| M[Permission request in-app action button is clicked]
    M ---|Notification Clicked event for in-app campaign itself is raised| N([In-app notification dismissed])
    N --> O{Can show system permission prompt?}
    
    O -->|Yes| P[Show system prompt]
    P --> Q{User selection}
    Q -->|Accept/Deny| R([System function dismissed])
    
    O -->|No| T([System function dismissed])
    T --> U[Navigate to system settings screen for app notifications]
```

## App Rating
This function displays the system app rating dialog. Here is a summary of the flow and its results:
```mermaid
flowchart TD
    Start([App Rating Request]) --> A{App Rating request trigger}
    A -->|Launched as a stand-alone campaign| B([App Rating system prompt displayed])
    A -->|In-app notification containing app rating request action| C[Display in-app notification]
    
    B --- |Notification Viewed event is raised| D@{ shape: framed-circle, label: "Stop" }
    C --> |Notification Viewed event for in-app campaign itself is raised| E[Rating request in-app action button is clicked]

    E --- |Notification Clicked event for in-app campaign itself is raised| F([In-app notification dismissed])
    F --> G([App Rating system prompt displayed])
```

| :bulb:  Apple limits amount of time you can prompt app review to three times in one year, also avoid showing a request for a review immediately when a user launches your app, even if it isn’t the first time it launches. Refer to the [apple documentation](https://developer.apple.com/documentation/storekit/requesting-app-store-reviews#Overview) for more details. |
|-----------------------------------------|