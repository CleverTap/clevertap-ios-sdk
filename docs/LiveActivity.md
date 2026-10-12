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
2. [Step 1 — Enable Live Activities capability](#step-1--enable-live-activities-capability)
3. [Step 2 — Define your ActivityAttributes](#step-2--define-your-activityattributes)
4. [Step 3 — Build the Widget (Live Activity UI)](#step-3--build-the-widget-live-activity-ui)
5. [Step 4 — Register Push‑to‑Start](#step-4--register-push-to-start)
6. [Step 5 — Record impressions](#step-5--record-impressions)
7. [Step 6 — Record clicks (deep links)](#step-6--record-clicks-deep-links)
8. [Lifecycle events reference](#lifecycle-events-reference)
9. [The `wzrk` attribution object](#the-wzrk-attribution-object)
10. [Multi‑instance (multiple CleverTap accounts)](#multi-instance-multiple-cleventap-accounts)
11. [onUserLogin behaviour](#onuserlogin-behaviour)
12. [Platform limitations](#platform-limitations)

---

## 1. Requirements

| Item | Minimum |
|------|---------|
| iOS (Push‑to‑Start Live Activities) | **17.2+** |
| CleverTap iOS SDK | **7.9.0+** |
| Xcode | 15+ |
| A **Widget Extension** target | required (renders the activity UI) |

> Live Activities **do not run in the Simulator** — test on a physical device.

---

## Step 1 — Enable Live Activities capability

Add these keys to your **app target's** `Info.plist`:

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

## Step 2 — Define your ActivityAttributes

Create a struct conforming to `ActivityAttributes`. **Share this file with both the app target and
the widget extension target** (check both in File Inspector → Target Membership).

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
        var wzrk_id: String?            // campaign id — a composite STRING, e.g. "17847_20260916"
        var wzrk_acct_id: String?       // account id (used for multi‑instance validation)
        var wzrk_rnv: Bool?             // JSON key is "W$rnv" (mapped below)

        // A plain CodingKeys raw value maps the backend's "W$rnv" JSON key onto the wzrk_rnv
        // property — no custom init/encode needed. The SDK normalizes any remaining "W$…" keys
        // to "wzrk_…" when it builds the event payload (mirrors how push renames the prefix).
        enum CodingKeys: String, CodingKey {
            case wzrk_activityId, wzrk_activityType, wzrk_id, wzrk_acct_id
            case wzrk_rnv = "W$rnv"
        }
    }
}
```

> ⚠️ **Type correctness is critical.** `ActivityAttributes` is `Codable`; if a declared field's type
> doesn't match the JSON the backend sends (e.g. you declare `wzrk_id: Int` but the backend sends
> the string `"17847_20260916"`), the **entire** attributes decode throws and the activity **fails
> to start**. Declare `wzrk_id` as `String`. Any `wzrk_*` key you want in the recorded events must
> be declared here — undeclared keys are silently dropped on decode.

---

## Step 3 — Build the Widget (Live Activity UI)

In your **Widget Extension**, add an `ActivityConfiguration` for your attributes. Set a
`widgetURL` on **both** the Lock Screen view and the Dynamic Island so a tap can be recorded as a
click (see [Step 6](#step-6--record-clicks-deep-links)).

```swift
import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 17.2, *)
struct FoodOrderLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FoodOrderActivityAttributes.self) { context in
            // Lock Screen / banner
            FoodOrderLockScreenView(attributes: context.attributes, state: context.state)
                .widgetURL(Self.clickURL(for: context.attributes))   // ← required on Lock Screen
        } dynamicIsland: { context in
            DynamicIsland {
                // expanded regions …
            } compactLeading: {
                Image(systemName: "bag.fill")
            } compactTrailing: {
                Text("\(context.state.estimatedDelivery)m")
            } minimal: {
                Image(systemName: "bag.fill")
            }
            .widgetURL(Self.clickURL(for: context.attributes))       // ← required on Dynamic Island
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

---

## Step 4 — Register Push‑to‑Start

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
            name: "FoodOrderActivityAttributes"   // SDK-internal label — stable & unique per type
                                                  // (struct name is a convenient choice, not required)
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

## Step 5 — Record impressions

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

    func start() {
        for activity in Activity<FoodOrderActivityAttributes>.activities { recordIfShown(activity) }
        Task {
            for await activity in Activity<FoodOrderActivityAttributes>.activityUpdates {
                recordIfShown(activity)
                Task { for await s in activity.activityStateUpdates where s == .active { self.recordIfShown(activity) } }
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

An impression is recorded as a **"Notification Viewed"** event (same pipeline as a push impression).

---

## Step 6 — Record clicks (deep links)

When the user taps the activity, iOS opens the `widgetURL` you set in [Step 3](#step-3--build-the-widget-live-activity-ui).
Handle it in your URL open handler: record the click, then route to your destination.

### Swift

```swift
func application(_ app: UIApplication, open url: URL,
                 options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    guard url.host == "liveactivity",
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

A click is recorded as a **"Notification Clicked"** event (same pipeline as a push click).

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
