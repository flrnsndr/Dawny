---
layout: "@/layouts/Legal.astro"
title: "Privacy Policy"
description: "Dawny's privacy policy. Privacy-first. No third-party SDKs in the app. Cookieless web analytics."
lang: "en"
canonicalPath: "/privacy/"
altCanonicalPath: "/datenschutz/"
---

**Last updated:** 28 August 2026
**Language:** English ([Deutsche Version](/de/datenschutz/))

## 1. Data controller

The controller within the meaning of the GDPR is:

Florian Schneider<br>
Kreuzstraße 26<br>
76133 Karlsruhe<br>
Germany

Email: [info@dawnyapp.com](mailto:info@dawnyapp.com)

## 2. Overview

Dawny is a native iOS app for personal task planning. Dawny is designed to be **privacy-first**:

- There is **no server and no backend** on the developer's side.
- **No personal data is collected** by the developer.
- There is **no tracking, no analytics, no advertising, and no third-party SDKs** in the app.
- All data stays **on your device** or, if you use iCloud, in your personal iCloud account, which is managed exclusively by Apple.

## 3. What data is processed?

### 3.1 Local app data (SwiftData)

Dawny stores your tasks, Backlog entries, categories, and app settings locally on your iPhone using the **SwiftData** framework provided by Apple. This data does not leave your device, unless you have enabled system-wide iCloud sync in the iOS settings, in which case Apple syncs the data in encrypted form between your own Apple devices. The developer has no access to it in any case.

### 3.2 Apple Reminders (EventKit)

If you enable syncing with Apple Reminders, Dawny writes the tasks of your current Today list into your local Reminders database and reads changes back from it. Permission for this is requested through the standard iOS dialog the first time it is needed (`NSRemindersUsageDescription`). You can revoke it at any time under *Settings → Privacy & Security → Reminders → Dawny*.

This data is processed **exclusively locally, or within your own iCloud account**. Nothing is sent to the developer or to third parties.

### 3.3 Siri and App Intents

Dawny provides Siri shortcuts (for example "Add milk to Dawny today"). Permission for Siri is requested through the standard iOS dialog the first time it is needed (`NSSiriUsageDescription`). Voice processing is carried out by Apple in accordance with [Apple's Privacy Policy](https://www.apple.com/legal/privacy/en-ww/). The developer receives neither the audio data nor the transcribed commands.

### 3.4 Background execution (BackgroundTasks)

Dawny uses Apple's `BackgroundTasks` framework to carry out the nightly reset (moving unfinished tasks of the day back to the Backlog or into the Archive). **No data is sent** in the process; it is a purely local operation on your app data.

### 3.5 App settings (UserDefaults)

App settings such as your preferred reset time and the visibility of categories are stored in the `UserDefaults` of your app container, likewise purely locally.

## 4. Data that is NOT processed

Dawny collects **none** of the following data:

- Name, email address, phone number, postal address, or other contact details.
- Location data.
- Crash reports or diagnostic telemetry sent to the developer.
- Advertising identifiers (IDFA), device IDs, or fingerprints.
- Behavioral or usage analytics.

The app contains **no third-party SDKs** (no Firebase, no Sentry, no Mixpanel, no Facebook SDK, etc.).

## 5. App Tracking Transparency

Dawny does not track and therefore does not present the **App Tracking Transparency (ATT)** dialog.

## 6. Apple as the platform

Dawny runs on iOS and uses Apple services (App Store, iCloud, Siri, Reminders). [Apple's Privacy Policy](https://www.apple.com/legal/privacy/en-ww/) applies to data processing by Apple, over which the developer has no influence. Clicking the download button on this website takes you to the App Store, where Apple's privacy policy applies.

## 7. Your rights

Since Dawny does not process any personal data on the developer's side, many GDPR rights (access, erasure, rectification, etc.) are in practice to be exercised against Apple or by you yourself on your device:

- **Erasure of all Dawny data**: Delete the app; this removes all local app data. Data in your Apple Reminders remains there.
- **Access**: All data can be viewed in the app itself and, if syncing is enabled, in the Reminders app on your device.
- **Complaint**: You have the right to lodge a complaint with a data protection supervisory authority, in Germany for example with the state data protection authority responsible for your federal state.

## 8. Contact

For questions about data protection: [info@dawnyapp.com](mailto:info@dawnyapp.com)

## 9. Changes to this privacy policy

This privacy policy may be adjusted if the app changes. Material changes will be communicated with the next app update.

## 10. This website

This website (`dawnyapp.com`) is hosted statically at IONOS in Germany. Apart from the cookieless web analytics described below, the site embeds **no external resources**: no Google Fonts from a CDN, no embedded videos, no maps, no social plugins, no external images. All fonts are served by the site itself.

The hosting provider processes technically necessary data in the server log files (including a shortened IP address, the time of access, the file requested, the volume of data transferred, and the browser and operating system identifier). The legal basis is Art. 6(1)(f) GDPR, my legitimate interest in the secure and trouble-free operation of the site. A data processing agreement pursuant to Art. 28 GDPR is in place with IONOS; it forms part of the IONOS terms and conditions. Further information on data processing by IONOS: [IONOS privacy policy](https://www.ionos.de/terms-gtc/datenschutzerklaerung/).

### 10.1 Cookieless web analytics (PostHog)

For audience and conversion measurement, this website uses **PostHog**, in fully **cookieless mode**. This means:

- **No cookies** are set.
- **No `localStorage` or `sessionStorage`** is used.
- There is **no cross-device tracking** and **no user identification**.
- There is no cookie banner, because no information is stored on or read from your device (§ 25 TDDDG / Art. 5(3) ePrivacy Directive).

**Provider and processor:** PostHog, Inc. Processing takes place in the **EU (Frankfurt, AWS eu-central-1)**. A data processing agreement (Data Processing Addendum) is in place, incorporated through PostHog's terms of service and containing the EU Standard Contractual Clauses. Access from the USA in the course of support cannot be ruled out and is in that case safeguarded by the Standard Contractual Clauses of the DPA.

**How it works:** When a page is loaded, the IP address and user agent are transmitted to PostHog servers in Frankfurt. From these, PostHog generates an **irreversible hash** (`hash of team ID + daily salt + IP + user agent + hostname`). The daily salt rotates every day and is deleted after processing. No personal data can be recovered from the hash.

**Information collected:** Page views, approximate time on page, scroll depth, device type, browser, operating system, approximate geographic region (derived from the IP address, not stored), referrer and UTM parameters, as well as explicitly measured interactions with the website: clicks on App Store download buttons, language switches, FAQ questions that get opened, and use of the reset demo (start, step, pause, replay).

**Legal basis:** Legitimate interest in audience measurement and in improving the website (Art. 6(1)(f) GDPR). Since no information is stored on your device, no consent under § 25 TDDDG is required.

**Objection:** You can prevent this processing by disabling JavaScript in your browser or by using a content or tracking blocker.

Further information: [PostHog Privacy Policy](https://posthog.com/privacy), [PostHog DPA / data processing agreement](https://posthog.com/dpa).

### 10.2 Contacting me

If you write to me, I process your email address and the content of your message in order to reply to it. The legal basis is Art. 6(1)(f) GDPR, my legitimate interest in being able to answer enquiries. Your message sits in my email mailbox and is deleted once the matter is settled. It is not passed on to anyone.
