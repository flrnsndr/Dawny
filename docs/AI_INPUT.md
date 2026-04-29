# Dawny — AI Context Document for Marketing

## ROLE & PURPOSE

This document is the complete, authoritative product context for Dawny. It is structured for consumption by an AI tasked with planning a comprehensive marketing campaign. All sections carry equal weight. Do not invent features, audiences, or positioning beyond what is documented here. Where constraints are listed, treat them as hard limits.

Last source-code review for factual product state: April 27, 2026. Re-verify before major launch campaigns or App Store copy.

---

## 1. PRODUCT IDENTITY

| Field | Value |
|---|---|
| Name | Dawny |
| Category | iOS task management app |
| Official tagline | "A task app that deletes yesterday's tasks. On purpose." |
| One-liner | "Dawny turns unfinished tasks into a clear priority signal." |
| Platform | iOS 26.2+, native SwiftUI. Designed and tested primarily for iPhone; do not position as an iPad-optimized product unless separately verified. |
| Distribution | Public Beta via TestFlight |
| TestFlight link | https://testflight.apple.com/join/h9JSWasd |
| App Store | Not yet live |
| Pricing | Free during beta. No pricing commitment for post-launch. |
| Developer | Florian Schneider, Karlsruhe, Germany |
| Contact | info@dawnyapp.com |
| Project type | Independent (indie), no VC backing, noncommercial license |
| Trademark | "Dawny" and the Dawny logo are common-law trademarks. Correct capitalization must be maintained. |

---

## 2. THE CORE PHILOSOPHY

Every design decision in Dawny follows from one thesis:

> **Overdue tasks are a design flaw.**
> Most task apps treat unfinished tasks as overdue. Dawny treats them as a priority signal.

If a task didn't get done, it usually wasn't the actual priority. Classic tools keep surfacing it with red badges and overdue flags — creating artificial urgency instead of clarity. Dawny removes that mechanism entirely.

### Core principles that are non-negotiable

**Zero-Overdue Policy**
There are no overdue tasks in Dawny. No red. No late. No accumulated pressure. If something is not done by the daily reset, it is processed without judgment: it either returns to the Backlog or, once the Make It Count threshold is reached, moves to the Archive.

**The 3 AM Reset**
The default reset time is 3 AM. This is also the product metaphor and recommended marketing phrase. In the app, the reset hour is configurable in Settings. The reset is checked when the app launches or becomes active, and Dawny also schedules a local background refresh when iOS allows it. The promise is not "an exact server-side cron job"; the promise is that the user's Daily Focus is cleared automatically without manual cleanup.

**Make It Count**
Make It Count is Dawny's mechanism for turning repeated non-completion into a clear signal. Each non-recurring task tracks how many times it was in Daily Focus and still incomplete at the daily reset. The threshold is configurable from 1–7 missed resets, with a default of 1. When the task reaches that threshold, it is moved to the Archive instead of being quietly returned to the Backlog again.

The Archive is not punishment. It is a visible, recoverable holding area for tasks that the user's actual behavior has repeatedly deprioritized. Archived tasks are out of the way, but not lost: the user can restore them to Backlog, restore them directly to Today/Daily Focus, or delete them permanently. This is central to Dawny's philosophy: repeated non-completion is a signal about priority.

Make It Count is a core feature and cannot be disabled. Recurring-category tasks are the exception: they return to Backlog at reset and are not archived by Make It Count.

**Intentional Days**
Dawny enforces a deliberate daily choice. Nothing moves to Today automatically. The user decides each morning what actually matters. Dawny then protects that decision until the reset.

---

## 3. HOW IT WORKS — FEATURE INVENTORY

### Currently implemented features (verified from source code)

**Two-List System**
- Backlog: everything that *could* matter someday, with no deadline pressure
- Daily Focus (labeled "Heute" in German / "Today" in English): what actually matters today
- These are the only two user-facing planning contexts. There are no due dates, deadline reminders, manual scheduling screens, or calendar views.

**3 AM Reset**
- The default reset hour is 3:00 AM; users can change the reset hour in Settings
- The reset is checked on app launch and when the app becomes active
- Dawny also schedules a local BackgroundTasks refresh, subject to iOS background execution rules
- Incomplete Daily Focus tasks are processed automatically: most return to Backlog, but tasks that reach the Make It Count threshold move to Archive instead
- Requires no manual cleanup from the user

**Make It Count / Archive**
- Make It Count tracks missed Daily Focus commitments per non-recurring task
- A "miss" happens when a task is still incomplete in Daily Focus at the daily reset
- The threshold is user-configurable in Settings from 1–7 missed resets
- The default threshold is 1, meaning a non-recurring task can be archived after the first missed reset
- Before the threshold is reached, the task returns to Backlog at reset
- Once the threshold is reached, the task moves to Archive instead of returning to Backlog again
- The Archive is a dedicated section/tab, not a trash bin
- Archived tasks remain visible and recoverable
- Archived tasks can be restored to Backlog
- Archived tasks can be restored directly to Daily Focus / Today
- Archived tasks can also be deleted permanently by the user
- A dot badge can indicate that new tasks were archived by the latest reset
- Restoring a task from Archive resets its missed-reset count
- Manually moving a task out of Daily Focus back to Backlog resets its missed-reset count
- Completed tasks are not archived by Make It Count
- Tasks in recurring categories are not archived by Make It Count; they return to Backlog at reset
- Make It Count cannot be disabled — it is a core feature
- Marketing framing: this is not punishment and not a moral judgment. It is a calm signal that the task has repeatedly not been the real priority.

**Categories**
- Lightweight grouping within the Backlog
- User-defined categories with custom names and icons
- Categories can be marked as "recurring" (a default "Recurring Tasks" category exists)
- Tasks in recurring categories return to Backlog at reset and are excluded from Make It Count archiving
- When a recurring-category task is completed in Today, Dawny creates a fresh Backlog copy so the recurring item remains available
- Categories are optional; a flat uncategorized view is also available

**Quick Entry**
- Inline text row at the bottom of each category section and the Backlog list
- No modal sheet, no navigation required — just tap and type
- Also available in Daily Focus / Today view

**Apple Reminders Sync**
- Permission-dependent sync with iOS Reminders via EventKit
- Sync can be toggled in Settings and is enabled by default, but still requires the user's iOS Reminders permission
- Daily Focus tasks can appear in the iOS Reminders app
- Changes made to linked Reminders can sync back to Dawny
- Conflict resolution: last-write-wins based on modification timestamps
- This is not a full Reminders import or a general calendar-planning feature

**Siri / App Intents**
- "Hey Siri, add [task] to Dawny" → adds to Backlog
- "Hey Siri, add [task] to Dawny today" → adds to Daily Focus

**Privacy-first app architecture**
- The Dawny app has no server, no backend, and no developer-side task-data collection
- The app has no analytics, no tracking, no advertising SDKs, and no third-party SDKs
- App data stays on the device, except where the user chooses Apple-owned services such as Apple Reminders, which Apple may sync through the user's own iCloud settings
- Reminders sync uses the user's own Apple Reminders database; nothing is sent to a Dawny-controlled backend
- Privacy Nutrition Labels in App Store should be "No data collected" for the app, as long as this architecture remains unchanged

**Website analytics distinction**
- The marketing website may use cookieless PostHog analytics for audience measurement and conversion tracking
- This does not contradict the app's privacy-first architecture, but marketing must not claim "no analytics anywhere" across app + website
- Correct framing: "The app has no analytics or tracking. The website may use cookieless, non-identifying analytics as described in the privacy policy."

**Navigation model**
- Top bar (not a bottom tab bar): Settings (gear icon, left) / Backlog + Today segment (center) / Archive (right)
- Pager-style swipe navigation across Backlog, Today, and Archive

### Features that do NOT exist — marketing must not reference these

- Due dates or deadline reminders of any kind
- Subtasks or task hierarchies
- Rich notes, attachments, comments, or document-like task detail pages
- Date-based recurring task schedules (recurring categories exist, but there are no scheduled repeat rules like "every Monday")
- Dedicated macOS, Android, or web app versions
- iPad-optimized positioning unless separately tested and verified
- Team collaboration or shared lists
- iCloud Sync (on roadmap, not live)
- Home Screen Widget (on roadmap, not live)
- Apple Watch app (on roadmap, not live)
- Calendar view or date-based planning

---

## 4. TARGET AUDIENCE

### Primary audience — people overwhelmed by their own task systems

**Profile:**
- Reliably capture tasks, but the list grows faster than it shrinks
- Accumulated backlog becomes emotionally draining and loses relevance
- Repeatedly reschedule tasks rather than deciding
- Feel overload or avoidance when opening their task app
- Have tried multiple tools; none stick long-term

**Key insight:** They do not fail at discipline. The system fails them by design.

**What Dawny offers this group:** A system that acknowledges reality instead of fighting it. Tasks don't become overdue — they return to the pool or move to the Archive. Each day is a fresh start.

### High-relevance sub-segment — neurodivergent people (especially ADHD)

**Important framing:** Dawny is NOT positioned as an "ADHD tool" or medical product. It is positioned as a clarity tool that *tends to work especially well* for people who don't fit rigid productivity systems.

**Why the fit exists:**
- Difficulty with long-term prioritization → Dawny only asks: "what matters today?"
- Fluctuating energy across days → the reset means yesterday's missed tasks don't fill today's view
- High sensitivity to visual overload and "open loops" → Dawny removes both with the reset
- Low attachment to artificial deadlines → Dawny has none
- Classic tools often get abandoned entirely → Dawny's simplicity reduces that risk

**Communication rule:** Use "tends to work especially well for people who don't fit rigid productivity systems — including many neurodivergent thinkers." Do not make clinical claims.

### Secondary audiences

**Minimalists and anti-feature-overload users**
- Actively reject complex systems (GTD, Notion databases, nested projects)
- Want one tool that does one thing well
- The absence of features is itself the value proposition

**Knowledge workers with dynamic priorities**
- Product managers, founders, freelancers, creatives
- Their priorities genuinely shift daily; deadline-based tools create false urgency
- Need to end the day without dragging every open loop into tomorrow

**"Tool fatigue" users**
- Have tried Todoist, Things, Notion, Reminders, etc.
- Frustrated by the overhead of maintaining complex systems
- Looking for something they can actually sustain

### Not the target audience (do not target these groups)

- Users who need complex project planning, subtasks, or dependencies
- Teams requiring shared or collaborative task management
- Users whose workflow depends on deadline reminders
- Android users

---

## 5. COMPETITIVE DIFFERENTIATION

### Competitive landscape

| Competitor | Core model | Dawny's difference |
|---|---|---|
| Todoist | Due dates, projects, labels, karma score | Dawny has no due dates; no score; no overdue-pressure mechanism |
| Things 3 | Areas, projects, deadlines, "Today" list | Things' Today list doesn't reset; overdue stays overdue |
| Microsoft To Do | Lists, due dates, "My Day" (manual) | My Day is manual and doesn't enforce a reset philosophy |
| Apple Reminders | Date/time reminders, lists | Reminder-centric; missed = overdue notification |
| TickTick | Full-featured with habit tracking | Heavy and complex; opposite of Dawny's philosophy |
| Notion / Linear | Highly flexible, complex | Far too much overhead for personal daily management |

### Dawny's unique positions

**1. Zero-Overdue is a system design, not a toggle**
Other apps could add a "hide overdue" setting. Dawny removes the concept entirely from its data model. There is no overdue state. This is architectural, not cosmetic.

**2. The 3 AM Reset as a product metaphor**
The daily reset is a primary product behavior and brand metaphor. It is memorable and genuinely changes how users relate to their list. Avoid unverified absolute claims such as "no competitor does this."

**3. Make It Count as honest signal**
Instead of letting ignored tasks silently pile up, Dawny acknowledges them: if a task repeatedly misses the user's chosen day, it gets archived into a visible, recoverable place. This respects the user's intelligence and treats repeated non-completion as a priority signal.

**4. Radical reduction as a deliberate choice**
Dawny documents what it doesn't do and explains why. This is rare in the productivity app market and resonates strongly with burned-out users.

**5. Privacy-first by architecture**
For the app, zero developer-side task-data collection is not a setting or a plan tier — it is the default and only mode. No app backend means there is no Dawny-controlled task database to breach.

### Single-sentence differentiator

*"Dawny treats repeated non-completion as a priority signal — and enforces that philosophy in its architecture."*

---

## 6. TONE & VOICE

### Personality

- **Confident, not apologetic:** Dawny makes strong, opinionated choices and does not apologize for what it lacks. "We removed what gets in the way" is the posture, not "unfortunately we don't support X yet."
- **Honest about limits:** Dawny explicitly states what it is not for. This builds trust with the right audience.
- **Calm and direct:** No hype, no exclamation marks, no hustle language. The voice feels like it belongs to someone who has thought carefully about this.
- **Anti-hustle:** The framing is never "be more productive." It is always "protect your attention" / "start fresh" / "clarity."
- **Slightly poetic when appropriate:** "Your task list shouldn't keep score." "Tomorrow is a clean slate." — short, resonant phrases work.

### Language

- Primary language: English for broad reach; German is also a first-class marketing language because the app and website are localized EN/DE
- Short sentences preferred
- Active voice
- Avoid: "boost productivity," "supercharge," "game-changer," "revolutionary," "seamless," corporate jargon

### Approved neurodivergence phrasing

- English: "Dawny tends to work especially well for people who find classic productivity systems too rigid — including many neurodivergent thinkers."
- German: "Dawny passt oft besonders gut zu Menschen, für die klassische Produktivitätssysteme zu starr sind — darunter auch viele neurodivergente Köpfe."
- Do not say Dawny treats ADHD, improves mental health, reduces symptoms, or is a medical/clinical tool.

### Existing key phrases (cleared for reuse)

- "Start fresh. Every single day."
- "No overdue. No carryover. Just clarity."
- "Just clarity."
- "Your to-do list that wakes up fresh every morning, free from yesterday's clutter."
- "The 3 AM Reset"
- "Make it count"
- "Intentional days"
- "Overdue tasks are a design flaw."
- "Not done does not mean failed. It means: maybe it wasn't important enough for today."
- German: "Nicht erledigt heißt nicht gescheitert. Es heißt: vielleicht war es nicht wichtig genug für heute."
- "A clean slate."
- "No red. No artificial urgency. No unfinished tasks blocking your list."

---

## 7. CURRENT STATUS & DISTRIBUTION

- **Stage:** Public beta
- **Access:** TestFlight — https://testflight.apple.com/join/h9JSWasd
- **App Store:** Not yet live
- **Feedback:** TestFlight beta testers directly shape the product
- **Pricing post-launch:** Not publicly defined. Marketing must not make pricing commitments in either direction.
- **Platform positioning:** iOS 26.2+. Developed and tested primarily for iPhone. Do not market as iPad-optimized unless separately verified.
- **Tech stack (relevant for developer/tech media):** Swift 6, SwiftUI, SwiftData, EventKit, App Intents, BackgroundTasks framework

---

## 8. HARD CONSTRAINTS FOR ANY MARKETING CAMPAIGN

These are non-negotiable boundaries derived from factual product state and legal/ethical requirements.

1. **Do not promise features that do not exist.** See Section 3 "Features that do NOT exist." This especially includes: due dates, widgets, Apple Watch, iCloud Sync, Android, macOS, web, and iPad-optimized workflows.
2. **Do not make post-launch pricing statements.** Dawny is free during TestFlight beta. No specific post-launch price point or free-plan commitment has been made.
3. **Do not make medical or clinical claims** about ADHD, neurodivergence, or mental health. Use "tends to work especially well for people who don't fit rigid productivity systems."
4. **Do not promise cross-platform availability.** Dawny is iOS only, developed and tested primarily for iPhone.
5. **Use correct trademark.** The app is always "Dawny" — capital D, no other spelling.
6. **Do not imply enterprise, team, or collaboration features.** This is a personal productivity tool only.
7. **Do not imply data syncs to any cloud service controlled by the developer.** App data is local or in Apple-owned services the user chooses, such as Apple Reminders behavior controlled by Apple and the user's own iCloud settings.
8. **Keep app privacy claims separate from website analytics.** The app has no analytics or third-party SDKs. The website may use cookieless PostHog analytics as disclosed in the privacy policy.
9. **Do not overpromise background timing.** The 3 AM Reset is the default product metaphor and reset time, but iOS controls background execution. It is safe to say Dawny resets automatically; do not imply a remote server guarantees exact execution at 3:00:00 AM.

---

## 9. QUICK REFERENCE SUMMARY

For rapid orientation when generating marketing copy:

| Question | Answer |
|---|---|
| What is Dawny? | A minimalist iOS task app, designed primarily for iPhone, that resets daily and removes overdue entirely |
| What problem does it solve? | Task list overload, stale tasks blocking today's focus, tool fatigue |
| Who is it for? | People overwhelmed by their own task systems; minimalists; dynamic workers; neurodivergent-friendly |
| What makes it different? | Zero-Overdue by design, 3 AM Reset, Make It Count archiving, recoverable Archive, radical reduction |
| What does it NOT do? | No due dates, no subtasks, no team features, no cross-platform, no iPad-optimized promise |
| How do I get it? | TestFlight beta: https://testflight.apple.com/join/h9JSWasd |
| Who made it? | Florian Schneider, indie developer, Karlsruhe, Germany |
| What should the tone be? | Calm, confident, honest, anti-hustle, slightly poetic |
| What phrases are established? | "Start fresh.", "No overdue.", "Make it count.", "The 3 AM Reset", "Just clarity." |
