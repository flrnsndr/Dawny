# Dawny — AI Context Document for Marketing

## ROLE & PURPOSE

This document is the complete, authoritative product context for Dawny. It is structured for consumption by an AI tasked with planning a comprehensive marketing campaign. All sections carry equal weight. Do not invent features, audiences, or positioning beyond what is documented here. Where constraints are listed, treat them as hard limits.

---

## 1. PRODUCT IDENTITY

| Field | Value |
|---|---|
| Name | Dawny |
| Category | iOS task management app |
| Official tagline | "A task app that deletes yesterday's tasks. On purpose." |
| One-liner | "Dawny turns unfinished tasks into signal—not failure." |
| Platform | iOS 26.2+ (iPhone), native SwiftUI |
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
> Most task apps assume unfinished = failure. Dawny assumes unfinished = information.

If a task didn't get done, it usually wasn't the actual priority. Classic tools punish this with red badges and overdue flags — creating guilt, not clarity. Dawny removes that mechanism entirely.

### Three principles that are non-negotiable

**Zero-Overdue Policy**
There are no overdue tasks in Dawny. No red. No late. No accumulated guilt. If something is not done by the end of the day, it returns to the backlog — silently, without judgment.

**The 3 AM Reset**
Every night at 3 AM (triggered on next app launch after that time), Dawny resets. All tasks that were not completed in Daily Focus return to the Backlog. The next day starts clean by default. No manual cleanup. No friction. No residue.

**Make It Count**
Tasks that repeatedly sit in Daily Focus without being completed are eventually archived (not silently re-added to the backlog). The threshold is configurable: 1–7 days. This feature is core and cannot be disabled. It treats a repeatedly-deferred task as a signal that it may never be the priority — and makes that visible.

**Intentional Days**
Dawny enforces a deliberate daily choice. Nothing moves to Today automatically. The user decides each morning what actually matters. Dawny then protects that decision until the reset.

---

## 3. HOW IT WORKS — FEATURE INVENTORY

### Currently implemented features (verified from source code)

**Two-List System**
- Backlog: everything that *could* matter someday, with no deadline pressure
- Daily Focus (labeled "Heute" in German / "Today" in English): what actually matters today
- These are the only two temporal contexts. There are no due dates, no scheduling, no calendar views.

**3 AM Reset**
- All incomplete Daily Focus tasks return to Backlog automatically
- Triggered on the first app launch after 3:00 AM
- Requires no user action

**Make It Count / Archive**
- Tasks that reach the configured threshold (1–7 days in Daily Focus without completion) are archived
- Archived tasks are viewable in a dedicated Archive section
- Archived tasks can be restored to Backlog or Daily Focus
- The threshold is user-configurable in Settings (default: 1 day)
- Make It Count cannot be disabled — it is a core feature

**Categories**
- Lightweight grouping within the Backlog
- User-defined categories with custom names and icons
- Categories can be marked as "recurring" (a default "Recurring Tasks" category exists)
- Recurring categories persist after the reset and are not affected by daily clearing
- Categories are optional; a flat uncategorized view is also available

**Quick Entry**
- Inline text row at the bottom of each category section and the Backlog list
- No modal sheet, no navigation required — just tap and type
- Also available in Daily Focus / Today view

**Apple Reminders Sync**
- Bidirectional sync with iOS Reminders via EventKit
- Daily Focus tasks appear in the iOS Reminders app
- Changes made in Reminders sync back to Dawny
- Conflict resolution: last-write-wins

**Siri / App Intents**
- "Hey Siri, add [task] to Dawny" → adds to Backlog
- "Hey Siri, add [task] to Dawny today" → adds to Daily Focus

**Privacy-first architecture**
- No server, no backend, no developer-side data collection
- No analytics, no tracking, no third-party SDKs
- All data stays on the device or in the user's own iCloud account (via Reminders sync)
- Privacy Nutrition Labels in App Store: "No data collected"

**Navigation model**
- Top bar (not a bottom tab bar): Settings (gear icon, left) / Backlog + Today segment (center) / Archive (right)
- Swipe between Backlog and Today pager-style

### Features that do NOT exist — marketing must not reference these

- Due dates or deadline reminders of any kind
- Subtasks or task hierarchies
- Notes longer than a single text field per task *(note: there is a notes field in the QuickAdd sheet, but it is minimal)*
- Recurring task automation (recurring categories exist, but individual tasks do not auto-repeat)
- macOS, iPadOS, Android, or web versions
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
- Feel guilt or avoidance when opening their task app
- Have tried multiple tools; none stick long-term

**Key insight:** They do not fail at discipline. The system fails them by design.

**What Dawny offers this group:** A system that acknowledges reality instead of fighting it. Tasks don't become overdue — they return to the pool. Each day is a fresh start.

### High-relevance sub-segment — neurodivergent people (especially ADHD)

**Important framing:** Dawny is NOT positioned as an "ADHD tool" or medical product. It is positioned as a clarity tool that *tends to work especially well* for people who don't fit rigid productivity systems.

**Why the fit exists:**
- Difficulty with long-term prioritization → Dawny only asks: "what matters today?"
- Fluctuating energy across days → the reset means yesterday's missed tasks don't haunt today
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
- Need to feel "done enough" at end of day without guilt

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
| Todoist | Due dates, projects, labels, karma score | Dawny has no due dates; no score; no guilt mechanism |
| Things 3 | Areas, projects, deadlines, "Today" list | Things' Today list doesn't reset; overdue stays overdue |
| Microsoft To Do | Lists, due dates, "My Day" (manual) | My Day is manual and doesn't enforce a reset philosophy |
| Apple Reminders | Date/time reminders, lists | Reminder-centric; missed = overdue notification |
| TickTick | Full-featured with habit tracking | Heavy and complex; opposite of Dawny's philosophy |
| Notion / Linear | Highly flexible, complex | Far too much overhead for personal daily management |

### Dawny's unique positions

**1. Zero-Overdue is a system design, not a toggle**
Other apps could add a "hide overdue" setting. Dawny removes the concept entirely from its data model. There is no overdue state. This is architectural, not cosmetic.

**2. The 3 AM Reset as a product metaphor**
No competitor uses a daily reset as a primary feature and brand identity. It is novel, memorable, and genuinely changes how users relate to their list.

**3. Make It Count as honest signal**
Instead of letting ignored tasks silently pile up, Dawny acknowledges them: if something keeps not happening, it gets archived. This respects the user's intelligence.

**4. Radical reduction as a deliberate choice**
Dawny documents what it doesn't do and explains why. This is rare in the productivity app market and resonates strongly with burned-out users.

**5. Privacy-first by architecture**
Zero developer-side data collection is not a setting or a plan tier — it is the default and only mode. No backend means nothing to breach.

### Single-sentence differentiator

*"Dawny is the only task app that treats an unfinished task as information, not failure — and enforces that philosophy in its architecture."*

---

## 6. TONE & VOICE

### Personality

- **Confident, not apologetic:** Dawny makes strong, opinionated choices and does not apologize for what it lacks. "We removed what gets in the way" is the posture, not "unfortunately we don't support X yet."
- **Honest about limits:** Dawny explicitly states what it is not for. This builds trust with the right audience.
- **Calm and direct:** No hype, no exclamation marks, no hustle language. The voice feels like it belongs to someone who has thought carefully about this.
- **Anti-hustle:** The framing is never "be more productive." It is always "protect your attention" / "start fresh" / "clarity."
- **Slightly poetic when appropriate:** "Your task list shouldn't keep score." "Tomorrow is a clean slate." — short, resonant phrases work.

### Language

- Primary language: English (the app is localized EN/DE; marketing language is not fixed but English-first is recommended for reach)
- Short sentences preferred
- Active voice
- Avoid: "boost productivity," "supercharge," "game-changer," "revolutionary," "seamless," corporate jargon

### Existing key phrases (cleared for reuse)

- "Start fresh. Every single day."
- "No overdue. No carryover. No guilt."
- "Just clarity."
- "Your to-do list that wakes up fresh every morning, free from yesterday's clutter."
- "The 3 AM Reset"
- "Make it count"
- "Intentional days"
- "Overdue tasks are a design flaw."
- "Unfinished = information, not failure."
- "A clean slate."
- "No red. No guilt. No unfinished tasks blocking your list."

---

## 7. CURRENT STATUS & DISTRIBUTION

- **Stage:** Public beta
- **Access:** TestFlight — https://testflight.apple.com/join/h9JSWasd
- **App Store:** Not yet live
- **Feedback:** TestFlight beta testers directly shape the product
- **Pricing post-launch:** Not publicly defined. Marketing must not make pricing commitments in either direction.
- **Tech stack (relevant for developer/tech media):** Swift 6, SwiftUI, SwiftData, EventKit, App Intents, BackgroundTasks framework

---

## 8. HARD CONSTRAINTS FOR ANY MARKETING CAMPAIGN

These are non-negotiable boundaries derived from factual product state and legal/ethical requirements.

1. **Do not promise features that do not exist.** See Section 3 "Features that do NOT exist." This especially includes: due dates, widgets, Apple Watch, iCloud Sync, Android, macOS.
2. **Do not make pricing statements.** Neither "free" nor any specific price point has been committed post-launch.
3. **Do not make medical or clinical claims** about ADHD, neurodivergence, or mental health. Use "tends to work especially well for people who don't fit rigid productivity systems."
4. **Do not promise cross-platform availability.** Dawny is iOS only.
5. **Use correct trademark.** The app is always "Dawny" — capital D, no other spelling.
6. **Do not imply enterprise, team, or collaboration features.** This is a personal productivity tool only.
7. **Do not imply data syncs to any cloud service controlled by the developer.** All data is local or in the user's own iCloud (via Apple Reminders only).

---

## 9. QUICK REFERENCE SUMMARY

For rapid orientation when generating marketing copy:

| Question | Answer |
|---|---|
| What is Dawny? | A minimalist iOS task app that resets daily and removes overdue entirely |
| What problem does it solve? | Task list anxiety, guilt from accumulated undone items, tool fatigue |
| Who is it for? | People overwhelmed by their own task systems; minimalists; dynamic workers; neurodivergent-friendly |
| What makes it different? | Zero-Overdue by design, 3 AM Reset, Make It Count archiving, radical reduction |
| What does it NOT do? | No due dates, no subtasks, no team features, no cross-platform |
| How do I get it? | TestFlight beta: https://testflight.apple.com/join/h9JSWasd |
| Who made it? | Florian Schneider, indie developer, Karlsruhe, Germany |
| What should the tone be? | Calm, confident, honest, anti-hustle, slightly poetic |
| What phrases are established? | "Start fresh.", "No overdue.", "Make it count.", "The 3 AM Reset", "Just clarity." |
