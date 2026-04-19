<h1 align="center">Dawny</h1>

<p align="center">
  <strong>Plan each day on its own terms, without yesterday's unfinished noise.</strong>
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-iOS%2026.2%2B-blue">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6-orange">
  <img alt="UI" src="https://img.shields.io/badge/UI-SwiftUI-0A84FF">
  <img alt="Persistence" src="https://img.shields.io/badge/Data-SwiftData-34C759">
  <a href="https://testflight.apple.com/join/h9JSWasd"><img alt="TestFlight" src="https://img.shields.io/badge/TestFlight-Join%20Beta-000000?logo=apple"></a>
  <img alt="Status" src="https://img.shields.io/badge/status-beta-yellow">
</p>

<p align="center">
  <img alt="Dawny logo hero" src="App/Assets.xcassets/AppIcon.appiconset/Dawny%20Icon%20Gemini%201024x1024%20300dpi.png" width="300">
</p>

<p align="center">
  <a href="https://testflight.apple.com/join/h9JSWasd">
    <img alt="Join the TestFlight Beta" src="https://img.shields.io/badge/TestFlight-Join%20the%20Beta-000000?style=for-the-badge&logo=apple">
  </a>
</p>

<p align="center">
  <strong>🌅 🌅 🌅</strong><br>
  <strong>CLEAR LIST.</strong><br>
  <strong>CLEAR MIND.</strong><br>
  <strong>FOCUS ON WHAT TRULY MATTERS.</strong><br>
  <strong>🌅 🌅 🌅</strong>
</p>

<p align="center">
  <strong>Built for people with too many overdue lists and too little clarity.</strong>
</p>

<p align="center">
  If you did not finish a task today, your day likely had other priorities.<br>
  At 3 AM, Dawny automatically moves unfinished Daily Focus tasks back to Backlog.<br>
  Your list does not get clogged with old, low value, unfinished tasks.<br>
</p>

- ✅ Native iOS only task manager
- ✅ Built completely in Swift with SwiftUI
- ✅ Deeply integrated into the iOS ecosystem through Apple Reminders, Calendar APIs, and Siri
- ✅ Built around one opinionated idea: **nothing is ever overdue**
- ✅ Signature behavior: **3 AM reset** that automatically clears unfinished Daily Focus tasks back into Backlog

Every day is different. Every day deserves its own plan. If something was not done, that usually means the day had different priorities. Dawny protects your focus by giving you a clean starting point each morning, so your mind stays clear for what truly matters.

---

## Why Dawny

Most task apps punish you. Tasks you did not finish yesterday turn red and stay red. The list grows, context changes, and yesterday's leftovers compete with today's real priorities.

Dawny takes the opposite stance: **overdue tasks are a design bug, not a feature.** Unfinished does not automatically mean failed. Often it just means "not the right priority for that day."

### The 3 AM Reset

Dawny has two lists: **Backlog** (someday) and **Daily Focus** (today). Each day you pull a handful of tasks from the backlog into focus. At 3 AM, while you are asleep, anything still unchecked in Daily Focus is moved back to the backlog. Nothing is deleted, and nothing clutters today by default.

This gives you a true daily reset. Plan each day on its own terms, keep old noise out of sight, and stay focused on what counts now.

---

## Who is this for

> **Most important: The overwhelmed planner**  
> You have tried Todoist, Things, TickTick, or MS To Do, and ended up with a graveyard of ignored red items from days that no longer matter.

- **The overwhelmed planner** who needs a clean daily reset instead of another accumulating backlog of overdue tasks.
- **The deliberate minimalist** who wants fewer choices and a tool that helps choose today's priorities instead of carrying yesterday's leftovers forever.
- **The iOS native user** who lives in Apple Reminders and Siri and wants a task app that feels truly native.

### Dawny is probably *not* for you if you need

- Cross-platform sync (Android, Web, Windows).
- Recurring tasks, subtasks, or tags.
- Multiple projects or nested lists.
- Arbitrary due dates and specific time reminders.

That's fine. Dawny is deliberately small. If it does not fit, other tools are excellent.

---

## Features

- **Two-list system** with Backlog for someday and Daily Focus for today.
- **3 AM auto-reset** returns unfinished focus tasks to the backlog overnight, creating space for a fresh morning plan.
- **Bidirectional iOS Reminders sync** shows Daily Focus tasks in Apple Reminders and syncs changes both ways.
- **Siri shortcuts** support voice input such as "Hey Siri, add milk to Dawny today."
- **Categories** provide lightweight grouping when needed.
- **Native feel** comes from SwiftUI, haptic feedback, Dynamic Type, and full localization scaffolding (`Localizable.xcstrings`).
- **Built to be testable** through protocol based time and calendar access, so daily reset behavior can be validated deterministically.

---

## Get Dawny

### Join the TestFlight beta

Dawny is currently in public beta on TestFlight:

<p align="center">
  <a href="https://testflight.apple.com/join/h9JSWasd">
    <img alt="Join the TestFlight Beta" src="https://img.shields.io/badge/TestFlight-Join%20the%20Beta-000000?style=for-the-badge&logo=apple">
  </a>
</p>

> Dawny is built by a single developer. Your feedback shapes the app. Use the in app feedback button in TestFlight to tell me what works, what does not, and what is missing from your workflow.

Requirements: iPhone running **iOS 26.2 or later**.

If a task was not done today, that can be useful information, not failure. Dawny is designed around that mindset.

---

## Tech stack

- **Platform**: iOS 26.2+
- **Language**: Swift 6
- **UI**: SwiftUI
- **Persistence**: SwiftData
- **Calendar integration**: EventKit
- **Voice**: App Intents (Siri)
- **Background execution**: BackgroundTasks framework
- **Testing**: XCTest (unit, integration, UI)

## Roadmap

Intentionally small for now. Possible future additions are welcome only if they do not violate the Zero Overdue Philosophy.

- Home Screen widget
- Apple Watch companion app
- Multiple backlogs (for example work and personal)
- Stats and insights
- iCloud sync across iOS devices

Explicitly **not** on the roadmap: recurring tasks, subtasks, tags, arbitrary due dates, and cross platform clients. The goal is a clear mind and a clean daily planning surface, not a bigger feature set.

---

---

<p align="center">
  Built with care by <a href="https://github.com/flrnsndr">@flrnsndr</a>.<br>
  <sub>Every morning is a blank page.</sub>
</p>
