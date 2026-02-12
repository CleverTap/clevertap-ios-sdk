# InApp Deep Link Click Attribution - Implementation Plan

## 📋 Executive Summary

This plan implements deep link attribution for InApp clicks by adding `wzrk_dl` (deep link) tracking to complement the existing `wzrk_c2a` (call-to-action) tracking. The implementation will capture the actual navigation destination for InApp clicks across all template types.

---

## 🎯 Objectives

1. **Capture Deep Link Destination**: Add `wzrk_dl` property to InApp click events
2. **Template Coverage**: Support all template types (CTA-based and non-CTA templates)
3. **Multi-CTA Support**: Track the specific CTA clicked when multiple CTAs exist
4. **Personalization Support**: Capture user-specific resolved deep links
5. **Backward Compatibility**: Maintain existing `wzrk_c2a` behavior

---

## 🔍 Current State Analysis

### Existing Architecture

**Event Flow:**
```
Button Tap → CTInAppDisplayViewController.handleButtonClickFromIndex:
           → CTInAppDisplayManager.handleNotificationAction:
           → CleverTap.recordInAppNotificationStateEvent:
           → CTEventBuilder.buildInAppNotificationStateEvent:
           → Event Queued with properties
```

**Current Event Properties:**
- `wzrk_id`: Campaign ID
- `wzrk_c2a`: Button text (CTA name)
- Other `wzrk_*` custom properties

**Deep Link Handling:**
- Deep links currently embedded in `wzrk_c2a` using format: `buttonText__dl__deeplink_url`
- Extracted in `CTInAppUtils.getParametersFromURL:` (lines 127-156)
- Opened via `CTInAppDisplayManager.handleCTAOpenURL:` (lines 801-818)

### Gap Analysis

| Scenario | Current Behavior | Required Behavior |
|----------|------------------|-------------------|
| CTA button with deep link | `wzrk_c2a` = button text, deep link in combined format | `wzrk_c2a` = button text, `wzrk_dl` = deep link URL |
| Non-CTA template (image-only) | `wzrk_c2a` = empty | `wzrk_c2a` = empty, `wzrk_dl` = template deep link |
| Multi-CTA templates | Tracks clicked button | Must track specific CTA's deep link |
| Personalized deep links | Not tracked separately | Must capture resolved URL |

---

## 🏗️ Implementation Plan

### Phase 1: Core Infrastructure (Constants & Models)

#### 1.1 Add wzrk_dl Constant
**File:** `CleverTapSDK/CTConstants.h`
**Location:** After line 248 (near `CLTAP_PROP_WZRK_CTA`)

```objc
#define CLTAP_PROP_WZRK_DL @"wzrk_dl"
```

**Rationale:** Follows existing naming convention for wzrk properties.

---

### Phase 2: Event Builder Enhancement

#### 2.1 Update Event Builder to Accept Deep Link Parameter
**File:** `CleverTapSDK/CTEventBuilder.m`
**Method:** `buildInAppNotificationStateEvent:forNotification:andQueryParameters:completionHandler:`
**Location:** Lines 192-222

**Changes:**
1. Update method signature to accept deep link parameter (or extract from query parameters)
2. Add logic to populate `wzrk_dl` in event properties when present
3. Ensure `wzrk_dl` is included in the final event dictionary

**Implementation Approach:**
```objc
// Extract deep link from query parameters if present
NSString *deepLink = queryParameters[CLTAP_PROP_WZRK_DL];
if (deepLink && deepLink.length > 0) {
    [eventProps setObject:deepLink forKey:CLTAP_PROP_WZRK_DL];
}
```

**Test Criteria:**
- ✅ Event includes `wzrk_dl` when deep link is present
- ✅ Event excludes `wzrk_dl` when no deep link (no empty strings)
- ✅ Existing `wzrk_c2a` behavior unchanged

---

### Phase 3: Button Click Handler Updates

#### 3.1 Update Button Click Handler to Extract and Pass Deep Link
**File:** `CleverTapSDK/InApps/CTInAppDisplayViewController.m`
**Method:** `handleButtonClickFromIndex:`
**Location:** Lines 394-434

**Current Flow:**
```objc
- Button tap detected
- Extract button text for wzrk_c2a
- Create extras dictionary
- Call delegate with notification action
```

**Enhanced Flow:**
```objc
- Button tap detected
- Extract button text for wzrk_c2a
- Extract deep link URL from button action
- Add deep link to extras dictionary as CLTAP_PROP_WZRK_DL
- Call delegate with notification action
```

**Implementation Details:**
1. Access `CTNotificationButton.action.actionURL` to get the deep link
2. Parse and validate the URL
3. Add to extras: `extras[CLTAP_PROP_WZRK_DL] = actionURL.absoluteString`
4. Handle personalized URLs (already resolved at this stage)

**Key Considerations:**
- **Multi-CTA Support**: Each button has its own action, so clicked button's deep link is automatically captured
- **URL Format**: Use `absoluteString` to capture the full URL including query parameters
- **Nil Handling**: Only add `wzrk_dl` if action URL exists and is non-nil

**Test Criteria:**
- ✅ Single CTA: Captures CTA's deep link
- ✅ Multiple CTAs: Captures clicked CTA's specific deep link
- ✅ No CTA: No `wzrk_dl` added (handled in Phase 4)

---

### Phase 4: Template-Level Deep Link Support (Non-CTA Templates)

#### 4.1 Identify Template-Level Deep Link Source
**Analysis:**
- Image-only templates (no CTAs) may have template-level navigation
- Need to check `CTInAppNotification` for template-level deep link property

**Files to Investigate:**
- `CleverTapSDK/CTInAppNotification.m/.h`
- Look for properties that store template-level action/URL

#### 4.2 Update Trigger Action Handler
**File:** `CleverTapSDK/InApps/CTInAppDisplayViewController.m`
**Method:** `triggerInAppActionForWzrkParameters:`
**Location:** Lines 436-472

**Purpose:** This method handles non-button actions (template-level clicks)

**Changes:**
1. Extract deep link from template action
2. Add to query parameters as `CLTAP_PROP_WZRK_DL`
3. Pass to event builder

**Implementation:**
```objc
// For image-only and non-CTA templates
NSString *templateDeepLink = [self getTemplateLevelDeepLink];
if (templateDeepLink && templateDeepLink.length > 0) {
    queryParameters[CLTAP_PROP_WZRK_DL] = templateDeepLink;
}
```

**Test Criteria:**
- ✅ Image-only interstitial: Captures template deep link
- ✅ Cover image: Captures template deep link
- ✅ No CTA but navigable: Captures destination URL

---

### Phase 5: Template-Specific Updates

#### 5.1 HTML Templates (Custom HTML)
**File:** `CleverTapSDK/InApps/CTInAppHTMLViewController.m`
**Scenario:** JavaScript bridge actions

**Current Flow:**
- JavaScript calls native bridge via `CleverTapJSInterface`
- Actions passed to display manager

**Update Required:**
- Ensure deep link from HTML actions is captured
- Check `CleverTapJSInterface.m` for action parsing
- Add deep link extraction if not present

#### 5.2 Image Templates
**Files:**
- `CTInterstitialImageViewController.m`
- `CTCoverImageViewController.m`
- `CTHalfInterstitialImageViewController.m`

**Scenario:** Full-image click → navigation

**Implementation:**
- Override tap gesture handler
- Extract template-level action URL
- Pass deep link to click event

#### 5.3 Custom Templates (Advanced InApp Builder)
**Files:**
- `CleverTapSDK/InApps/CustomTemplates/CTCustomTemplateInAppData.m`
- `CTTemplateContext.m`
- System app functions

**Scenario:** Custom template actions, app functions

**Changes:**
1. Check `CTAppFunctionBuilder` for URL-based actions
2. Ensure `CTOpenUrlSystemAppFunction` deep link is captured
3. Update custom template action handler to include deep link

**Implementation Points:**
- `CTCustomTemplatesManager.handleNotificationAction:` - capture deep link
- `CTTemplateContext` - pass deep link through context
- System functions - extract URL from function parameters

---

### Phase 6: Deep Link Extraction & Parsing Enhancement

#### 6.1 Review Existing Deep Link Extraction
**File:** `CleverTapSDK/CTInAppUtils.m`
**Method:** `getParametersFromURL:`
**Location:** Lines 127-156

**Current Behavior:**
- Parses `wzrk_c2a` with format: `buttonText__dl__deeplink`
- Separator: `CLTAP_WEB_PERSONALIZATION_TAG` (`__dl__`)
- Returns dictionary with `params` and `deeplink` keys

**Required Updates:**
1. Maintain backward compatibility with `__dl__` format
2. Add support for separate `wzrk_dl` parameter
3. Prioritize explicit `wzrk_dl` over embedded format

**Enhanced Logic:**
```objc
// Priority order:
// 1. Explicit wzrk_dl parameter
// 2. Deep link from __dl__ separator in wzrk_c2a
// 3. Action URL from button/template
```

#### 6.2 Add Helper Method for Deep Link Resolution
**File:** `CleverTapSDK/CTInAppUtils.m`

**New Method:**
```objc
+ (NSString *)resolveDeepLinkFromAction:(CTNotificationAction *)action
                     withQueryParameters:(NSDictionary *)params;
```

**Purpose:**
- Centralize deep link extraction logic
- Handle all deep link sources (action URL, params, embedded)
- Return resolved final URL string

---

### Phase 7: Personalization Support

#### 7.1 User-Level Personalized Deep Links
**Requirement:** Capture the resolved, user-specific deep link that's actually opened

**Analysis:**
- Personalization likely happens server-side before InApp JSON is delivered
- By the time SDK receives the InApp, personalized values are already resolved
- Need to ensure we capture the final URL, not templates

**Implementation:**
- No special handling needed in most cases (values pre-resolved)
- Ensure `absoluteString` captures full URL with all query parameters
- Document that personalization is handled by platform

**Validation:**
- ✅ Personalized deep link captured as-is
- ✅ Query parameters preserved
- ✅ User-specific tokens/IDs included in `wzrk_dl`

---

### Phase 8: Action Handler Updates

#### 8.1 Update Display Manager Action Handler
**File:** `CleverTapSDK/InApps/CTInAppDisplayManager.m`
**Method:** `handleNotificationAction:forNotification:withExtras:`
**Location:** Lines 763-798

**Current Behavior:**
- Routes action types (Close, OpenURL, KeyValues, etc.)
- Calls `handleCTAOpenURL:` for URL actions

**Enhancement:**
```objc
- (void)handleNotificationAction:(CTNotificationAction *)action
                  forNotification:(CTInAppNotification *)notification
                       withExtras:(NSMutableDictionary *)extras {
    // ... existing code ...

    // Extract and add deep link for tracking
    if (action.type == CTInAppActionTypeOpenURL && action.actionURL) {
        extras[CLTAP_PROP_WZRK_DL] = action.actionURL.absoluteString;
    }

    // For custom templates with URL destinations
    if (action.type == CTInAppActionTypeCustom) {
        NSString *customURL = [self extractURLFromCustomAction:action];
        if (customURL) {
            extras[CLTAP_PROP_WZRK_DL] = customURL;
        }
    }

    // Record event with deep link
    [self recordInAppNotificationStateEvent:YES
                            forNotification:notification
                         andQueryParameters:extras];

    // ... continue with action handling ...
}
```

---

### Phase 9: Testing & Validation

#### 9.1 Unit Tests
**Create Test File:** `CleverTapSDKTests/InApp/CTInAppDeepLinkAttributionTests.m`

**Test Cases:**
1. **CTA Button with Deep Link**
   - Given: InApp with CTA button containing deep link
   - When: User clicks button
   - Then: Event includes `wzrk_c2a` = button text, `wzrk_dl` = deep link URL

2. **Multiple CTA Buttons**
   - Given: InApp with 2+ CTA buttons, each with different deep link
   - When: User clicks second button
   - Then: `wzrk_dl` matches second button's deep link

3. **Image-Only Template**
   - Given: Image interstitial with template-level deep link, no CTA
   - When: User taps image
   - Then: `wzrk_c2a` = empty, `wzrk_dl` = template deep link

4. **No Deep Link Scenario**
   - Given: InApp with button but no deep link (pure dismiss)
   - When: User clicks button
   - Then: `wzrk_c2a` = button text, `wzrk_dl` not present

5. **HTML Template with JS Action**
   - Given: Custom HTML InApp with JavaScript-triggered navigation
   - When: User clicks element that triggers deep link
   - Then: `wzrk_dl` = resolved deep link from JS action

6. **Custom Template with App Function**
   - Given: Advanced InApp Builder with "Open URL" app function
   - When: User triggers app function
   - Then: `wzrk_dl` = URL from app function parameters

7. **Personalized Deep Link**
   - Given: Deep link with user-specific parameters: `https://app.com/offer?user=123`
   - When: User clicks
   - Then: `wzrk_dl` includes full personalized URL with parameters

8. **Backward Compatibility**
   - Given: Existing InApp with `__dl__` format in `wzrk_c2a`
   - When: User clicks
   - Then: Both `wzrk_c2a` and `wzrk_dl` populated correctly

#### 9.2 Manual Testing Checklist

**Template Matrix Validation:**

| Template | Test Case | Expected wzrk_c2a | Expected wzrk_dl | Status |
|----------|-----------|-------------------|------------------|---------|
| Basic Interstitial (CTA) | Click button | Button text | Button deep link | ⬜ |
| Basic Image-Only | Tap image | (empty) | Template deep link | ⬜ |
| Ratings | Click button | Button text | (empty) | ⬜ |
| Lead Generation | Click button | Button text | (empty) | ⬜ |
| Custom HTML | Click link | Button text | JS action URL | ⬜ |
| Advanced Builder | Click CTA | Button text | Builder action URL | ⬜ |
| Custom Code | Depends | (empty) | (empty) | ⬜ |
| App Functions | System action | (empty) | (empty) | ⬜ |
| Cover Image | Tap image | (empty) | Template deep link | ⬜ |
| Half Interstitial | Click button | Button text | Button deep link | ⬜ |
| Header Banner | Tap banner | (empty) | Banner deep link | ⬜ |
| Footer Banner | Tap banner | (empty) | Banner deep link | ⬜ |
| Alert | Click button | Button text | Button deep link | ⬜ |

---

### Phase 10: Documentation

#### 10.1 Code Documentation
**Files to Update:**
- Add inline comments explaining `wzrk_dl` population logic
- Document method parameters for deep link handling
- Add header documentation for new helper methods

#### 10.2 SDK Documentation
**Create:** `docs/InApp-Deep-Link-Attribution.md`

**Contents:**
- Feature overview
- Event property reference
- Template-specific behavior
- Migration guide (if any breaking changes)
- Code examples

---

## 📁 Files to Modify

### Core Files (High Priority)
1. ✅ **CleverTapSDK/CTConstants.h**
   - Add `CLTAP_PROP_WZRK_DL` constant

2. ✅ **CleverTapSDK/CTEventBuilder.m**
   - Update `buildInAppNotificationStateEvent:...` to include `wzrk_dl`

3. ✅ **CleverTapSDK/InApps/CTInAppDisplayViewController.m**
   - Update `handleButtonClickFromIndex:` to extract and pass deep link
   - Update `triggerInAppActionForWzrkParameters:` for template-level deep links

4. ✅ **CleverTapSDK/InApps/CTInAppDisplayManager.m**
   - Update `handleNotificationAction:...` to capture deep link from actions

5. ✅ **CleverTapSDK/CTInAppUtils.m**
   - Add helper method for deep link resolution
   - Enhance existing URL parsing if needed

### Template-Specific Files (Medium Priority)
6. **CleverTapSDK/InApps/CTInAppHTMLViewController.m**
   - Ensure HTML actions capture deep link

7. **CleverTapSDK/InApps/CTInterstitialImageViewController.m**
   - Template-level deep link for image clicks

8. **CleverTapSDK/InApps/CTCoverImageViewController.m**
   - Template-level deep link for cover image clicks

9. **CleverTapSDK/InApps/CTHalfInterstitialImageViewController.m**
   - Template-level deep link for half interstitial image clicks

10. **CleverTapSDK/InApps/CustomTemplates/CTCustomTemplatesManager.m**
    - Custom template deep link handling

### Model Files (If Needed)
11. **CleverTapSDK/CTInAppNotification.m/.h**
    - May need to expose template-level action URL property

12. **CleverTapSDK/CTNotificationAction.m/.h**
    - Verify action URL is accessible

### Test Files (New)
13. **CleverTapSDKTests/InApp/CTInAppDeepLinkAttributionTests.m** (NEW)
    - Unit tests for deep link attribution

### Documentation (New)
14. **docs/InApp-Deep-Link-Attribution.md** (NEW)
    - Feature documentation

---

## 🎬 Implementation Order

### Sprint 1: Foundation (Days 1-2)
1. Add `CLTAP_PROP_WZRK_DL` constant
2. Update `CTEventBuilder` to accept and populate `wzrk_dl`
3. Create unit test structure
4. Validate event builder changes with tests

### Sprint 2: CTA Button Support (Days 3-4)
1. Update `handleButtonClickFromIndex:` to extract button deep links
2. Update `handleNotificationAction:` to pass deep link to event builder
3. Add tests for single CTA and multi-CTA scenarios
4. Manual testing with sample InApps

### Sprint 3: Template-Level Support (Days 5-6)
1. Identify template-level deep link source in `CTInAppNotification`
2. Update `triggerInAppActionForWzrkParameters:` for non-CTA templates
3. Update image template view controllers
4. Add tests for image-only templates

### Sprint 4: Advanced Templates (Days 7-8)
1. Update HTML template deep link handling
2. Update custom template manager
3. Verify app function deep links
4. Add tests for all advanced template types

### Sprint 5: Testing & Validation (Days 9-10)
1. Complete unit test suite
2. Manual testing with template matrix
3. Fix any bugs found

### Sprint 6: Documentation & Polish (Days 11-12)
1. Add inline code documentation
2. Create feature documentation
3. Code review and refactoring

---

## 🚨 Risks & Mitigation

### Risk 1: Breaking Existing wzrk_c2a Behavior
**Mitigation:**
- Maintain backward compatibility with `__dl__` format
- Add comprehensive regression tests
- Validate existing InApps continue to work

### Risk 2: Template-Level Deep Link Source Unknown
**Mitigation:**
- Investigation phase to locate template deep link property
- Fallback to action URL if no dedicated property
- Document findings

### Risk 3: Custom Template Complexity
**Mitigation:**
- Start with standard templates first
- Custom templates as separate phase
- Leverage existing action handling infrastructure

### Risk 4: Performance Impact
**Mitigation:**
- Minimal string operations (URL extraction already exists)
- No additional network calls
- Reuse existing URL parsing logic

### Risk 5: Incomplete Test Coverage
**Mitigation:**
- Template matrix as test checklist
- Automated tests for each template type
- Manual QA with real InApp campaigns

---

## ✅ Success Criteria

### Functional Requirements
- ✅ All InApp click events with navigation include `wzrk_dl`
- ✅ CTA button clicks capture specific button's deep link
- ✅ Multi-CTA templates track clicked button's deep link
- ✅ Non-CTA templates with navigation include template deep link
- ✅ Personalized deep links captured as resolved URLs
- ✅ Existing `wzrk_c2a` behavior unchanged

### Technical Requirements
- ✅ Unit test coverage ≥ 90%
- ✅ All template types validated
- ✅ No performance regression
- ✅ Backward compatible with existing InApps
- ✅ Code review approved
- ✅ Documentation complete

### Template Coverage Matrix
- ✅ Basic templates (Content + Image, Image only) - wzrk_dl captured
- ✅ Ratings - wzrk_dl empty (no navigation)
- ✅ Lead Generation - wzrk_dl empty (no navigation)
- ✅ Custom HTML - wzrk_dl captured from JS actions
- ✅ Advanced InApp Builder - wzrk_dl captured from builder actions
- ✅ Custom Code - wzrk_dl empty (no navigation)
- ✅ App Functions - wzrk_dl empty (system actions)

---

## 📊 Validation Plan

### Pre-Release Checklist
- [ ] All unit tests passing
- [ ] Manual template matrix completed
- [ ] Regression tests passing (existing functionality)
- [ ] Code review completed
- [ ] Documentation reviewed
- [ ] Performance benchmarks acceptable
- [ ] Sample app testing completed

### Post-Release Monitoring
- Monitor event data for `wzrk_dl` population rate
- Validate deep link URLs are well-formed
- Track any customer reports of missing deep links
- Review analytics for event property completeness

---

## 🔄 Rollback Plan

If critical issues are discovered:

1. **Immediate Mitigation:**
   - Feature can be disabled by not populating `wzrk_dl` (conditional compilation)
   - Existing `wzrk_c2a` continues to work independently

2. **Rollback Strategy:**
   - Revert commits in reverse order (documentation → tests → implementation)
   - Remove `CLTAP_PROP_WZRK_DL` constant
   - Restore original event builder

3. **Zero Impact Guarantee:**
   - No changes to existing event names
   - No changes to existing `wzrk_c2a` logic
   - New property is additive only

---

## 📝 Notes & Assumptions

### Assumptions
1. Personalized deep links are resolved server-side before SDK receives InApp JSON
2. Template-level deep link is accessible via `CTInAppNotification` or action properties
3. Deep link format is standard URL (http/https) or custom scheme (app://)
4. Multi-CTA templates already track which button was clicked
5. No new event names required (add property to existing "Notification Clicked" event)

### Open Questions (To Resolve During Implementation)
1. ❓ How are template-level deep links stored in `CTInAppNotification`?
2. ❓ Do Custom Code templates ever have deep links?
3. ❓ Do App Functions need deep link attribution (or just action tracking)?
4. ❓ Should we track deep link for HTML templates that use window.location?
5. ❓ How do we handle malformed URLs or invalid deep links?

### Future Enhancements (Out of Scope for Now)
- Deep link click attribution for other channels (Push, etc.)
- Deep link analytics/reporting in SDK
- Deep link validation/verification
- Deep link failure tracking

---

## 🎯 Definition of Done

This feature is **DONE** when:

1. ✅ Code implementation complete for all template types
2. ✅ Unit tests written and passing (≥90% coverage)
3. ✅ Manual testing completed for all templates
4. ✅ Code reviewed and approved
5. ✅ Documentation written and reviewed
6. ✅ No regressions in existing functionality
7. ✅ Sample app testing completed
8. ✅ Feature merged to develop branch
9. ✅ QA sign-off received

---

**Plan Version:** 1.0
**Created:** 2026-02-12
**Branch:** `claude/inapp-deep-link-attribution-lk90P`
**Estimated Effort:** 10-12 days
**Complexity:** Medium-High
