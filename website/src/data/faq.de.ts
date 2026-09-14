import type { FaqBlock } from "@/data/faq";

/** German FAQ content. Item and block ids are shared with faq.en.ts (see faq.ts). */
export const faqBlocks: FaqBlock[] = [
  {
    id: "reset",
    anchor: "faq-reset",
    title: "Der Reset",
    intro: "Was nachts um drei passiert, und warum.",
    surface: "paper",
    next: { anchor: "faq-bedienung", label: "Wie nutze ich Dawny am besten?" },
    groups: [
      {
        items: [
          {
            id: "reset-ablauf",
            q: "Was passiert um drei Uhr nachts genau?",
            a: "Dawny beendet den Tag und leert die Heute-Liste. Erledigte Aufgaben liegen danach im Archiv unter „Erledigt“. Nicht erledigte wandern in der Grundeinstellung ebenfalls ins Archiv, unter „Archiviert“. Wiederkehrende Aufgaben gehen zurück in den Backlog. Die App muss dafür nicht geöffnet sein.",
          },
          {
            id: "reset-warum-drei-uhr",
            q: "Warum drei Uhr und nicht Mitternacht?",
            a: "Weil ein Tag nicht um zwölf endet, sondern wenn du schlafen gehst. Wer um halb eins noch etwas abhakt, will es im Heute von gestern sehen und nicht im Morgen von heute.",
          },
          {
            id: "reset-uhrzeit",
            q: "Kann ich die Uhrzeit ändern?",
            a: "Ja. In den Einstellungen stellst du die Reset-Zeit auf jede volle Stunde. Drei Uhr ist nur die Voreinstellung.",
          },
          {
            id: "reset-nicht-geschafft",
            q: "Was passiert mit Aufgaben, die ich nicht geschafft habe?",
            a: "Sie werden nicht stillschweigend auf morgen geschoben. In der Grundeinstellung wandern sie ins Archiv, weil ein Platz in der Heute-Liste eine Zusage ist und keine Ablage. Mit einem Wisch nach rechts holst du sie von dort zurück, in den Backlog oder direkt nach Heute.",
          },
          {
            id: "reset-erledigte-weg",
            q: "Sind meine erledigten Aufgaben danach weg?",
            a: "Nein. Sie liegen im Archiv unter „Erledigt“, nach Datum sortiert. Du kannst dort jederzeit nachsehen, was du an einem bestimmten Tag geschafft hast.",
          },
          {
            id: "reset-uebersicht",
            q: "Woher weiß ich, was nachts passiert ist?",
            a: "Beim ersten Öffnen nach einem Reset zeigt Dawny eine kurze Übersicht in zwei Schritten: erst was aus Heute abgelegt wurde, dann was aus dem Backlog aufgeräumt wurde. Danach bist du auf dem Stand und die Übersicht verschwindet.",
          },
        ],
      },
    ],
  },
  {
    id: "bedienung",
    anchor: "faq-bedienung",
    title: "Wie nutze ich Dawny am besten?",
    intro:
      "Die Handgriffe, die man einmal gesehen haben muss, und wie man sich den Tag damit einteilt.",
    surface: "paper-warm",
    next: { anchor: "faq-konzept", label: "Das Konzept dahinter" },
    groups: [
      {
        label: "Die Handgriffe",
        items: [
          {
            id: "bedienung-backlog-nach-heute",
            q: "Wie bekomme ich eine Aufgabe vom Backlog zu Heute?",
            a: "Wisch die Zeile nach rechts. Es erscheint eine orange Sonne mit „Heute“, und die Aufgabe wechselt hinüber. Wische weit genug, dann brauchst du nicht einmal zu tippen.",
          },
          {
            id: "bedienung-abhaken",
            q: "Wie hake ich eine Aufgabe ab?",
            a: "Tippe im Heute-Tab auf den Kreis links neben der Aufgabe, sie rutscht dann nach unten zu den erledigten Aufgaben. Das geht bewusst nur in Heute: der Kreis im Backlog ist deshalb ausgegraut, denn Erledigen ist bei Dawny an die Heute-Liste gebunden. Wenn du die erledigten Aufgaben dort nicht sehen willst, blendest du den Bereich in den Einstellungen aus.",
          },
          {
            id: "bedienung-neue-aufgabe",
            q: "Wie lege ich eine neue Aufgabe an?",
            a: "In Heute und im Backlog steht unter der Liste immer eine leere Zeile. Tippe hinein, schreib los, mit Return legst du sie an und kannst direkt die nächste tippen. Für den Backlog wählst du vorher die Kategorie, in die sie soll.",
          },
          {
            id: "bedienung-archiv-zurueckholen",
            q: "Wie hole ich etwas aus dem Archiv zurück?",
            a: "Wisch die Zeile im Archiv nach rechts. Du bekommst zwei Ziele: „Backlog“ legt sie zurück in die Ablage, „Heute“ nimmt sie dir sofort für heute vor. Ein Wisch nach links löscht sie endgültig.",
          },
          {
            id: "bedienung-kategorie-wechseln",
            q: "Wie sortiere ich eine Aufgabe in eine andere Kategorie?",
            a: "Halte die Zeile im Backlog gedrückt, dann erscheint eine Liste aller Kategorien. Wähl die Zielkategorie aus, und die Aufgabe wandert sofort dorthin.",
          },
          {
            id: "bedienung-eigene-kategorien",
            q: "Kann ich eigene Kategorien anlegen?",
            a: "Ja, so viele du willst, jeweils mit eigenem Namen und Symbol. Am Ende der Kategorieliste im Backlog steht dafür eine eigene Zeile.",
          },
          {
            id: "bedienung-wiederkehrende-kategorien",
            q: "Was sind wiederkehrende Kategorien?",
            a: "Eine Kategorie lässt sich als wiederkehrend markieren. Alles darin wird nie archiviert, sondern geht nachts zurück in den Backlog, egal ob du es erledigt hast oder nicht. Genau richtig für Sport, Gießen oder Vokabeln.",
          },
        ],
      },
      {
        label: "Wie man sich den Tag einteilt",
        items: [
          {
            id: "bedienung-anzahl-heute",
            q: "Wie viele Aufgaben gehören in Heute?",
            a: "So viele, wie du dir an diesem einen Tag wirklich zutraust. Bei den meisten sind das drei bis fünf. Die Liste ist bewusst kurz gehalten, damit du abends noch draufschaust, statt sie wegzuwischen.",
          },
          {
            id: "bedienung-planen",
            q: "Wann plane ich am besten?",
            a: "Morgens, in einer Minute. Du gehst den Backlog von oben nach unten durch, holst raus, was heute dran ist, und schließt die App wieder. Der Reset hat dir die Liste dafür schon leergeräumt.",
          },
          {
            id: "bedienung-immer-wieder-verschieben",
            q: "Was mache ich mit Aufgaben, die ich immer wieder verschiebe?",
            a: "Wenn eine Aufgabe zum dritten Mal ins Archiv wandert, ist das bereits die Antwort: So, wie du sie dir vorgenommen hast, wird sie offenbar nicht passieren. Unser Vorschlag: Lass sie entweder los. Oder, falls sie dir wirklich wichtig ist, frag dich, was dir fehlt, um sie morgen doch umzusetzen, und mach genau das zur nächsten Aufgabe.",
          },
          {
            id: "bedienung-grosses-vorhaben",
            q: "Ich habe eine große Sache vor, die Wochen dauert. Wie bilde ich die ab?",
            a: "Dafür ist Dawny bewusst nicht das richtige Werkzeug: Eine To-do-Liste ist kein Projektmanagement-Tool. Plane größere Vorhaben lieber in einer App, die dafür gemacht ist. Was in Dawny helfen kann: eine wiederkehrende Aufgabe wie „Am Projekt weiterarbeiten“, die dich jeden Tag daran erinnert, egal wie weit du gerade bist.",
          },
        ],
      },
    ],
  },
  {
    id: "konzept",
    anchor: "faq-konzept",
    title: "Das Konzept dahinter",
    intro: "Die Fragen, die kommen, wenn Dawny sich anders verhält als erwartet.",
    surface: "paper-2",
    next: { anchor: "faq-technik", label: "Geräte, Sync und Widgets" },
    groups: [
      {
        items: [
          {
            id: "konzept-backlog-nicht-abhaken",
            q: "Warum kann ich im Backlog nichts abhaken?",
            a: "Weil Erledigen im Heute passiert. Der Backlog ist eine Sammlung von allem, was irgendwann ansteht, nicht die Liste, an der du gerade arbeitest. Der Kreis ist deshalb sichtbar, aber ausgegraut. Hol die Aufgabe mit einem Wisch nach Heute, dann kannst du sie abhaken.",
          },
          {
            id: "konzept-warum-archivieren",
            q: "Warum werden nicht erledigte Aufgaben überhaupt archiviert?",
            a: "Weil eine Liste, die nur wächst, irgendwann nicht mehr gelesen wird. Wenn Liegengebliebenes automatisch stehen bleibt, kostet dich jeder Blick auf die Liste Energie für Dinge, die du längst abgeschrieben hast. Dawny räumt sie weg und überlässt dir die Entscheidung, ob du sie zurückholst.",
          },
          {
            id: "konzept-make-it-count",
            q: "Mich stört, dass Aufgaben schon beim ersten Mal archiviert werden. Was kann ich tun?",
            a: "Das lässt sich einstellen. In den Einstellungen steht unter „Make it count“ eine Zahl von 1 bis 7. Sie sagt, wie oft eine Aufgabe in Heute liegenbleiben darf, bevor sie ins Archiv geht. Bei 3 wandert sie zweimal zurück in den Backlog und erst beim dritten Mal ins Archiv.",
          },
          {
            id: "konzept-keine-prioritaet",
            q: "Warum kann ich einer Aufgabe keine Priorität geben?",
            a: "Weil Prioritäten eine Lüge sind, die man sich selbst erzählt. Nach zwei Wochen ist alles „hoch“. Dawny stellt stattdessen die einfachere Frage: wann ungefähr? Daraus werden die Zeithorizonte im Backlog. Die eigentliche Priorisierung passiert jeden Morgen, wenn du entscheidest, was nach Heute wandert.",
          },
          {
            id: "konzept-keine-faelligkeitsdaten",
            q: "Warum gibt es keine Fälligkeitsdaten und keine Erinnerungen?",
            a: "Weil ein Datum in der Zukunft eine Entscheidung vertagt, statt sie zu treffen. In Dawny gibt es genau zwei Zeitpunkte: heute und irgendwann. Wenn du eine Aufgabe an einem festen Termin brauchst, gehört sie in den Kalender oder in die Erinnerungen-App, und dorthin kann Dawny sie auch spiegeln.",
          },
          {
            id: "konzept-keine-projekte",
            q: "Warum keine Projekte, Tags oder Unteraufgaben?",
            a: "Weil jede zusätzliche Struktur eine zusätzliche Entscheidung ist, die du triffst, bevor du irgendetwas erledigt hast. Dawny hat eine Ebene: Aufgabe, in einer Kategorie. Wer mehr Struktur braucht, legt mehr Kategorien an.",
          },
          {
            id: "konzept-archiviert-verloren",
            q: "Ist eine archivierte Aufgabe verloren?",
            a: "Nein. Archiviert heißt einsortiert, nicht gelöscht. Das Archiv ist durchsuchbar und nach Datum sortiert, und ein Wisch holt jede Aufgabe zurück. Gelöscht wird nur, was du selbst löschst.",
          },
          {
            id: "konzept-backlog-aufraeumen",
            q: "Warum ist eine Aufgabe aus dem Backlog verschwunden, obwohl sie nie in Heute war?",
            a: "Auch der Backlog räumt sich auf. Jede Kategorie hat eine Lebensdauer: „Schnell erledigt“ sieben Tage, „Die nächsten Tage“ 21, „Die nächsten Wochen“ 60, „Die nächsten Monate“ ein Jahr. Was länger unangetastet liegt, wandert ins Archiv. „Irgendwann“ hat keine Frist, dort bleibt alles liegen, und wiederkehrende Kategorien sind ausgenommen. Bei eigenen Kategorien stellst du die Frist selbst ein.",
          },
        ],
      },
    ],
  },
  {
    id: "technik",
    anchor: "faq-technik",
    title: "Geräte, Sync und Widgets",
    intro: "Was auf anderen Geräten ankommt, und was nicht.",
    surface: "paper",
    next: { anchor: "faq-daten", label: "Daten, Kosten, Support" },
    groups: [
      {
        items: [
          {
            id: "technik-widgets",
            q: "Was können die Widgets?",
            a: "Es gibt drei, in mehreren Größen: Heute, Backlog und Archiv. Aufgaben lassen sich direkt im Widget abhaken, die App muss dafür nicht starten. Ein Tippen auf eine Zeile springt an die passende Stelle in der App. Der nächtliche Reset gilt für die Widgets genauso.",
          },
          {
            id: "technik-ipad-mac",
            q: "Läuft Dawny auf dem iPad oder dem Mac?",
            a: "Dawny ist als iPhone-App gebaut. Auf dem iPad läuft sie im iPhone-Kompatibilitätsmodus, also im iPhone-Format statt mit einer eigenen iPad-Oberfläche. Auf dem Mac läuft sie nicht. Wer die Aufgaben zusätzlich nativ auf Mac oder Apple Watch sehen will, aktiviert die Synchronisation mit der Erinnerungen-App.",
          },
          {
            id: "technik-reminders-sync",
            q: "Wie funktioniert die Synchronisation mit der Erinnerungen-App?",
            a: "In den Einstellungen schaltest du sie ein und verknüpfst eine Liste. Dawny schreibt deine Heute-Aufgaben dorthin und liest Änderungen von dort zurück. Beim ersten Mal fragt iOS nach der Berechtigung.",
          },
          {
            id: "technik-reminders-import",
            q: "Kann ich meine bestehenden Erinnerungen nach Dawny importieren?",
            a: "Nein, und das ist Absicht. Der Sinn von Dawny ist, dass du jeden Morgen neu entscheidest, was heute zählt. Eine Liste mit 200 importierten Altlasten wäre das Gegenteil davon.",
          },
          {
            id: "technik-icloud-sync",
            q: "Was macht der iCloud-Sync?",
            a: "Er hält zwei Geräte mit derselben Apple-ID auf demselben Stand, über deinen eigenen iCloud-Account. Es gibt keinen Server bei mir. Der Sync ist standardmäßig aus und wird erst nach einem Neustart der App wirksam.",
          },
          {
            id: "technik-siri",
            q: "Was kann Siri?",
            a: "Du kannst Aufgaben per Sprache anlegen, entweder in den Backlog oder direkt nach Heute, und die Kategorie mitsprechen. Dawny meldet sich dafür mit App Intents beim System an, die Kurzbefehle-App findet die Aktionen automatisch.",
          },
          {
            id: "technik-inaktiv",
            q: "Was passiert, wenn ich das iPhone tagelang nicht anfasse?",
            a: "Nichts geht verloren. Der Reset holt beim nächsten Start nach, was in der Zwischenzeit fällig war, und die Übersicht zeigt dir, was abgelegt wurde.",
          },
        ],
      },
    ],
  },
  {
    id: "daten",
    anchor: "faq-daten",
    title: "Daten, Kosten, Support",
    intro: "Wem was gehört und was das kostet.",
    surface: "paper-warm",
    groups: [
      {
        items: [
          {
            id: "daten-kosten",
            q: "Kostet Dawny etwas?",
            a: "Nein. Die App ist vollständig kostenlos. Es gibt kein Abo, keine Pro-Version, keine In-App-Käufe und keine Werbung. Es gibt auch keine Funktion, die hinter einer Bezahlschranke liegt.",
          },
          {
            id: "daten-haken",
            q: "Wo ist der Haken?",
            a: "Es gibt keinen. Dawny ist als Werkzeug entstanden, das ich selbst benutze. Der Quellcode liegt offen auf GitHub, du kannst nachsehen, was die App tut.",
          },
          {
            id: "daten-konto",
            q: "Brauche ich ein Konto?",
            a: "Nein. Du lädst die App und legst los. Es gibt keine Registrierung, keinen Login und ich kenne deine E-Mail-Adresse nicht.",
          },
          {
            id: "daten-speicherort",
            q: "Wo liegen meine Aufgaben?",
            a: "Auf deinem iPhone. Wenn du den iCloud-Sync einschaltest, zusätzlich in deinem eigenen iCloud-Account, den Apple verwaltet. Ich habe in keinem Fall Zugriff darauf, weil es keinen Server von mir gibt.",
          },
          {
            id: "daten-tracking",
            q: "Sammelt die App Daten über mich?",
            a: "Nein. Die App enthält keine Analytics-SDKs, kein Crash-Reporting an mich, keine Werbe-IDs und keine Tracker. Auf dieser Website messe ich anonym die Reichweite, ohne Cookies und ohne dich wiederzuerkennen. Die Einzelheiten stehen in der Datenschutzerklärung.",
          },
          {
            id: "daten-loeschen",
            q: "Wie werde ich alle meine Daten wieder los?",
            a: "App löschen. Damit sind alle lokalen Daten weg. Was du in die Erinnerungen-App gespiegelt hast, bleibt dort und musst du bei Bedarf dort löschen.",
          },
          {
            id: "daten-support",
            q: "Ich habe einen Fehler gefunden oder einen Wunsch. Wohin damit?",
            a: "Schreib mir an info@dawnyapp.com. In der App findest du unter Einstellungen ebenfalls einen direkten Weg dorthin. Fehlerberichte und Wünsche landen beide bei mir persönlich, es gibt kein Ticketsystem dazwischen.",
          },
        ],
      },
    ],
  },
];
