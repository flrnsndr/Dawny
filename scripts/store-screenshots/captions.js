// Texts for the captioned App Store screenshots, one block per language.
// `<em>` marks the one word per headline that is set in italic accent colour.
// `<br>` in notes sets the line breaks by hand, the notes are narrow.
window.CAPTIONS = {
  de: {
    reset: {
      kicker: "Der Reset um 3 Uhr",
      title: "Jeden Morgen ein <em>leeres</em> Heute.",
      sub: "Was liegen bleibt, wandert zurück ins Backlog. Überfällig wird nichts.",
      evening: "Abends",
      morning: "Morgens",
      time: "3:00",
    },
    backlog: {
      kicker: "Backlog",
      title: "Sortiert danach, <em>wann</em> es dran ist.",
      sub: "Von „Schnell erledigt“ über Tage, Wochen und Monate bis „Irgendwann“.",
      soon: "bald",
      someday: "irgendwann",
    },
    today: {
      kicker: "Heute",
      title: "Ein paar Aufgaben für heute. <em>Mehr nicht.</em>",
      sub: "Morgens auswählen, tagsüber abhaken.",
    },
    archive: {
      kicker: "Aufräumen",
      title: "Was liegen bleibt, räumt Dawny <em>weg.</em>",
      sub: "Gelöscht wird nichts. Alles lässt sich mit einem Wisch zurückholen.",
      note: "Zurück<br>ins Backlog<br>oder direkt<br>nach Heute",
    },
    widgets: {
      kicker: "Widgets",
      title: "Abhaken, <em>ohne</em> die App zu öffnen.",
      sub: "Heute, Backlog und Archiv auf dem Home-Bildschirm.",
    },
    free: {
      title: "Kostenlos. <em>Wirklich.</em>",
      sub: "Keine Werbung, kein Abo, keine In-App-Käufe.",
      features: [
        ["cloud", "iCloud-Sync", "Gleiche Liste auf iPhone und iPad"],
        ["list", "Apple Erinnerungen", "Heute erscheint auf Wunsch auch dort"],
        ["wave", "Siri und Kurzbefehle", "Aufgaben per Sprache anlegen und abfragen"],
        ["lock", "Kein Konto, kein Tracking", "Deine Daten bleiben bei dir"],
      ],
    },
  },
  en: {
    reset: {
      kicker: "The 3 AM reset",
      title: "A <em>fresh</em> Today, every morning.",
      sub: "Whatever's left goes back to your backlog. Nothing is ever overdue.",
      evening: "Evening",
      morning: "Morning",
      time: "3 AM",
    },
    backlog: {
      kicker: "Backlog",
      title: "Sorted by <em>when</em> it matters.",
      sub: "From Quick through days, weeks and months to Someday.",
      soon: "soon",
      someday: "someday",
    },
    today: {
      kicker: "Today",
      title: "A few tasks for today. <em>That's it.</em>",
      sub: "Pick them in the morning, check them off during the day.",
    },
    archive: {
      kicker: "Tidying up",
      title: "What sits around, Dawny <em>clears</em> away.",
      sub: "Nothing gets deleted. Anything comes back with one swipe.",
      note: "Back to<br>your backlog<br>or straight<br>to Today",
    },
    widgets: {
      kicker: "Widgets",
      title: "Check things off <em>without</em> opening the app.",
      sub: "Today, Backlog and Archive right on your Home Screen.",
    },
    free: {
      title: "Free. <em>Really.</em>",
      sub: "No ads, no subscription, no in-app purchases.",
      features: [
        ["cloud", "iCloud Sync", "Same list on iPhone and iPad"],
        ["list", "Apple Reminders", "Today can show up there too"],
        ["wave", "Siri and Shortcuts", "Add and check tasks by voice"],
        ["lock", "No account, no tracking", "Your data stays with you"],
      ],
    },
  },
};
