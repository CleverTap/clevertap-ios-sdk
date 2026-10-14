# CleverTap Live Activities — iOS Integration Guide

Live Activities let your app show glanceable, real‑time information on the Lock Screen and in the
Dynamic Island (e.g. an order‑tracking card, a ride ETA, a live score). CleverTap drives Live
Activities **remotely** using Apple's **Push‑to‑Start (PTS)** model: your backend starts, updates,
and ends the activity via push — the user does not need to open the app.

This guide covers everything you need to integrate the feature.

> 📂 **Reference implementation:** a complete, working integration lives in the **`SwiftStarter`**
> sample app in this repo. The snippets below use the same `FoodOrderActivityAttributes` type, so
> you can cross‑reference them directly against the sample.

---

## Table of contents

1. [Requirements](#1-requirements)
2. [Step 1 — Add a Widget Extension target](#step-1--add-a-widget-extension-target)
3. [Step 2 — Enable capabilities (Push Notifications + Live Activities)](#step-2--enable-capabilities-push-notifications--live-activities)
4. [Step 3 — Define your ActivityAttributes](#step-3--define-your-activityattributes)
5. [Step 4 — Build the Widget (Live Activity UI)](#step-4--build-the-widget-live-activity-ui)
6. [Step 5 — Register Push‑to‑Start](#step-5--register-pushtostart)
7. [Step 6 — Record impressions](#step-6--record-impressions)
8. [Step 7 — Record clicks (deep links)](#step-7--record-clicks-deep-links)
9. [Lifecycle events reference](#lifecycle-events-reference)
10. [The `wzrk` attribution object](#the-wzrk-attribution-object)
11. [Multi‑instance (multiple CleverTap accounts)](#multiinstance-multiple-clevertap-accounts)
12. [onUserLogin behaviour](#onuserlogin-behaviour)
13. [Platform limitations](#platform-limitations)

---

## 1. Requirements

| Item | Minimum |
|------|---------|
| iOS (Push‑to‑Start Live Activities) | **17.2+** |
| CleverTap iOS SDK | **7.9.0+** |
| Xcode | 15+ |
| A **Widget Extension** target | required (renders the activity UI) — see [Step 1](#step-1--add-a-widget-extension-target) |
| **Push Notifications** capability | required (activities are driven over APNs) — see [Step 2](#step-2--enable-capabilities-push-notifications--live-activities) |

> Live Activities **do not run in the Simulator** — test on a physical device.

---

## Step 1 — Add a Widget Extension target

A Live Activity's UI is rendered by a **Widget Extension**, not by your app — so if your project
doesn't have one yet, create it first.

In Xcode: **File → New → Target… → Widget Extension**. Name it (e.g. `FoodOrderWidget`), and
**tick "Include Live Activity"** before finishing. That checkbox is what generates the
`ActivityConfiguration` scaffold you'll fill in later — without it you get a plain home‑screen
widget. Accept the prompt to activate the new scheme.

Xcode then creates the extension target, embeds it in your app, and adds
`NSSupportsLiveActivities` to the **app target's** `Info.plist`.

Check these on the new target before moving on:

| Setting | Value |
|---------|-------|
| **Minimum Deployment** | **iOS 16.2+** (the sample uses 16.2; Push‑to‑Start itself needs a 17.2 device) |
| **Bundle Identifier** | must be a child of your app's — e.g. app `com.example.app` → widget `com.example.app.FoodOrderWidget` (Xcode does this for you) |
| `NSExtensionPointIdentifier` | `com.apple.widgetkit-extension` in the extension's `Info.plist` |

> **Do not add the CleverTap SDK to the widget extension.** Every CleverTap call in this guide is
> made from the **app** target. The extension only needs ActivityKit, WidgetKit and SwiftUI — the
> one file the two targets share is your `ActivityAttributes` (see
> [Step 3](#step-3--define-your-activityattributes)), which is why that struct must not import
> `CleverTapSDK`.

---

## Step 2 — Enable capabilities (Push Notifications + Live Activities)

### Push Notifications capability — required

CleverTap starts, updates and ends Live Activities over **APNs**, and both token streams the SDK
listens to (`pushToStartTokenUpdates` and `pushTokenUpdates`) are APNs tokens. Without the
entitlement iOS never issues them: no token reaches CleverTap, and **no activity ever starts** —
with no error raised.

On your **app target** → *Signing & Capabilities* → **+ Capability** → **Push Notifications**.
Xcode adds the entitlement:

```xml
<!-- YourApp.entitlements -->
<key>aps-environment</key>
<string>development</string>   <!-- Xcode switches this to "production" for release builds -->
```

Also ensure the App ID used by your provisioning profile has **Push Notifications** enabled in the
Apple Developer portal.

> Add this to the **app target only** — the Widget Extension does not need it.
>
> This is *separate* from the notification permission prompt. Live Activities do not depend on the
> user accepting `UNUserNotificationCenter` authorization; they have their own switch
> (**Settings → [your app] → Live Activities**), which the SDK reports via
> `ActivityAuthorizationInfo().areActivitiesEnabled`. The capability is still mandatory either way.

### Live Activities Info.plist keys

Add these keys to your **app target's** `Info.plist` (if you checked *Include Live Activity* in
Step 1, Xcode has already added `NSSupportsLiveActivities` — verify it, and add the second key):

```xml
<key>NSSupportsLiveActivities</key>
<true/>

<!-- Opt into high‑frequency ActivityKit push updates (recommended for fast‑changing
     activities like live scores or delivery tracking). Without it, iOS may throttle updates. -->
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

> `NSSupportsLiveActivitiesFrequentUpdates` only *declares* support — users can still toggle
> "Frequent Updates" off in **Settings → [your app] → Live Activities**, and iOS may throttle
> extreme update rates regardless.

---

## Step 3 — Define your ActivityAttributes

Create a struct conforming to `ActivityAttributes`. **Share this file with both the app target and
the widget extension target** — select the file, open the File Inspector (⌥⌘1) and tick **both**
targets under *Target Membership*. Both sides must compile the *same* type, or the widget cannot
render the activity your app registered for.

Two rules make CleverTap attribution work:

- Put a **nested `wzrk` object** in the static attributes. The CleverTap backend injects it into
  `aps.attributes` at start. The SDK reads it generically via `Codable` — **no CleverTap protocol
  conformance is required**.
- Put the **changing** attribution fields (milestone id, per‑send id) in `ContentState`, because
  only the content‑state is readable on update/end.

```swift
import ActivityKit
import Foundation

@available(iOS 17.2, *)
struct FoodOrderActivityAttributes: ActivityAttributes {

    // Dynamic — changes on every update push.
    struct ContentState: Codable, Hashable {
        // --- your own UI fields ---
        var status: String
        var estimatedDelivery: Int
        var progressStep: Int

        // --- CleverTap fields — add these as-is (names/types must match exactly) ---
        var wzrk_milestoneId: String?   // changes per state → lives here, not in `wzrk`
        var wzrk_pid: String?           // per‑send push id → lives here
    }

    // Static — set once at start, immutable thereafter.
    var restaurantName: String
    var orderSummary: String
    var orderId: String

    // CleverTap field — add this as-is. The backend injects the `wzrk` object into
    // aps.attributes at start.
    var wzrk: Wzrk?

    struct Wzrk: Codable, Hashable {
        var wzrk_activityId: String?    // your activity id
        var wzrk_activityType: Int?
        var wzrk_id: String?            // campaign id
        var wzrk_acct_id: String?       // account id
        var wzrk_rnv: Bool?             // JSON key is "W$rnv" (mapped below)

        enum CodingKeys: String, CodingKey {
            case wzrk_activityId, wzrk_activityType, wzrk_id, wzrk_acct_id
            case wzrk_rnv = "W$rnv"
        }
    }
}
```

> ⚠️ **Type correctness is critical.** `ActivityAttributes` is `Codable`; if a declared field's type
> doesn't match the JSON the backend sends (e.g. you declare `wzrk_id: Int` but the backend sends
> the string, the **entire** attributes decode throws and the activity **fails
> to start**. Declare `wzrk_id` as `String`.

---

## Step 4 — Build the Widget (Live Activity UI)

In the Widget Extension you created in [Step 1](#step-1--add-a-widget-extension-target), add an
`ActivityConfiguration` for your attributes (replacing the stub Xcode generated). Set a
`widgetURL` on **both** the Lock Screen view and the Dynamic Island so a tap can be recorded as a
click (see [Step 7](#step-7--record-clicks-deep-links)).

> 📝 **Build the Live Activity UI to suit your app.** The layout, copy and styling are entirely
> yours — CleverTap does not impose or render any UI. The snippet below is a **sample for a food
> order** activity; use it as a shape to follow, not a template to copy. Only two things in this
> step are CleverTap requirements:
>
> 1. `widgetURL` set on **both** the Lock Screen and the Dynamic Island, so taps can be recorded
>    as clicks.
> 2. the deep link built with `URLComponents`, so a `wzrk_activityId` containing reserved
>    characters survives the round trip.

```swift
import WidgetKit
import SwiftUI

@available(iOS 17.2, *)
struct FoodOrderLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FoodOrderActivityAttributes.self) { context in
            // Lock Screen / banner
            FoodOrderLockScreenView(attributes: context.attributes, state: context.state)
                .widgetURL(Self.clickURL(for: context.attributes))
        } dynamicIsland: { context in
            DynamicIsland {
                // Your Dynamic Island expanded UI goes here.
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.status)
                }
            } compactLeading: {
                Image(systemName: "bag.fill")
            } compactTrailing: {
                Text("\(context.state.estimatedDelivery)m")
            } minimal: {
                Image(systemName: "bag.fill")
            }
            .widgetURL(Self.clickURL(for: context.attributes))
        }
    }

    /// Build the click deep link with URLComponents so a wzrk_activityId containing reserved
    /// characters (& # ? space) is percent‑encoded and reaches the app intact.
    static func clickURL(for attributes: FoodOrderActivityAttributes) -> URL? {
        let tag = attributes.wzrk?.wzrk_activityId ?? attributes.orderId
        var c = URLComponents()
        c.scheme = "yourapp"              // a URL scheme registered in your app's Info.plist
        c.host = "liveactivity"
        c.queryItems = [
            URLQueryItem(name: "tag", value: tag),
            URLQueryItem(name: "type", value: "FoodOrderActivityAttributes")
        ]
        return c.url
    }
}
```

> `widgetURL` must be set on **each surface separately** — setting it only on the Dynamic Island
> means Lock Screen taps are not delivered to your app.

### The Lock Screen view

`FoodOrderLockScreenView` above is your own SwiftUI view — ActivityKit hands it the static
`attributes` and the current `ContentState`, and re‑renders it on every update push. Nothing here
is CleverTap‑specific; lay it out however you like:

```swift
@available(iOS 17.2, *)
struct FoodOrderLockScreenView: View {
    let attributes: FoodOrderActivityAttributes
    let state: FoodOrderActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 1) {
                    Text(attributes.restaurantName).font(.headline)
                    Text(attributes.orderSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("ETA").font(.caption2).foregroundColor(.secondary)
                    Text("\(state.estimatedDelivery) min")
                        .font(.caption)
                        .monospacedDigit()
                        .fontWeight(.semibold)
                }
            }

            Text(state.status)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ProgressView(value: Double(state.progressStep), total: 3.0)
                .tint(.orange)
        }
    }
}
```

> Read **only** `attributes` and `state` here. A Live Activity view is rendered by the widget
> extension in a separate process — it cannot reach your app's memory, and it gets no network or
> CleverTap access.

`SwiftStarter/FoodOrderWidget/FoodOrderLiveActivityWidget.swift` has a richer version of this view
(a four‑stage progress track instead of the single `ProgressView`) plus the fully populated
`DynamicIsland` regions the snippet above abbreviates.

### Make the widget the extension's entry point

A `Widget` on its own is never loaded. The extension's `@main` must be a `WidgetBundle` listing
it — Xcode generates this file with the target, so just make sure your Live Activity widget
appears in the body:

```swift
import WidgetKit
import SwiftUI

@main
struct FoodOrderWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 17.2, *) {
            FoodOrderLiveActivityWidget()
        }
    }
}
```

> The `if #available` is required because the widget is annotated `@available(iOS 17.2, *)`;
> without it the bundle won't compile. (The sample uses `16.2` throughout — the Live Activity
> *UI* only needs 16.2, it's Push‑to‑Start that requires 17.2.)
>
> If the backend starts an activity and you see the `Started` event, but nothing renders on the
> Lock Screen, a missing or mismatched `WidgetBundle` entry is the first thing to check.

---

## Step 5 — Register Push‑to‑Start

Call `registerPushToStart` **as early as possible** in `didFinishLaunchingWithOptions` (iOS only
generates a PTS token on the first launch after a device restart). This is a Swift‑generic API.

### Swift

```swift
import CleverTapSDK
import ActivityKit

func application(_ application: UIApplication,
                didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    CleverTap.autoIntegrate()

    if #available(iOS 17.2, *) {
        CleverTap.sharedInstance()?.registerPushToStart(
            Activity<FoodOrderActivityAttributes>.self,
            name: "FoodOrderActivityAttributes"
        )
    }
    return true
}
```

### Objective‑C app delegate

`registerPushToStart` is Swift‑generic and can't be called from Objective‑C directly. Add a tiny
Swift helper and call it from your `.m`:

```swift
// LiveActivitySetup.swift
import CleverTapSDK
import ActivityKit

@objc final class LiveActivitySetup: NSObject {
    @objc static func start() {
        if #available(iOS 17.2, *) {
            CleverTap.sharedInstance()?.registerPushToStart(
                Activity<FoodOrderActivityAttributes>.self,
                name: "FoodOrderActivityAttributes"
            )
        }
    }
}
```

```objc
// AppDelegate.m  (after CleverTap autoIntegrate)
#import "YourProduct-Swift.h"
[LiveActivitySetup start];
```

---

## Step 6 — Record impressions

Impression is an **opt‑in, client‑side** event — your app decides *when* an activity counts as
"shown". ActivityKit has no literal "on screen" callback, so use the `.active` state as the proxy.
A small observer started at launch covers activities started while the app is alive **and** any
already running at launch.

You do **not** need to track which activities you've already reported: the SDK de‑duplicates
`recordLiveActivityImpression(_:)` to **one impression per activity**, persisted across launches
(the same way it reports `Started` once). So it's safe to call on every `.active` transition and on
every relaunch.

```swift
import ActivityKit
import CleverTapSDK

@available(iOS 17.2, *)
final class LiveActivityImpressionObserver {
    static let shared = LiveActivityImpressionObserver()
    private init() {}

    func start() {
        // Activities already running at launch — this is also the path that covers a push‑to‑start
        // arriving while the app was killed, since iOS background‑launches the app for it.
        for activity in Activity<FoodOrderActivityAttributes>.activities {
            recordIfShown(activity)
        }
        // Activities the backend starts while the app is alive (foreground or background).
        Task { [weak self] in
            for await activity in Activity<FoodOrderActivityAttributes>.activityUpdates {
                self?.recordIfShown(activity)
            }
        }
    }

    private func recordIfShown(_ activity: Activity<FoodOrderActivityAttributes>) {
        guard activity.activityState == .active else { return }
        // The SDK reads the wzrk from the activity itself (attributes + current content‑state) and
        // de‑dupes to one impression per activity — safe to call repeatedly.
        CleverTap.sharedInstance()?.recordLiveActivityImpression(activity)
    }
}
```

```swift
// In didFinishLaunchingWithOptions, after registerPushToStart:
if #available(iOS 17.2, *) { LiveActivityImpressionObserver.shared.start() }
```

Those two loops are all you need — between them they cover every app state, because Push‑to‑Start
makes iOS launch or wake your app when the activity starts:

| App state when the activity starts | Covered by |
|------------------------------------|------------|
| **Foreground** | `activityUpdates` |
| **Background** (suspended) | `activityUpdates` — iOS wakes the app |
| **Killed** | the `activities` loop — iOS background‑launches the app, so `start()` runs again |

> Because `start()` must run on a background launch for the killed case to work, call it in
> `didFinishLaunchingWithOptions` — not from a view controller or a foreground‑only hook.

> **Optional hardening.** If you also want to catch an activity that is *not* `.active` the moment
> you first see it (e.g. it was `.stale` at launch) and becomes `.active` later, additionally
> observe `activity.activityStateUpdates` and call `recordIfShown` on `.active`. The sample's
> `LiveActivityImpressionObserver` does this. It is not required for the three cases above, and the
> SDK's de‑duplication means the extra calls cannot produce duplicate impressions.

### APIs

```swift
/// Records a Live Activity **impression** ("shown") — the preferred variant.
///
/// Pass the live `Activity`. The SDK:
///  • extracts the full, **current** `wzrk` for you (static attributes + the content‑state at call
///    time, so the milestone/pid are current), and
///  • **de‑duplicates** to one impression per activity, persisted across launches — so you can call
///    it on every `.active` transition and on every relaunch without sending duplicates.
///
/// Use this whenever you hold the `Activity` (from `Activity<…>.activities` or `activityUpdates`).
/// This is the variant the sample's impression observer uses.
///
/// - Parameter activity: the running Live Activity.
@available(iOS 17.2, *)
func recordLiveActivityImpression<Attributes: ActivityAttributes>(_ activity: Activity<Attributes>)

/// Records a Live Activity **impression** from a `wzrk` dictionary — the escape hatch for when you
/// do **not** hold the live `Activity`.
///
/// Unlike the `Activity` variant this is **not de‑duplicated** — each call sends one event, so you
/// own when/how often it fires. Typical cases:
///  • a custom impression trigger (not `.active`) driven by your own app/backend signal,
///  • deferred / replayed reporting after the activity has ended and left `Activity.activities`,
///  • integrations that track the campaign `wzrk` outside ActivityKit.
///
/// Most ActivityKit integrations never need this — prefer `recordLiveActivityImpression(_:)`.
///
/// - Parameter wzrk: the campaign dictionary (the `wzrk` object from the activity payload).
func recordLiveActivityImpression(wzrk: [AnyHashable: Any])
```

---

## Step 7 — Record clicks (deep links)

When the user taps the activity, iOS opens the `widgetURL` you set in [Step 4](#step-4--build-the-widget-live-activity-ui).
Handle it in your URL open handler: record the click, then route to your destination.

### Swift

```swift
func application(_ app: UIApplication, open url: URL,
                 options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // Match the scheme too — host alone would also claim a universal link or another SDK's
    // deep link that happens to use "liveactivity". Use the scheme you set in Step 4.
    guard url.scheme == "yourapp", url.host == "liveactivity",
          let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
    let tag = comps.queryItems?.first(where: { $0.name == "tag" })?.value ?? ""

    if #available(iOS 17.2, *), !tag.isEmpty {
        if let activity = Activity<FoodOrderActivityAttributes>.activities
            .first(where: { $0.attributes.wzrk?.wzrk_activityId == tag }) {
            // Live lookup → SDK reads the CURRENT wzrk (milestone current at tap time).
            CleverTap.sharedInstance()?.recordLiveActivityClicked(activity)
        } else {
            // Activity gone — report with what the deep link carried.
            CleverTap.sharedInstance()?.recordLiveActivityClicked(wzrk: ["wzrk_activityId": tag])
        }
    }
    return true
}
```

### APIs

```swift
/// Records a Live Activity **click** — the preferred variant.
///
/// Pass the live `Activity`. The SDK extracts the full, **current** `wzrk` (static attributes +
/// the content‑state at tap time, so the milestone is current). Use this when your deep‑link
/// handler successfully looks up the running activity (see the handler above).
///
/// Clicks are **not** de‑duplicated — a user can legitimately tap more than once.
///
/// - Parameter activity: the running Live Activity the user tapped.
@available(iOS 17.2, *)
func recordLiveActivityClicked<Attributes: ActivityAttributes>(_ activity: Activity<Attributes>)

/// Records a Live Activity **click** from a `wzrk` dictionary — the fallback for when the live
/// `Activity` isn't available at tap time.
///
/// This is the common fallback for clicks (unlike impressions): a tap can arrive when the activity
/// has already ended/dismissed, or on a cold launch before `Activity.activities` is populated, so
/// the lookup returns nil. Report with whatever the deep link carried, e.g.
/// `["wzrk_activityId": tag]`.
///
/// - Parameter wzrk: the campaign dictionary (at minimum `wzrk_activityId` from the deep link).
func recordLiveActivityClicked(wzrk: [AnyHashable: Any])
```

---

## Lifecycle events reference

The SDK records these automatically once `registerPushToStart` is called. All lifecycle stages are
sent as a **single event name `"Live Activity"`** with a `state` field:

| Event | `evtName` | Payload |
|-------|-----------|---------|
| Started | `Live Activity` | `evtData = { state: "Started", ...wzrk }` |
| Updated | `Live Activity` | `evtData = { state: "Updated", ...wzrk }` |
| Ended | `Live Activity` | `evtData = { state: "Ended", ...wzrk }` |
| Dismissed | `Live Activity` | `evtData = { state: "Dismissed", ...wzrk }` |
| Impression | `Notification Viewed` | `evtData = wzrk` |
| Click | `Notification Clicked` | `evtData = wzrk` |

Token data events the SDK sends to the backend (for your reference):

```jsonc
// Push‑to‑Start token
{ "id": "<hex>", "type": "pts", "action": "register" }

// Per‑activity token register
{ "id": "<hex>", "type": "la", "action": "register",
  "liveActivityId": "<ActivityKit id>", "activityId": <wzrk_activityId>, "activityType": <wzrk_activityType> }

// Per‑activity token unregister (on end / dismiss)
{ "type": "la", "action": "unregister",
  "liveActivityId": "<ActivityKit id>", "activityId": <wzrk_activityId>, "activityType": <wzrk_activityType> }
```

---

## The `wzrk` attribution object

The backend injects a nested `wzrk` object into `aps.attributes` at **start**, and the per‑state
fields into `content-state` on every push. Example start payload:

```jsonc
{
  "aps": {
    "event": "start",
    "attributes-type": "FoodOrderActivityAttributes",
    "attributes": {
      "restaurantName": "Pizza Palace",
      "orderSummary": "2x Margherita, 1x Garlic Bread",
      "orderId": "123456",
      "wzrk": {
        "wzrk_activityId": "order-123",
        "wzrk_activityType": 0,
        "wzrk_id": "1784798893_20260916",   // campaign id (STRING)
        "wzrk_acct_id": "YOUR-ACCT-ID",
        "W$rnv": true                        // decoded → emitted as wzrk_rnv
      }
    },
    "content-state": {
      "status": "Preparing", "estimatedDelivery": 20, "progressStep": 1,
      "wzrk_milestoneId": "order_preparing",
      "wzrk_pid": "1784798893_1789548802"
    },
    "alert": { "title": "Order update", "body": "Your order is being prepared" }
  }
}
```

| Key | Where | Type | Meaning |
|-----|-------|------|---------|
| `wzrk_activityId` | `attributes.wzrk` | String | Your activity id (used as the click `tag`) |
| `wzrk_activityType` | `attributes.wzrk` | Int | Activity type |
| `wzrk_id` | `attributes.wzrk` | **String** | Campaign id (composite) |
| `wzrk_acct_id` | `attributes.wzrk` | String | CleverTap account id (multi‑instance validation) |
| `W$rnv` → `wzrk_rnv` | `attributes.wzrk` | Bool | Raised‑not‑viewed flag |
| `wzrk_milestoneId` | `content-state` | String | Milestone — current at each event |
| `wzrk_pid` | `content-state` | String | Per‑send push id |

---

## Multi‑instance (multiple CleverTap accounts)

If you run **more than one** CleverTap instance, record impression/click on the **same instance
that owns the activity** — i.e. the instance whose `accountId` equals the activity's `wzrk_acct_id`.

The SDK enforces this: if a Live Activity event's `wzrk_acct_id` doesn't match the recording
instance's account, the event is **dropped** (and a debug log is emitted). This prevents
cross‑account attribution leakage. A missing `wzrk_acct_id` imposes no constraint.

```swift
// Record on the instance that owns the activity:
let instance = CleverTap.instance(withAccountId: "YOUR-ACCT-ID")
instance?.recordLiveActivityImpression(activity)
```

---

## onUserLogin behaviour

When you call `onUserLogin` (the device id / user changes) and an activity is active, the SDK, per
active activity:

1. Records a **`Live Activity` → `Ended`** event,
2. Sends an **unregister** token event,
3. Ends the visible activity, and
4. Re‑sends the **PTS token** for the new user so the backend can start activities for them.

No action is required from you beyond the normal `onUserLogin` call.

---

## Platform limitations

These are **iOS/ActivityKit** constraints, not SDK limitations:

| Scenario | Behaviour |
|----------|-----------|
| **Start** while app killed | ✅ Sent. iOS **background‑launches** the app on a PTS push, so the SDK registers the token and records **Started**. |
| **Update** while app killed | ❌ Not recorded. iOS re‑renders the widget **without** launching the app, so the SDK never sees the update. (Your backend already has the send record.) |
| **End** while app killed | ❌ Not recorded as *Ended*. On the next launch the activity is simply absent, so the SDK reconciles it as **Dismissed** (it can't distinguish an end push from a user swipe after the fact). |
| **Dismissed** while app killed | ✅ Recorded on the next SDK start (including background launches) via reconciliation. |
| Simulator | ❌ Live Activities don't run in the Simulator — use a real device. |

For kill‑state **update/end** analytics, rely on your backend's push‑send records.

---

## API summary

```swift
// Registration (iOS 17.2+)
// Starts PTS monitoring + lifecycle observation for this activity type. `name` is an SDK‑internal
// label (stable & unique per type). Call once, early in didFinishLaunchingWithOptions.
func registerPushToStart<Attributes: ActivityAttributes>(_ activityType: Activity<Attributes>.Type, name: String)

// Impression → "Notification Viewed" (iOS 17.2+)
// Preferred: you hold the Activity. SDK extracts current wzrk + de‑dupes once per activity (persisted).
func recordLiveActivityImpression<Attributes: ActivityAttributes>(_ activity: Activity<Attributes>)
// Escape hatch: you only have the campaign dict. NOT de‑duped — you decide when it fires.
func recordLiveActivityImpression(wzrk: [AnyHashable: Any])

// Click → "Notification Clicked" (iOS 17.2+)
// Preferred: you looked up the running Activity. SDK extracts the wzrk current at tap time.
func recordLiveActivityClicked<Attributes: ActivityAttributes>(_ activity: Activity<Attributes>)
// Fallback: Activity not available (ended/dismissed, or cold‑launch). Pass the deep link's wzrk.
func recordLiveActivityClicked(wzrk: [AnyHashable: Any])
```

Lifecycle (Started/Updated/Ended/Dismissed) and token register/unregister are handled automatically
once `registerPushToStart` is called.
