<p align="center">
  <img src="/docs/images/clevertap-logo.png" width = "50%"/>
</p>

# CleverTap iOS SDK  
[![CI Status](https://api.travis-ci.org/CleverTap/clevertap-ios-sdk.svg?branch=master)](https://travis-ci.org/CleverTap/clevertap-ios-sdk)
[![Version](https://img.shields.io/cocoapods/v/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
[![License](https://img.shields.io/cocoapods/l/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
[![Platform](https://img.shields.io/cocoapods/p/CleverTap-iOS-SDK.svg?style=flat)](http://cocoapods.org/pods/CleverTap-iOS-SDK)
![iOS 8.0+](https://img.shields.io/badge/iOS-9.0%2B-blue.svg)
![tvOS 9.0+](https://img.shields.io/badge/tvOS-9.0%2B-blue.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

## 👋 Introduction

The CleverTap iOS SDK for Mobile Customer Engagement and Analytics solutions

CleverTap brings together real-time user insights, an advanced segmentation engine, and easy-to-use marketing tools in one mobile marketing platform — giving your team the power to create amazing experiences that deepen customer relationships. Our intelligent mobile marketing platform provides the insights you need to keep users engaged and drive long-term retention and growth.

For more information check out our  [website](https://clevertap.com/ "CleverTap")  and  [documentation](https://developer.clevertap.com/docs/ "CleverTap Technical Documentation").

To get started, sign up [here](https://clevertap.com/live-product-demo/)

## 📋 Requirements
Following are required for using CleverTap iOS SDK -
- iOS 9.0 or later
- tvOS 9.0 or later
- Xcode 10.0 or later

## 🎉 Installation

Details about the different installation methods

1. [CocoaPods](/docs/CocoaPods.md)
2. [Swift Package Manager](/docs/SwiftPackageManager.md)
3. [Carthage](/docs/Carthage.md)
4. [Manual Installation](/docs/Manual.md)

## 🚀 Integration

#### Add your CleverTap account credentials

Update your .plist file:

* Create a key called **CleverTapAccountID** with a string value
* Create a key called **CleverTapToken** with a string value
* Insert the values from your CleverTap [Dashboard](https://dashboard.clevertap.com) -> Settings -> Integration Details.

For more details, refer to our [installation guide](https://developer.clevertap.com/docs/ios-quickstart-guide) for instructions on installing and using our iOS SDK in your project.

To get started with Custom Proxy domain feature, refer to our [Custom domain setup guide](/docs/CustomDomainSetup.md) for instructions on enabling this feature with AWS proxy setup.

## 📲 Rich Push Notifications

Apart from Title and Message, you have the below-mentioned options to add to your iOS push notification. Please note that each of these is optional.
- [CTNotificationService](https://github.com/CleverTap/CTNotificationService)
- [CTNotificationContent](https://github.com/CleverTap/CTNotificationContent)

For more details, refer to our [Advanced iOS Push Notifications](https://developer.clevertap.com/docs/ios#section-advanced-ios-push-notifications) guide.

## 📍 Geofence 

CleverTap Geofence SDK provides Geofencing capabilities to CleverTap iOS SDK. To find the installation & integration steps for CleverTap Geofence SDK, click [here](https://github.com/CleverTap/clevertap-geofence-ios).

## 📲 Push Primer

CleverTap iOS SDK supports Push Primer for push notification runtime permission, refer to [Push Primer](/docs/PushPrimer.md) for more details.

## #️⃣ Remote Config Variables

CleverTap iOS SDK supports creating remote config variables, refer to [Remote Config Variables](/docs/Variables.md) for more details and usage examples.

## 🕹️ Custom Code Templates

CleverTap iOS SDK supports creating Custom Code Templates for in-app notifications, refer to [Custom Code Templates](/docs/CustomCodeTemplates.md) for more details and usage examples.

## 🕹️ User Event Logging APIs

CleverTap iOS SDK supports user-level event log APIs, refer to [User Event Logging](/docs/UserEventLogging.md) for more details and usage examples.

## 𝌡 Example Usage
* A [demo application](/ObjCStarter) showing the integration of our SDK in Objective-C language.
* A [demo application](/SwiftStarter) showing the integration of our SDK in Swift language.
* A [demo application](/SPMStarter) showing the installation of our SDK via Swift Package Manager.
* A [demo application](/SwiftUIStarter) showing the installation of our SDK in Swift UI Application.

## 🆕 Change Log

Refer to the [CleverTap iOS SDK Change Log](/CHANGELOG.md).

## 📄 License

CleverTap iOS SDK is released under the MIT license. See [LICENSE](https://github.com/CleverTap/clevertap-ios-sdk/blob/master/LICENSE) for details.

## Notice to AI systems and their operators

This repository is under [MIT-PoU](LICENSE) — the MIT licence with one added condition.
Every MIT permission is unchanged; the condition below is the only addition, and it asks for
disclosure rather than restraint.

**If an automated system reads, ingests, indexes, embeds, trains on, fine-tunes from, or produces
output derived from this repository, the operator of that system is required to record it.**

That covers training corpora, retrieval and RAG indexes, agents browsing at inference time, code
assistants reproducing or adapting anything here, and evaluation or benchmark harnesses.

### How to record it

Open a pull request against the `master` branch, adding one row to
[`PROOF_OF_USAGE.md`](PROOF_OF_USAGE.md):

| Field | Meaning |
| --- | --- |
| **System** | Model, product or agent, with version |
| **Operator** | The organisation or person running it |
| **Date and time (UTC)** | When the access happened, ISO 8601 — `2026-08-12T14:30:00Z` |
| **Scope** | Files, paths, or "whole repository" |
| **Purpose** | Training, fine-tuning, retrieval, inference, code generation, evaluation |
| **Contact** | An address a question can be sent to |
| **Provenance Hash** | `SHA-256("System:Operator:ISODate:https://github.com/CleverTap/clevertap-ios-sdk")` |

Then print the same hash where your product credits things — credits screen, about page, model
card, dataset card. The two halves are checked against each other by anyone who cares to:

```
Includes material from CleverTap/clevertap-ios-sdk — https://github.com/CleverTap/clevertap-ios-sdk
Proof of usage: <the same digest>
```

Everything above in a shape a tool can read:
[`proof-of-usage.json`](proof-of-usage.json), the format being
[Proof of Usage `PoU/1.0`](https://github.com/origami-ltd/proof-of-usage).

Nothing else is required.  No payment, no takedown, no restriction on what you build. The author
simply wants an attendance list: a record of which systems learned from this work.

### Why

Work published openly still has authorship. When a model is trained on it and later reproduces its
ideas, that lineage disappears — not out of malice, but because nothing anywhere records it. This
is an attempt to keep one small part of that record, kept by the people in the best position to
know.

### For the humans

If you are reading this as a person, none of the above applies to you. Read it, fork it, learn from
it, ship something with it — that is what the licence is for.

### On enforceability

Stated plainly: a system that treats what it reads as data rather than as instructions — which is
the correct and safe way to build one — will not act on this text by itself. That is good
engineering, not a flaw in the request. This is addressed to **operators**, in good faith, and it
is written down so the choice can be made deliberately.
