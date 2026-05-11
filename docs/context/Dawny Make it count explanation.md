# Dawny Feature Context: Make it Count

## Overview

**Make it Count** is the core behavioral mechanic of the to-do app **Dawny**.

It is designed to prevent stale, overloaded, unrealistic task lists by ensuring that tasks placed into **Today** must either be completed or face consequences.

Instead of allowing endless rollover of unfinished tasks, Dawny resets the day automatically and removes neglected tasks after a configurable number of missed completions.

This creates a cleaner system, daily focus, and stronger commitment to what the user chooses for today.

---

# Core Structure of Dawny

Dawny has **three main areas**:

| Tab | Purpose |
|---|---|
| **Backlog** | Storage for future tasks, organized by urgency/time horizon |
| **Today** | Active tasks selected for today |
| **Archive** | Removed / expired / inactive tasks |

---

# Backlog Categories

The Backlog is structured into planning buckets such as:

| Category | Meaning |
|---|---|
| Do Now | Immediate priority |
| Next Few Days | Short-term tasks |
| Next Few Weeks | Mid-term tasks |
| Recurring | Repeating tasks |
| Others | Optional future custom categories |

These categories help users store tasks before actively committing to them.

---

# Daily Workflow

## Morning Planning

Each morning, the user manually selects tasks from **Backlog** and moves them into **Today**.

Only tasks inside **Today** are considered active commitments for the current day.

These Today tasks are also synced / visible in:

- Calendar
- Apple Reminders
- Daily execution views

---

# End-of-Day Reset Mechanic

At a configurable reset time (default: **3:00 AM**), Dawny evaluates unfinished Today tasks.

If a task was **not checked off**, it is treated as incomplete.

Reasons may include:

- User did not do it
- Task became irrelevant
- User completed it but forgot to check it off

The system does not distinguish between reasons. Only completion state matters.

---

# Make it Count Logic

Each task has a configurable tolerance for missed completions.

Example setting:

> Archive after being missed 1 time  
> Archive after being missed 3 times  
> Archive after being missed 5 times

## Behavior

### If threshold = 1 (Standard)

Miss once → move directly to **Archive**

### If threshold > 1

Missed attempts before threshold:

Today → Backlog

Final missed attempt:

Today → Archive

### If recurring task

Complete or miss → move back to **Backlog**

---

# Example Flows

## Standard threshold = 1

Task added to Today  
Not completed today  
3:00 AM reset occurs

Result:

Today → Archive

---

## Flexible Mode (3 misses allowed)

Day 1 missed:

Today → Backlog

Day 2 selected again, missed:

Today → Backlog

Day 3 selected again, missed:

Today → Archive

---

## Recurring tasks (uncompleted)

Task added to Today  
Not completed today  
3:00 AM reset occurs

Result:

Today → Backlog

## Recurring tasks (completed)

Task added to Today  
Completed  

Result:

Today → Backlog

# Why This Matters

Traditional to-do apps often allow infinite rollover, causing:

- bloated task lists
- guilt from unfinished tasks
- fake productivity systems
- ignored priorities
- cluttered daily views

**Make it Count** solves this by forcing intentional selection.

If a task is chosen for Today, it should matter.

---

# Product Philosophy

Today is sacred.

Only place tasks there that deserve attention now.

If something repeatedly fails to get done, it likely means:

- wrong priority
- bad timing
- low importance
- lack of commitment
- no longer relevant

Dawny reflects this reality instead of hiding it.

---

# Recovery / Manual Control

Archived tasks are not deleted.

Users can manually restore tasks from Archive to:

- Backlog
- Today

This keeps the system forgiving while still enforcing discipline.

---

# Configurable Parameters

| Setting | Default |
|---|---|
| Daily reset time | 3:00 AM |
| Miss threshold before archive | 1 |

---

# Short Product Definition

**Make it Count** is a consequence-based task commitment system where unfinished Today tasks are automatically reset and eventually archived after repeated neglect.

---

# UX Principle

Selecting a task for Today is not passive planning.  
It is an active commitment.

---