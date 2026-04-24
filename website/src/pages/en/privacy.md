---
layout: "@/layouts/Legal.astro"
title: "Privacy Policy"
description: "Dawny's privacy policy. No tracking. No analytics. No third-party SDKs."
lang: "en"
canonicalPath: "/privacy/"
---

**Last updated:** April 19, 2026
**Language:** English ([Deutsche Version](/de/datenschutz/))

## 1. Data Controller

The data controller under the GDPR is:

**Florian Schneider**
Kreuzstraße 26
76133 Karlsruhe
Germany

Email: info@dawnyapp.com

## 2. Overview

Dawny is a native iOS app for personal task planning. Dawny is designed to be **privacy-first**:

- There is **no server and no backend** operated by the developer.
- The developer does **not collect any personal data** from you.
- There is **no tracking, no analytics, no advertising, no third-party SDKs**.
- All data stays **on your device** or — if you use iCloud — inside your personal iCloud account, managed exclusively by Apple.

## 3. What data is processed?

### 3.1 Local app data (SwiftData)

Dawny stores your tasks, backlog entries, categories, and app settings locally on your iPhone using Apple's **SwiftData** framework. This data never leaves your device — unless you have iOS-wide iCloud sync enabled, in which case Apple syncs the data, encrypted, between your own Apple devices. The developer never has access to it.

### 3.2 Apple Reminders / Apple Calendar (EventKit)

If you enable Apple Reminders sync, Dawny writes the tasks of your current Daily Focus list into your local Apple Reminders database and reads changes back from it. iOS asks for permission via the standard system dialog the first time (`NSRemindersUsageDescription`). You can revoke it at any time under *Settings → Privacy & Security → Reminders → Dawny*.

This data is processed **only locally and within your own iCloud account**. Nothing is sent to the developer or to third parties.

### 3.3 Siri and App Intents

Dawny offers Siri shortcuts (e.g. "Add milk to Dawny today"). iOS asks for permission for Siri via the standard system dialog the first time (`NSSiriUsageDescription`). Voice processing is done by Apple under [Apple's Privacy Policy](https://www.apple.com/legal/privacy/en-ww/). The developer receives neither the audio nor the transcribed commands.

### 3.4 Background execution (BackgroundTasks)

Dawny uses Apple's `BackgroundTasks` framework to perform the 3 AM reset (moving unfinished Daily Focus tasks back to the backlog). **No data is sent anywhere** during this; it is a purely local operation on your app data.

### 3.5 App preferences (UserDefaults)

App preferences such as your preferred reset hour and category visibility are stored in your app container's `UserDefaults` — also purely local.

## 4. Data that is NOT processed

Dawny does **not** collect any of the following:

- Name, email, phone number, address, or other contact details.
- Location data.
- Crash reports or diagnostic telemetry sent to the developer.
- Advertising identifiers (IDFA), device IDs, or fingerprints.
- Behavioral or usage analytics.

The app contains **no third-party SDKs** (no Firebase, no Sentry, no Mixpanel, no Facebook SDK, etc.).

## 5. App Tracking Transparency

Dawny does not track and therefore does not present the **App Tracking Transparency (ATT)** dialog.

## 6. Apple as the platform

Dawny runs on iOS and uses Apple services (App Store, TestFlight, iCloud, Siri, Reminders, Calendar). For data processing by Apple, [Apple's Privacy Policy](https://www.apple.com/legal/privacy/en-ww/) applies, over which the developer has no control.

## 7. Your rights

Because Dawny does not process personal data on the developer's side, many GDPR rights (access, deletion, correction, etc.) are effectively exercised either against Apple or by you directly on your device:

- **Delete all Dawny data**: Delete the app — all local app data is removed. Items in your Apple Reminders remain in Reminders, since they belong to your Reminders database.
- **Access**: All data is visible inside the app itself and (if sync is enabled) in the Reminders app on your device.
- **Complaint**: You have the right to lodge a complaint with a data protection supervisory authority.

## 8. Contact

For privacy-related questions: **info@dawnyapp.com**

## 9. Changes to this privacy policy

This privacy policy may be updated as the app evolves. Material changes will be announced with the next app update.

## 10. Website

This website (`dawnyapp.com`) is statically hosted on IONOS in Germany. It does not use cookies, analytics, or tracking. Standard server access logs may be temporarily kept by the hosting provider for the purpose of operating the service. For more information on how IONOS processes data, see [IONOS's privacy policy](https://www.ionos.de/terms-gtc/datenschutzerklaerung/).
