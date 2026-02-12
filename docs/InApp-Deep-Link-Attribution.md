# InApp Deep Link Attribution

## Overview

InApp Deep Link Attribution adds the `wzrk_dl` (deep link) property to InApp click events, enabling comprehensive tracking of user navigation destinations. This complements the existing `wzrk_c2a` (call-to-action) property to provide complete click attribution.

## Feature Summary

**Event Property Added:**
- `wzrk_dl`: Deep link / destination URL for InApp clicks

**Template Support:**
- ✅ Basic templates with CTA buttons
- ✅ Image-only templates (no CTA buttons)
- ✅ Multi-CTA templates (tracks specific clicked button)
- ✅ HTML templates (Custom HTML)
- ✅ Advanced InApp Builder templates
- ✅ Custom templates with URL actions
- ✅ Personalized deep links (user-specific URLs)

## Event Properties

### wzrk_dl (Deep Link)

Captures the destination URL or deep link for InApp clicks that lead to navigation.

**Type:** `String`
**When Present:** Only when the InApp click leads to a URL navigation
**Format:** Full URL with scheme, path, and query parameters

**Examples:**
```
wzrk_dl: "https://myapp.com/products/sale"
wzrk_dl: "myapp://product/123"
wzrk_dl: "https://shop.example.com/offer?user_id=abc123&promo=SPRING2026"
```

### wzrk_c2a (Call-to-Action)

Existing property capturing the CTA button text.

**Type:** `String`
**Behavior:** Unchanged - continues to work as before

## Template Behavior Matrix

| Template Type | wzrk_c2a | wzrk_dl | Notes |
|---------------|----------|---------|-------|
| **Basic Templates - Content with Image** | Button text | Deep link URL | CTA button click |
| **Basic Templates - Image Only** | (empty) | Deep link URL | Image tap navigation |
| **Ratings** | Button text | (empty) | No navigation |
| **Lead Generation** | Button text | (empty) | Form submission, no navigation |
| **Custom HTML** | Button text | Deep link URL | JavaScript action |
| **Advanced InApp Builder** | Button text | Deep link URL | Builder CTA action |
| **Custom Code** | (empty) | (empty) | No attribution |
| **App Functions** | (empty) | (empty) | System actions |

## Implementation Details

### CTA Button Clicks

When a user clicks a CTA button with a deep link:

```objc
// Event properties sent:
{
    "wzrk_id": "campaign_123",
    "wzrk_c2a": "Shop Now",
    "wzrk_dl": "https://shop.example.com/sale"
}
```

### Multi-CTA Scenarios

Each button's deep link is tracked individually:

```objc
// User clicks "Option A" button:
{
    "wzrk_c2a": "Option A",
    "wzrk_dl": "https://example.com/page-a"
}

// User clicks "Option B" button:
{
    "wzrk_c2a": "Option B",
    "wzrk_dl": "https://example.com/page-b"
}
```

### Image-Only Templates

For templates without CTA buttons where the image itself is tappable:

```objc
// Event properties sent:
{
    "wzrk_id": "campaign_456",
    "wzrk_c2a": "",  // Empty for non-CTA templates
    "wzrk_dl": "https://example.com/promotion"
}
```

### Personalized Deep Links

User-specific parameters are preserved in wzrk_dl:

```objc
// Deep link with personalization:
{
    "wzrk_dl": "https://app.com/offer?user_id=abc123&name=John&promo=VIP2026"
}

// All query parameters are captured in the deep link
```

### HTML Templates

JavaScript-triggered navigation in Custom HTML templates:

```objc
// When HTML InApp navigates via JavaScript:
{
    "wzrk_c2a": "Learn More",  // From URL parameters or button
    "wzrk_dl": "https://learn.example.com/courses"
}
```

## Code Examples

### Reading wzrk_dl from Events

When processing InApp click events in your analytics:

```objc
// Event data structure
NSDictionary *eventData = @{
    @"wzrk_id": @"campaign_123",
    @"wzrk_c2a": @"Shop Now",
    @"wzrk_dl": @"https://shop.example.com/sale"
};

// Extract deep link
NSString *deepLink = eventData[@"wzrk_dl"];
if (deepLink) {
    NSLog(@"User clicked and navigated to: %@", deepLink);
}
```

### Creating InApps with Deep Links

Deep links are configured in the CleverTap Dashboard when creating InApp campaigns. The SDK automatically extracts and reports them.

**Button Configuration:**
- Button Text: "Shop Now" → becomes `wzrk_c2a`
- Button Action URL: "https://shop.example.com/sale" → becomes `wzrk_dl`

**Template-Level Configuration (Image-Only):**
- Image Action URL: "https://example.com/promo" → becomes `wzrk_dl`
- wzrk_c2a will be empty (no button text)

## Backward Compatibility

This feature is **fully backward compatible**:

- ✅ Existing InApps continue to work without changes
- ✅ `wzrk_c2a` behavior is unchanged
- ✅ No breaking changes to event structure
- ✅ `wzrk_dl` is only added when deep link exists
- ✅ Compatible with legacy `__dl__` separator format

### Legacy Format Support

The SDK maintains compatibility with the older `buttonText__dl__deeplink` format:

```objc
// Legacy format (still supported)
wzrk_c2a: "Shop Now__dl__https://example.com"

// New format (recommended)
wzrk_c2a: "Shop Now"
wzrk_dl: "https://example.com"
```

## When wzrk_dl is NOT Included

The `wzrk_dl` property is **not included** in these scenarios:

1. **Close/Dismiss Actions:** Pure dismiss with no navigation
   ```objc
   // Click event for "Close" button
   {
       "wzrk_c2a": "Close",
       // wzrk_dl not present
   }
   ```

2. **Form Submissions:** Lead generation forms that don't navigate
   ```objc
   // Click event for "Submit" button
   {
       "wzrk_c2a": "Submit",
       // wzrk_dl not present
   }
   ```

3. **System Actions:** Permission requests, app ratings, etc.
   ```objc
   // App Functions (system actions)
   {
       // Both wzrk_c2a and wzrk_dl empty
   }
   ```

4. **Key-Value Actions:** Custom extras without URL navigation
   ```objc
   // Custom action with key-values
   {
       "wzrk_c2a": "Custom Action",
       // wzrk_dl not present (no URL)
   }
   ```

## Testing Deep Link Attribution

### Unit Tests

The SDK includes comprehensive unit tests in `CTInAppDeepLinkAttributionTests.m`:

- Event builder with/without wzrk_dl
- CTA button deep links
- Multi-CTA scenarios
- Image-only template deep links
- Personalized deep links
- Backward compatibility

### Manual Testing

To verify deep link attribution in your integration:

1. **Create Test Campaign:**
   - Create an InApp with CTA button
   - Set button action to a deep link URL
   - Send to test device

2. **Monitor Events:**
   - Listen for "Notification Clicked" events
   - Verify `wzrk_dl` is present in event properties
   - Confirm deep link URL matches button configuration

3. **Test Multi-CTA:**
   - Create InApp with 2+ buttons, each with different deep links
   - Click each button separately
   - Verify `wzrk_dl` matches the specific clicked button's URL

4. **Test Image-Only:**
   - Create image-only interstitial with template-level URL
   - Tap image
   - Verify `wzrk_c2a` is empty and `wzrk_dl` is present

## Troubleshooting

### wzrk_dl Not Appearing

**Issue:** Click events don't include `wzrk_dl`

**Solutions:**
- ✅ Verify button/template has a deep link URL configured
- ✅ Check that action type is "Open URL" (not "Close" or "Custom")
- ✅ Ensure SDK version includes this feature
- ✅ Confirm deep link URL is valid (non-empty, proper format)

### Wrong Deep Link Captured

**Issue:** `wzrk_dl` shows incorrect URL

**Solutions:**
- ✅ For multi-CTA: Verify each button has correct action URL
- ✅ Check for URL parameter overrides in JavaScript (HTML templates)
- ✅ Validate deep link in campaign configuration

### Missing Personalization

**Issue:** User-specific parameters not in `wzrk_dl`

**Solutions:**
- ✅ Verify personalization is configured in campaign
- ✅ Check that placeholders are resolved before SDK receives InApp
- ✅ Personalization is server-side - SDK captures final resolved URL

## Implementation Files

### Modified Files

- `CleverTapSDK/CTConstants.h` - Added CLTAP_PROP_WZRK_DL constant
- `CleverTapSDK/CTEventBuilder.m` - Document wzrk_dl support
- `CleverTapSDK/CTInAppDisplayViewController.m` - Extract deep links from buttons and actions
- `CleverTapSDK/InApps/CTInAppDisplayManager.m` - Ensure wzrk_dl in action handlers

### Test Files

- `CleverTapSDKTests/InApps/CTInAppDeepLinkAttributionTests.m` - Comprehensive unit tests

## Version Information

**Feature Added:** v[Version TBD]
**Minimum iOS:** iOS 10.0 (same as SDK minimum)
**Compatibility:** Backward compatible with all previous versions

## Support

For questions or issues related to InApp Deep Link Attribution:

1. Check this documentation first
2. Review unit tests for code examples
3. Contact CleverTap support with:
   - SDK version
   - Template type
   - Expected vs actual wzrk_dl value
   - Event payload sample

## Related Documentation

- [InApp Notifications](https://developer.clevertap.com/docs/ios-inapp)
- [Event Properties](https://developer.clevertap.com/docs/ios-events)
- [Deep Linking](https://developer.clevertap.com/docs/ios-deep-linking)

---

**Last Updated:** 2026-02-12
**Feature:** InApp Deep Link Attribution
**Property:** `wzrk_dl`
