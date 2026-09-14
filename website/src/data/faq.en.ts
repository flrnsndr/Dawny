import type { FaqBlock } from "@/data/faq";

/** English FAQ content. Item and block ids are shared with faq.de.ts (see faq.ts). */
export const faqBlocks: FaqBlock[] = [
  {
    id: "reset",
    anchor: "faq-reset",
    title: "The reset",
    intro: "What happens at 3 AM, and why.",
    surface: "paper",
    next: { anchor: "faq-bedienung", label: "Getting the most out of Dawny" },
    groups: [
      {
        items: [
          {
            id: "reset-ablauf",
            q: "What exactly happens at three in the morning?",
            a: "Dawny closes out the day and empties the Today list. Tasks you finished end up in the Archive under “Completed”. Unfinished ones go to the Archive too by default, under “Archived”. Recurring tasks return to the Backlog. The app does not need to be open for any of this.",
          },
          {
            id: "reset-warum-drei-uhr",
            q: "Why three in the morning and not midnight?",
            a: "Because a day does not end at twelve, it ends when you go to sleep. If you check something off at half past midnight, you want to see it in yesterday's Today, not in today's tomorrow.",
          },
          {
            id: "reset-uhrzeit",
            q: "Can I change the time?",
            a: "Yes. In Settings you can set the reset to any full hour. Three in the morning is just the default.",
          },
          {
            id: "reset-nicht-geschafft",
            q: "What happens to tasks I did not get done?",
            a: "They are not quietly pushed to tomorrow. By default they move to the Archive, because a spot on the Today list is a commitment and not a filing cabinet. A swipe right brings them back from there, either to the Backlog or straight to Today.",
          },
          {
            id: "reset-erledigte-weg",
            q: "Are my completed tasks gone afterwards?",
            a: "No. They sit in the Archive under “Completed”, sorted by date. You can look up at any time what you got done on a particular day.",
          },
          {
            id: "reset-uebersicht",
            q: "How do I know what happened overnight?",
            a: "The first time you open the app after a reset, Dawny shows a short two-step summary: first what was filed away from Today, then what was tidied out of the Backlog. After that you are up to date and the summary disappears.",
          },
        ],
      },
    ],
  },
  {
    id: "bedienung",
    anchor: "faq-bedienung",
    title: "Getting the most out of Dawny",
    intro: "The gestures worth seeing once, and how to plan a day with them.",
    surface: "paper-warm",
    next: { anchor: "faq-konzept", label: "The idea behind it" },
    groups: [
      {
        label: "The gestures",
        items: [
          {
            id: "bedienung-backlog-nach-heute",
            q: "How do I move a task from the Backlog to Today?",
            a: "Swipe the row right. An orange sun labelled “Today” appears and the task moves over. Swipe far enough and you do not even need to tap.",
          },
          {
            id: "bedienung-abhaken",
            q: "How do I check a task off?",
            a: "In the Today tab, tap the circle to the left of the task. It slides down to the completed tasks. If you would rather not see them there, you can hide that section in Settings.",
          },
          {
            id: "bedienung-neue-aufgabe",
            q: "How do I create a new task?",
            a: "In Today and in the Backlog there is always an empty row below the list. Tap into it, start typing, and Return creates the task so you can type the next one right away. For the Backlog you pick the category it should go into first.",
          },
          {
            id: "bedienung-archiv-zurueckholen",
            q: "How do I get something back out of the Archive?",
            a: "Swipe the row in the Archive right. You get two targets: “Backlog” puts it back into storage, “Today” puts it on your plate for today. A swipe left deletes it for good.",
          },
          {
            id: "bedienung-kategorie-wechseln",
            q: "How do I move a task into a different category?",
            a: "Press and hold the row in the Backlog and a list of all categories appears. Alternatively, drag the task onto the heading of the category you want.",
          },
          {
            id: "bedienung-notizen",
            q: "Can I attach notes to a task?",
            a: "Yes. Tap the task to open its details. Short notes are shown right in the row below the title.",
          },
          {
            id: "bedienung-eigene-kategorien",
            q: "Can I create my own categories?",
            a: "Yes, as many as you like, each with its own name and symbol. There is a dedicated row for it at the end of the category list in the Backlog.",
          },
          {
            id: "bedienung-wiederkehrende-kategorien",
            q: "What are recurring categories?",
            a: "A category can be marked as recurring. Nothing in it is ever archived, it goes back to the Backlog overnight whether you finished it or not. Exactly right for workouts, watering plants or vocabulary.",
          },
        ],
      },
      {
        label: "Planning a day",
        items: [
          {
            id: "bedienung-anzahl-heute",
            q: "How many tasks belong in Today?",
            a: "As many as you genuinely trust yourself to do on this one day. For most people that is three to five. The list is deliberately short so that you still look at it in the evening instead of swiping it away.",
          },
          {
            id: "bedienung-planen",
            q: "When is the best time to plan?",
            a: "In the morning, in a minute. You go through the Backlog from top to bottom, pull out what is due today, and close the app again. The reset has already cleared the list for you.",
          },
          {
            id: "bedienung-immer-wieder-verschieben",
            q: "What do I do with tasks I keep postponing?",
            a: "When a task lands in the Archive for the third time, that is your answer. Either you break it down into a first small step you will actually do today, or you leave it in the Archive. Both are a decision, and both beat postponing it forever.",
          },
          {
            id: "bedienung-grosses-vorhaben",
            q: "I have a big undertaking that will take weeks. How do I model that?",
            a: "Not as a single task. Dawny deliberately has no projects and no subtasks. Set the big thing up as a category and write the next concrete steps into it. Every morning you pull one of them into Today.",
          },
        ],
      },
    ],
  },
  {
    id: "konzept",
    anchor: "faq-konzept",
    title: "The idea behind it",
    intro: "The questions that come up when Dawny behaves differently than expected.",
    surface: "paper-2",
    next: { anchor: "faq-technik", label: "Devices, sync and widgets" },
    groups: [
      {
        items: [
          {
            id: "konzept-backlog-nicht-abhaken",
            q: "Why can't I check anything off in the Backlog?",
            a: "Because finishing things happens in Today. The Backlog is a collection of everything that is coming up at some point, not the list you are working on right now. That is why the circle is visible but greyed out. Swipe the task over to Today and you can check it off.",
          },
          {
            id: "konzept-warum-archivieren",
            q: "Why are unfinished tasks archived at all?",
            a: "Because a list that only grows eventually stops being read. If leftovers simply stay put, every look at the list costs you energy for things you wrote off long ago. Dawny clears them away and leaves the decision to you whether to bring them back.",
          },
          {
            id: "konzept-make-it-count",
            q: "It bothers me that tasks are archived on the very first try. What can I do?",
            a: "That is adjustable. In Settings there is a number from 1 to 7 under “Make it count”. It says how often a task may sit unfinished in Today before it goes to the Archive. At 3 it returns to the Backlog twice and only moves to the Archive on the third time.",
          },
          {
            id: "konzept-keine-prioritaet",
            q: "Why can't I give a task a priority?",
            a: "Because priorities are a lie you tell yourself. After two weeks everything is “high”. Dawny asks the simpler question instead: roughly when? That is where the time horizons in the Backlog come from. The real prioritising happens every morning when you decide what moves to Today.",
          },
          {
            id: "konzept-keine-faelligkeitsdaten",
            q: "Why are there no due dates and no reminders?",
            a: "Because a date in the future defers a decision instead of making it. Dawny has exactly two points in time: today and someday. If you need a task at a fixed moment, it belongs in your calendar or in Apple Reminders, and Dawny can mirror it there.",
          },
          {
            id: "konzept-keine-projekte",
            q: "Why no projects, tags or subtasks?",
            a: "Because every extra bit of structure is an extra decision you make before you have finished anything. Dawny has one level: a task, in a category. If you need more structure, create more categories.",
          },
          {
            id: "konzept-archiviert-verloren",
            q: "Is an archived task lost?",
            a: "No. Archived means filed, not deleted. The Archive is searchable and sorted by date, and a swipe brings any task back. The only things that get deleted are the ones you delete yourself.",
          },
          {
            id: "konzept-backlog-aufraeumen",
            q: "Why did a task disappear from the Backlog even though it was never in Today?",
            a: "The Backlog tidies itself too. Every category has a lifespan: “Quick” seven days, “Next couple of days” 21, “Next couple of weeks” 60, “Next couple of months” a year. Anything left untouched for longer moves to the Archive. “Someday” has no limit, everything stays there, and recurring categories are exempt. For your own categories you set the limit yourself.",
          },
        ],
      },
    ],
  },
  {
    id: "technik",
    anchor: "faq-technik",
    title: "Devices, sync and widgets",
    intro: "What reaches your other devices, and what does not.",
    surface: "paper",
    next: { anchor: "faq-daten", label: "Data, cost, support" },
    groups: [
      {
        items: [
          {
            id: "technik-widgets",
            q: "What can the widgets do?",
            a: "There are three, in several sizes: Today, Backlog and Archive. Tasks can be checked off right in the widget without launching the app. Tapping a row jumps to the matching spot in the app. The nightly reset applies to the widgets just the same.",
          },
          {
            id: "technik-ipad-mac",
            q: "Does Dawny run on iPad or Mac?",
            a: "Dawny is an iPhone app. If you want to see your tasks on other Apple devices, turn on the sync with Apple Reminders and they show up there on Mac, iPad and Apple Watch.",
          },
          {
            id: "technik-reminders-sync",
            q: "How does the sync with Apple Reminders work?",
            a: "You switch it on in Settings and link a list. Dawny writes your Today tasks there and reads changes back from there. The first time, iOS asks for permission.",
          },
          {
            id: "technik-reminders-import",
            q: "Can I import my existing reminders into Dawny?",
            a: "No, and that is on purpose. The point of Dawny is that you decide fresh every morning what counts today. A list with 200 imported leftovers would be the opposite of that.",
          },
          {
            id: "technik-icloud-sync",
            q: "What does the iCloud sync do?",
            a: "It keeps two devices with the same Apple ID in step, through your own iCloud account. There is no server on my end. The sync is off by default and only takes effect after you restart the app.",
          },
          {
            id: "technik-siri",
            q: "What can Siri do?",
            a: "You can create tasks by voice, either in the Backlog or straight into Today, and say the category along with it. Dawny registers with the system through App Intents, so the Shortcuts app finds the actions automatically.",
          },
          {
            id: "technik-inaktiv",
            q: "What happens if I don't touch my iPhone for days?",
            a: "Nothing is lost. The next time you launch the app, the reset catches up on everything that was due in the meantime, and the summary shows you what was filed away.",
          },
        ],
      },
    ],
  },
  {
    id: "daten",
    anchor: "faq-daten",
    title: "Data, cost, support",
    intro: "Who owns what, and what it costs.",
    surface: "paper-warm",
    groups: [
      {
        items: [
          {
            id: "daten-kosten",
            q: "Does Dawny cost anything?",
            a: "No. The app is completely free. There is no subscription, no pro version, no in-app purchases and no ads. There is also no feature sitting behind a paywall.",
          },
          {
            id: "daten-haken",
            q: "What's the catch?",
            a: "There isn't one. Dawny started as a tool I use myself. The source code is public on GitHub, so you can check what the app does.",
          },
          {
            id: "daten-konto",
            q: "Do I need an account?",
            a: "No. You download the app and get going. There is no sign-up, no login, and I do not know your email address.",
          },
          {
            id: "daten-speicherort",
            q: "Where are my tasks stored?",
            a: "On your iPhone. If you turn on the iCloud sync, additionally in your own iCloud account, which Apple manages. Either way I have no access to them, because there is no server of mine.",
          },
          {
            id: "daten-tracking",
            q: "Does the app collect data about me?",
            a: "No. The app contains no analytics SDKs, no crash reporting to me, no advertising IDs and no trackers. On this website I measure reach anonymously, without cookies and without recognising you. The details are in the privacy policy.",
          },
          {
            id: "daten-loeschen",
            q: "How do I get rid of all my data again?",
            a: "Delete the app. That removes all local data. Whatever you mirrored into Apple Reminders stays there and has to be deleted there if you want it gone.",
          },
          {
            id: "daten-support",
            q: "I found a bug or have a request. Where do I send it?",
            a: "Write to me at info@dawnyapp.com. You will also find a direct way there under Settings in the app. Bug reports and requests both land with me personally, there is no ticket system in between.",
          },
        ],
      },
    ],
  },
];
